<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\HttpHandler\HttpHandlerFactory;
use GuzzleHttp\Client;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Sends push notifications via FCM's HTTP v1 API directly (a plain OAuth2
 * token exchange via google/auth + one REST call per token through
 * Laravel's HTTP client) rather than pulling in kreait/firebase-php - that
 * SDK's Factory drags in the full google-cloud-php surface (gRPC, Cloud
 * Storage, protobuf, ~20 extra packages) to reach the one Messaging feature
 * this app needs, and FCM's v1 API has no server-side batch/multicast
 * endpoint anyway (Google retired that with the legacy API), so the SDK's
 * "sendMulticast" convenience is just this same per-token loop internally.
 */
class PushNotificationService
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    /**
     * Bounds every external HTTP call this service makes: the Google OAuth
     * token exchange, and each FCM send. This runs inside a queued job, not
     * the request/response path, so it doesn't need to be tight enough to
     * protect a live HTTP response - but it must still be bounded, or one
     * slow/hanging call ties up a queue worker indefinitely (neither Guzzle
     * nor google/auth apply a timeout by default). Both endpoints are
     * Google-operated and normally respond in well under a second; 10s
     * leaves generous headroom above that before giving up.
     */
    private const HTTP_TIMEOUT_SECONDS = 10;

    /**
     * Null when Firebase credentials aren't configured (e.g. local dev
     * before the service-account JSON is in place) - every method becomes
     * a silent no-op rather than throwing, since a push failure must never
     * turn a successful money-movement into a 500.
     */
    public function __construct(private readonly ?ServiceAccountCredentials $credentials)
    {
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function sendToUser(User $user, string $title, string $body, array $data = []): void
    {
        if ($this->credentials === null) {
            return;
        }

        // Everything below this point is a side effect of an already-successful
        // financial operation (TopUp/Transfer call this after their DB
        // transaction commits). Nothing in here — including the two plain
        // Eloquent calls, which aren't wrapped by the inner try/catches below
        // — may be allowed to throw back into the caller: that would turn a
        // successful money movement into a client-visible 500. Anticipated
        // failure modes (no OAuth token, a single FCM send failing) are still
        // caught individually below and logged as warnings; this outer catch
        // exists only to contain whatever isn't anticipated.
        try {
            $tokens = $user->deviceTokens()->pluck('token');
            if ($tokens->isEmpty()) {
                return;
            }

            try {
                $httpHandler = HttpHandlerFactory::build(new Client(['timeout' => self::HTTP_TIMEOUT_SECONDS]));
                $accessToken = $this->credentials->fetchAuthToken($httpHandler)['access_token'] ?? null;
                $projectId = $this->credentials->getProjectId();
            } catch (Throwable $e) {
                Log::warning('Failed to obtain a Firebase access token.', ['error' => $e->getMessage()]);

                return;
            }

            if (! $accessToken || ! $projectId) {
                return;
            }

            $staleTokens = [];

            foreach ($tokens as $token) {
                try {
                    $response = Http::withToken($accessToken)
                        ->timeout(self::HTTP_TIMEOUT_SECONDS)
                        ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                            'message' => [
                                'token' => $token,
                                'notification' => ['title' => $title, 'body' => $body],
                                'data' => array_map('strval', $data),
                            ],
                        ]);

                    // FCM reports a dead/invalid token as an UNREGISTERED or
                    // NOT_FOUND error - prune those, but never on a generic
                    // failure, since that could just as easily be our own
                    // malformed request or a transient outage.
                    if (in_array($response->json('error.status'), ['UNREGISTERED', 'NOT_FOUND'], true)) {
                        $staleTokens[] = $token;
                    }
                } catch (Throwable $e) {
                    Log::warning('FCM send failed.', ['user_id' => $user->id, 'error' => $e->getMessage()]);
                }
            }

            if (! empty($staleTokens)) {
                DeviceToken::whereIn('token', $staleTokens)->delete();
            }
        } catch (Throwable $e) {
            // Not an anticipated FCM/OAuth failure (those are caught above) -
            // most likely a DB error on the token lookup/prune queries. Logged
            // at `error`, not `warning`, since this is a genuine bug worth
            // investigating rather than an expected external-service hiccup.
            Log::error('Unexpected failure while sending a push notification.', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
