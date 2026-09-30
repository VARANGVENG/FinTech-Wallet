# Staging Deployment Plan

**Status: Phase 1 — plan only, nothing provisioned yet.** This consolidates NOV-24 (queue driver), NOV-38 (env template — already written, reused here), NOV-39 (worker deploy story), and R-09 (release build never installed/run), per the owner decision recorded 2026-09-30 in the Independent Review doc, Section M.

**Goal, stated precisely:** production-*grade* infrastructure for a portfolio project, to learn release engineering — not a real-money, real-user launch. Top-up has no real payment provider; H-06 and R-07/R-08 remain open gates before anything beyond staging is called "production."

---

## 1. Architecture

```
                    Internet
                       │
                  HTTPS (443)
                       │
              ┌────────▼────────┐
              │  Nginx (TLS via │
              │  Let's Encrypt) │
              └────────┬────────┘
                       │ proxy_pass, unix socket
              ┌────────▼────────┐
              │   PHP-FPM       │
              │  (Laravel app)  │
              └───┬────────┬────┘
                   │        │
         ┌─────────▼──┐   ┌─▼──────────────┐
         │  MySQL 8   │   │ systemd unit:  │
         │  127.0.0.1 │   │ queue:work     │
         │  only      │   │ (worker)       │
         └────────────┘   └────────────────┘
```

One VPS. MySQL bound to `127.0.0.1` only — never exposed to the internet, no inbound firewall rule for port 3306. The web process (Nginx + PHP-FPM) and the queue worker are two independently supervised processes on the same box.

## 2. Queue driver decision (NOV-24, formalized)

**Keep `QUEUE_CONNECTION=database`.** G-12 confirms exactly one job type exists (`SendPushNotificationJob`), dispatched at most twice per request, `tries=1`, already fully fault-tolerant at the application layer (failures are caught and logged inside `PushNotificationService`, never thrown). This workload does not justify Redis or a managed queue service — the complexity/cost of running and monitoring an additional service would not buy anything this workload needs. If the queue's shape changes materially later (multiple job types, higher volume, a need for real retries/backoff), revisit this.

**What "keep database" requires, made explicit (this is the actual NOV-39 answer):** a `php artisan queue:work` process must run continuously, or queued jobs simply sit in the `jobs` table forever and nothing gets sent. This is not automatic — it needs its own supervised process, below.

## 3. Server provisioning (what Phase 2 will actually run)

- Ubuntu 22.04 or 24.04 LTS, smallest tier that offers at least 1 vCPU / 1–2GB RAM (this workload is light — a single Laravel app + MySQL for a portfolio project, not real traffic).
- Packages: `nginx`, `mysql-server` (8.0, **not** a lower version — CHECK constraints require ≥ 8.0.16, per `docs/DATABASE_SCHEMA.md`), `php8.3-fpm` + `php8.3-{cli,mysql,mbstring,xml,curl,bcmath,zip}`, `composer`, `certbot` + `python3-certbot-nginx`, `git`.
- A registered domain/subdomain pointed at the VPS's IP (e.g. `staging.<yourdomain>`) — required for Let's Encrypt (HTTP-01 challenge needs a real domain, not just an IP).

## 4. MySQL setup

