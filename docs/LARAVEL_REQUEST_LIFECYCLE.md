# Laravel Request Lifecycle

This project uses modern Laravel bootstrap configuration. There is no `app/Http/Kernel.php` file in the audited code.

```text
HTTP request
  -> backend/public/index.php
  -> Composer autoload
  -> backend/bootstrap/app.php
  -> Application::configure(basePath)
  -> withRouting(web/api/commands/health)
  -> withMiddleware(throttleApi)
  -> withExceptions(JSON for api/*)
  -> bootstrap/providers.php
  -> AppServiceProvider
  -> routes/api.php
  -> route middleware
  -> controller method
  -> Form Request validation when type-hinted
  -> Eloquent / DB transaction
  -> API Resource / response()->json
```

`bootstrap/app.php` is responsible for route registration, API throttling, and JSON exception rendering. `bootstrap/providers.php` registers `App\Providers\AppServiceProvider`. `AppServiceProvider::boot()` sets default string length, disables resource wrapping, and defines `login`, `register`, and `api` rate limiters.

Routes in `routes/api.php` are grouped under `/api/v1`. Register and login use `guest` plus route-specific throttles. All other implemented API routes use `auth:sanctum`. Sanctum reads the bearer token and resolves `$request->user()`.

Form Requests are used for register, login, top-up, and transfer. Laravel resolves them through the service container before the controller body runs. Invalid data exits early as JSON 422. `UserController::search()` uses inline `$request->validate()`.

Failure outputs:

- Validation failure: 422 JSON.
- Authentication failure: 401 JSON.
- Rate limit exceeded: 429 JSON.
- Missing model via `firstOrFail()`: 404 JSON.
- Business rule failure: explicit JSON or `ValidationException`.
- Duplicate idempotency race: MySQL 1062 catch returns existing transaction.
- Unhandled exception: JSON for `api/*` due to `shouldRenderJsonWhen`.
