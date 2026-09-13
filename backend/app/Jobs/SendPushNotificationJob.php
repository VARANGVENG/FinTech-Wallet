<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\PushNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

/**
 * Queued so a slow/unreachable Google OAuth or FCM endpoint can never block
 * the TopUp/Transfer HTTP response that dispatches this - the notification
 * is a side effect of an already-successful financial operation, not part
 * of it.
 *
 * No $tries/$backoff is set here: PushNotificationService::sendToUser()
 * already catches every failure it can anticipate (and, as of the
 * surrounding fix, everything else too) and logs rather than throwing, so
 * this job is never expected to fail in a way the queue would retry. That
 * matches the project's existing queue convention - see the `queue:listen
 * --tries=1` dev script in composer.json - rather than introducing new
 * retry behavior no one asked for.
 */
class SendPushNotificationJob implements ShouldQueue
{
    use Queueable;

    /**
     * @param  array<string, mixed>  $data
     */
    public function __construct(
        public readonly User $user,
        public readonly string $title,
        public readonly string $body,
        public readonly array $data = [],
    ) {
    }

    public function handle(PushNotificationService $pushService): void
    {
        $pushService->sendToUser($this->user, $this->title, $this->body, $this->data);
    }
}
