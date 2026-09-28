<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use App\Services\PushNotificationService;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TopUpTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_to_payment_methods_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/payment-methods');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_request_to_topups_is_rejected(): void
    {
        $response = $this->postJson('/api/v1/topups', []);

        $response->assertStatus(401);
    }

    public function test_payment_methods_returns_the_fixed_list(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/payment-methods');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'methods')
            ->assertJson([
                'methods' => [
                    ['type' => 'linkedBank', 'title' => 'Linked Bank'],
                    ['type' => 'debitCard', 'title' => 'Debit Card'],
                    ['type' => 'applePay', 'title' => 'Apple Pay'],
                ],
            ]);
    }

    public function test_valid_topup_increases_balance_and_creates_transaction(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'balance' => 10.00, 'is_default' => true]);

        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/topups', [
            'amount' => 25.50,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'transaction' => [
                    'type' => 'topup',
                    'amount' => 25.50,
                    'balance_after' => 35.50,
                    'status' => 'completed',
                    'description' => 'Top-up via Linked Bank',
                ],
            ]);

        $this->assertEquals(35.50, $wallet->fresh()->balance);

        $this->assertDatabaseHas('transactions', [
            'wallet_id' => $wallet->id,
            'type' => 'topup',
            'amount' => 25.50,
            'balance_after' => 35.50,
        ]);
    }

    public function test_topup_fails_with_missing_fields(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/topups', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount', 'currency', 'method', 'idempotency_key']);
    }

    public function test_topup_rejects_non_positive_amount(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/topups', [
            'amount' => 0,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount']);
    }

    public function test_topup_rejects_unsupported_currency(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/topups', [
            'amount' => 10,
            'currency' => 'EUR',
            'method' => 'linkedBank',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['currency']);
    }

    public function test_topup_rejects_unsupported_method(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/topups', [
            'amount' => 10,
            'currency' => 'USD',
            'method' => 'bitcoin',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['method']);
    }

    public function test_topup_404s_when_user_has_no_wallet_in_that_currency(): void
    {
        $user = User::factory()->create();
        // Deliberately only a USD wallet - unlike real registration
        // (which always creates both), this test controls the fixture
        // directly to exercise the missing-wallet path.
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/topups', [
            'amount' => 10,
            'currency' => 'KHR',
            'method' => 'linkedBank',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(404);
    }

    public function test_duplicate_idempotency_key_does_not_create_a_second_topup(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);
        Sanctum::actingAs($user);

        $key = (string) Str::uuid();
        $body = [
            'amount' => 50.00,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => $key,
        ];

        $first = $this->postJson('/api/v1/topups', $body);
        $first->assertStatus(201);

        // Same key, sent again - the normal "client retried" case. The
        // pre-check in TopUpController finds the already-committed row
        // from the first request and returns it directly, without ever
        // touching the wallet balance a second time.
        $second = $this->postJson('/api/v1/topups', $body);
        $second->assertStatus(200)
            ->assertJson(['transaction' => ['id' => $first->json('transaction.id')]]);

        $this->assertEquals(50.00, $wallet->fresh()->balance);
        $this->assertDatabaseCount('transactions', 1);
    }

    /**
     * NOV-21 cross-user isolation check. The idempotency pre-check in
     * TopUpController::store() is Transaction::where('idempotency_key', ...)
     * with no 'type' filter and no scoping to the requesting user at all —
     * strictly less scoped than TransferController's equivalent. If Bob's
     * request reuses a key Alice already used, the secure behaviour is for
     * Bob's own top-up to go through as a normal first-time request.
     * Anything else means Bob's response carries Alice's transaction, and
     * Bob's own wallet is never actually credited.
     */
    public function test_user_b_reusing_user_as_idempotency_key_gets_their_own_topup_not_user_as(): void
    {
        $alice = User::factory()->create();
        Wallet::factory()->for($alice)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        $key = (string) Str::uuid();

        Sanctum::actingAs($alice);
        $aliceResponse = $this->postJson('/api/v1/topups', [
            'amount' => 40.00,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => $key,
        ]);
        $aliceResponse->assertStatus(201);
        $aliceTransactionId = $aliceResponse->json('transaction.id');

        $bob = User::factory()->create();
        $bobWallet = Wallet::factory()->for($bob)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        Sanctum::actingAs($bob);
        $bobResponse = $this->postJson('/api/v1/topups', [
            'amount' => 40.00,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => $key,
        ]);

        $bobResponse->assertStatus(201);
        $this->assertNotEquals($aliceTransactionId, $bobResponse->json('transaction.id'));
        $this->assertEquals(40.00, $bobWallet->fresh()->balance, 'Bob\'s own top-up must actually execute, not be short-circuited by Alice\'s key.');
    }

    /**
     * This is the actual H.1 investigation. A genuinely concurrent race
     * (two requests both passing the pre-check before either commits)
     * can't be deterministically reproduced in a single-threaded,
     * single-connection PHPUnit run - that's a real tooling limitation,
     * not a shortcut. What CAN be tested deterministically is the exact
     * premise TopUpController's catch block depends on: that inserting a
     * second transaction with the same (idempotency_key, type) pair
     * really does throw a QueryException with MySQL's duplicate-key
     * error code, 1062, against the real MySQL engine this test suite
     * now runs on (novapay_testing) - unlike the original broken SQLite
     * setup, where this code never even had a chance to run.
     */
    public function test_mysql_reports_error_code_1062_for_a_duplicate_idempotency_key_and_type(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);
        $key = (string) Str::uuid();

        Transaction::factory()->for($wallet)->create([
            'type' => 'topup',
            'idempotency_key' => $key,
        ]);

        try {
            Transaction::factory()->for($wallet)->create([
                'type' => 'topup',
                'idempotency_key' => $key,
            ]);

            $this->fail('Expected a QueryException for the duplicate (idempotency_key, type) pair - the UNIQUE constraint did not fire.');
        } catch (QueryException $e) {
            $this->assertEquals(1062, (int) ($e->errorInfo[1] ?? 0));
        }
    }

    public function test_successful_topup_sends_a_push_notification(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        $this->mock(PushNotificationService::class)
            ->shouldReceive('sendToUser')
            ->once()
            ->withArgs(fn ($u) => $u->is($user));

        Sanctum::actingAs($user);

        $this->postJson('/api/v1/topups', [
            'amount' => 25,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => (string) Str::uuid(),
        ])->assertStatus(201);
    }

    public function test_idempotent_replay_of_a_topup_does_not_resend_a_push_notification(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        $this->mock(PushNotificationService::class)->shouldReceive('sendToUser')->once();

        Sanctum::actingAs($user);

        $body = [
            'amount' => 25,
            'currency' => 'USD',
            'method' => 'linkedBank',
            'idempotency_key' => (string) Str::uuid(),
        ];

        $this->postJson('/api/v1/topups', $body)->assertStatus(201);
        $this->postJson('/api/v1/topups', $body)->assertStatus(200);
    }
}