- Install MySQL 8, then edit `bind-address = 127.0.0.1` in `mysqld.cnf` (should already be the default on a fresh install, but verify explicitly — don't assume).
- No firewall rule opens 3306 externally (UFW/iptables default-deny handles this if nothing explicitly allows it).
- Create a dedicated app database and a dedicated MySQL user scoped to only that database (not `root`) for the Laravel connection.
- Run `php artisan migrate --force` on first deploy (the `--force` flag is required to run migrations outside a `local` environment without an interactive confirmation prompt).

## 5. TLS

- `certbot --nginx -d staging.<yourdomain>` — handles both obtaining the certificate and configuring Nginx's TLS block, plus sets up auto-renewal via a systemd timer it installs itself (verify with `systemctl list-timers | grep certbot`).
- Nginx config: standard PHP-FPM reverse-proxy block, `proxy_pass` to the PHP-FPM socket, redirect port 80 → 443.

## 6. Systemd-supervised queue worker (the actual NOV-39 deliverable)

`php artisan queue:work` must run as its own supervised, auto-restarting process — it is not something PHP-FPM or Nginx provides for free. Proposed unit file, `/etc/systemd/system/novapay-queue-worker.service`:

```ini
[Unit]
Description=Novapay queue worker
After=network.target mysql.service

[Service]
User=www-data
WorkingDirectory=/var/www/novapay/current
ExecStart=/usr/bin/php artisan queue:work --tries=1 --timeout=60 --sleep=3
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

- `--tries=1` matches the job's own design intent (no retries wanted — see the doc comment on `SendPushNotificationJob`).
- `Restart=always` + `RestartSec=5`: if the worker process dies (PHP fatal error, OOM, `queue:restart` signal after a deploy), systemd brings it back within 5 seconds rather than silently leaving push notifications stuck forever.
- `WorkingDirectory` points at `current`, a symlink — see the deploy procedure below for why.
- Enable + start: `systemctl enable --now novapay-queue-worker`.
- **After every deploy**, run `php artisan queue:restart` — this signals the running worker to finish its current job and exit cleanly; systemd's `Restart=always` then relaunches it, picking up the new code. Without this step, a long-lived worker process keeps running the *old* PHP code in memory even after a fresh deploy.

## 7. Environment / secrets

- Base the real staging `.env` on `backend/.env.production.example` (NOV-38, already written) — copy it to `.env` on the server, fill in every `<CHANGE_ME>`, `php artisan key:generate` for a staging-specific `APP_KEY`.
- `FIREBASE_CREDENTIALS` service-account JSON: copy it to the server out-of-band (scp, not git) to the path the `.env` names — see `docs/FIREBASE_CONFIGURATION.md`.
- The real `.env` never touches git — matches the existing `.gitignore` convention already in place.

## 8. Deploy procedure

Releases-directory pattern (the standard, transferable technique — not a from-scratch invention): each deploy checks out into its own timestamped directory, and a single `current` symlink is atomically flipped to point at it once the new release is verified ready. This is what makes rollback (§9) actually fast and safe.

```
/var/www/novapay/
├── releases/
│   ├── 20260930-140501/
│   └── 20260930-153022/
├── current -> releases/20260930-153022/
└── shared/
    ├── .env
    └── storage/           # persisted across releases (logs, uploaded files)
```

Deploy script outline (run manually for Phase 1's "one recorded deploy" — a good candidate to automate via CI later):
```bash
RELEASE=$(date +%Y%m%d-%H%M%S)
TARGET=/var/www/novapay/releases/$RELEASE

git clone --depth 1 --branch main <repo-url> "$TARGET"
ln -s /var/www/novapay/shared/.env "$TARGET/.env"
ln -s /var/www/novapay/shared/storage "$TARGET/storage"

cd "$TARGET"
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache

ln -sfn "$TARGET" /var/www/novapay/current
php artisan queue:restart   # picks up the new code in the worker
sudo systemctl reload php8.3-fpm
```

## 9. Rollback procedure

**Code rollback (fast, safe, the primary mechanism):** flip the `current` symlink back to the previous `releases/<timestamp>/` directory, then `php artisan queue:restart` again.
```bash
ln -sfn /var/www/novapay/releases/<previous-timestamp> /var/www/novapay/current
php artisan queue:restart
sudo systemctl reload php8.3-fpm
```
This is close to instant and doesn't touch the database — it's what "one rollback, recorded" should demonstrate in Phase 2.

**Database rollback is a separate, harder problem, called out honestly rather than glossed over:** `php artisan migrate:rollback` only works if the migration that ran has a correct, tested `down()` — every migration in this app does (verified for NOV-21's own migration during that task), but a rollback that also needs to *undo a schema change already used by new data* is genuinely risky in a way code rollback isn't. The safe default is: only roll back the database if the deploy being reverted didn't yet write any data shaped by its migration; otherwise, prefer fixing forward.

## 10. Backups

- Nightly cron job on the VPS: `mysqldump` the database, gzip it, and push it **off-host** — the owner's stated requirement. Cheapest options: a small object-storage bucket (Backblaze B2, S3), or `scp` to a second inexpensive host/machine. Concrete choice is a Phase 2 decision (needs an actual account/bucket).
- Retention: keep a rolling window (e.g. 7 daily + 4 weekly) rather than unbounded — Phase 2 detail once the storage target is picked.
- **A backup that has never been restored is not a verified backup** — Definition of Done requires actually restoring one into a fresh database and confirming the data is intact (row counts, spot-check a known record), not just confirming the dump file exists.

## 11. Definition of Done (Phase 2+, requires real provisioning + a real device — not deliverable from this environment)

- [ ] Signed release APK (NOV-25's signing config) installed on a real Android device, completing login → transfer → top-up against staging over HTTPS. Record device model, OS version, build type.
- [ ] A push notification actually delivered to that device via the systemd-supervised worker (proves the whole queue path end-to-end, not just that a job row got inserted).
- [ ] A backup restored into a fresh database and verified.
- [ ] One deploy and one rollback performed using the procedures above, with the actual commands and output recorded in Notion (per the owner's stated Done criteria).

## 12. Explicitly out of scope for this plan (Phase 1)

No server has been provisioned, no DNS configured, no real device tested, no backup target chosen yet — this document is the plan Phase 2 executes against, not a record of anything having been done. Phase 2 requires the owner's own action (creating a VPS account, paying for it, owning DNS) — none of it can be done from this environment.
