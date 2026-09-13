<?php

namespace App\Providers;

use App\Services\PushNotificationService;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Schema\Builder;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;
use Throwable;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(PushNotificationService::class, function () {
            $path = config('services.firebase.credentials');

            try {
                if (! $path || ! is_string($path) || ! file_exists($path)) {
                    throw new \RuntimeException("Firebase credentials file not found at [{$path}].");
                }

                $credentials = new ServiceAccountCredentials(
                    'https://www.googleapis.com/auth/firebase.messaging',
                    $path,
                );
            } catch (Throwable $e) {
                // Missing/invalid Firebase credentials must not stop the
                // app from booting - PushNotificationService treats a null
                // credentials object as "push disabled" and no-ops.
                Log::warning('Push notifications disabled: '.$e->getMessage());
                $credentials = null;
            }

            return new PushNotificationService($credentials);
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Builder::defaultStringLength(191);
        JsonResource::withoutWrapping();

        // Keyed by email+IP (not IP alone) so a single attacker can't lock
        // out an arbitrary victim account by hammering it from many IPs
        // being the only thing that matters - matches Laravel Fortify's
        // own default login limiter.
        RateLimiter::for('login', function ($request) {
            $key = Str::transliterate(Str::lower((string) $request->input('email')).'|'.$request->ip());

            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('register', function ($request) {
            return Limit::perMinute(6)->by($request->ip());
        });

        RateLimiter::for('api', function ($request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });
    }
}
