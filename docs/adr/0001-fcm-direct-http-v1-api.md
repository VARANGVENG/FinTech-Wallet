# ADR 0001: Send push notifications via FCM's HTTP v1 API directly, not the kreait/firebase-php SDK

**Status:** Accepted

## Context

The backend needs to send push notifications (transaction alerts) to users' devices via Firebase Cloud Messaging (FCM). The obvious default in the Laravel ecosystem is `kreait/firebase-php`, a full-featured Firebase Admin SDK.

## Decision

`PushNotificationService` talks to FCM's HTTP v1 API directly: a plain OAuth2 token exchange via `google/auth`'s `ServiceAccountCredentials`, followed by one REST call per device token through Laravel's own HTTP client (`Illuminate\Support\Facades\Http`). No Firebase SDK is used.

## Consequences

**Why not the SDK:** `kreait/firebase-php`'s `Factory` drags in the full `google-cloud-php` surface (gRPC, Cloud Storage, protobuf, roughly 20 extra packages) to reach the one feature this app actually needs — Messaging. FCM's v1 API also has no server-side batch/multicast endpoint (Google retired that with the legacy API), so the SDK's `sendMulticast` convenience method is just the same per-token loop internally anyway — adopting the SDK would not have bought any real capability this hand-rolled version lacks.

**Trade-off accepted:** the app owns the OAuth2 token exchange, HTTP timeout handling (`HTTP_TIMEOUT_SECONDS = 10`, applied to both the token exchange and each FCM send, since neither Guzzle nor `google/auth` apply a timeout by default), and the per-token send loop directly, rather than delegating that to a maintained SDK. This is more code inside `PushNotificationService` to keep correct, in exchange for a much smaller dependency footprint and fully legible behavior (every HTTP call this service makes is visible in one file).

**Failure isolation:** a null `credentials` (Firebase not configured — e.g. local dev without the service-account JSON) makes every method a silent no-op rather than throwing, since a push failure must never turn a successful money-movement operation into a 500. Delivery itself is queued (`SendPushNotificationJob`) rather than called inline, keeping FCM's network latency off the critical path of a top-up or transfer request.
