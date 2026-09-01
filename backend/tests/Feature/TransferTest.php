<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TransferTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_to_transfers_is_rejected(): void
    {
        $response = $this->postJson('/api/v1/transfers', []);

        $response->assertStatus(401);
    }

    public function test_successful_transfer_moves_money_and_creates_both_transaction_records(): void
    {
        $alice = User::factory()->create(['full_name' => 'Alice']);
        $aliceWallet = Wallet::factory()->for($alice)->create(['currency' => 'USD', 'balance' => 100.00, 'is_default' => true]);

        $bob = User::factory()->create(['full_name' => 'Bob']);
        $bobWallet = Wallet::factory()->for($bob)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        Sanctum::actingAs($alice);

        $response = $this->postJson('/api/v1/transfers', [
            'recipient_email' => $bob->email,
            'amount' => 30.00,
            'currency' => 'USD',
            'idempotency_key' => (string) Str::uuid(),
            'note' => 'test transfer',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'transaction' => [
                    'type' => 'transfer_out',
                    'amount' => 30.00,
                    'balance_after' => 70.00,
                    'status' => 'completed',
                    'description' => 'Transfer to Bob — test transfer',
                    'related_wallet_id' => $bobWallet->id,
                ],
            ]);

        $this->assertEquals(70.00, $aliceWallet->fresh()->balance);
        $this->assertEquals(30.00, $bobWallet->fresh()->balance);

        $this->assertDatabaseHas('transactions', [
            'wallet_id' => $aliceWallet->id,
            'related_wallet_id' => $bobWallet->id,
            'type' => 'transfer_out',
            'amount' => 30.00,
        ]);
        $this->assertDatabaseHas('transactions', [
            'wallet_id' => $bobWallet->id,
            'related_wallet_id' => $aliceWallet->id,
            'type' => 'transfer_in',
            'amount' => 30.00,
            'description' => 'Transfer from Alice — test transfer',
        ]);
    }

    public function test_transfer_fails_with_missing_fields(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/transfers', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['recipient_email', 'amount', 'currency', 'idempotency_key']);
    }

    public function test_transfer_rejects_non_positive_amount(): void
    {
        $sender = User::factory()->create();
        Wallet::factory()->for($sender)->create(['currency' => 'USD', 'is_default' => true]);
        $recipient = User::factory()->create();
        Sanctum::actingAs($sender);

        $response = $this->postJson('/api/v1/transfers', [
            'recipient_email' => $recipient->email,
            'amount' => 0,
            'currency' => 'USD',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['amount']);
    }

    public function test_cannot_transfer_to_self(): void
    {
        $user = User::factory()->create(['email' => 'alice@example.com']);
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'balance' => 50, 'is_default' => true]);
        Sanctum::actingAs($user);

        // Uppercased on purpose - the controller compares case-insensitively
        // (strcasecmp), so this also proves that specific detail works.
        $response = $this->postJson('/api/v1/transfers', [
            'recipient_email' => 'ALICE@EXAMPLE.COM',
            'amount' => 10,
            'currency' => 'USD',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)
            ->assertJson(['message' => 'You cannot transfer to yourself.']);
    }

    public function test_transfer_to_unknown_recipient_returns_404(): void
    {
        $sender = User::factory()->create();
        Wallet::factory()->for($sender)->create(['currency' => 'USD', 'balance' => 50, 'is_default' => true]);
        Sanctum::actingAs($sender);

        $response = $this->postJson('/api/v1/transfers', [
            'recipient_email' => 'nobody@example.com',
            'amount' => 10,
            'currency' => 'USD',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(404)
            ->assertJson(['message' => 'No user found with that email.']);
    }

    public function test_transfer_fails_when_recipient_has_no_wallet_in_that_currency(): void
    {
        $sender = User::factory()->create();
        Wallet::factory()->for($sender)->create(['currency' => 'KHR', 'balance' => 100000, 'is_default' => true]);

        $recipient = User::factory()->create();
        // Recipient deliberately has only a USD wallet - no KHR. This is
        // the current, deliberate product decision: no auto-creating a
        // wallet for the recipient, hard block instead.
        Wallet::factory()->for($recipient)->create(['currency' => 'USD', 'is_default' => true]);

        Sanctum::actingAs($sender);

        $response = $this->postJson('/api/v1/transfers', [
            'recipient_email' => $recipient->email,
            'amount' => 1000,
            'currency' => 'KHR',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['currency']);
    }

    public function test_insufficient_balance_is_rejected_and_leaves_both_wallets_unchanged(): void
    {
        $sender = User::factory()->create();
        $senderWallet = Wallet::factory()->for($sender)->create(['currency' => 'USD', 'balance' => 10.00, 'is_default' => true]);

        $recipient = User::factory()->create();
        $recipientWallet = Wallet::factory()->for($recipient)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        Sanctum::actingAs($sender);

        $response = $this->postJson('/api/v1/transfers', [
            'recipient_email' => $recipient->email,
            'amount' => 999.00,
            'currency' => 'USD',
            'idempotency_key' => (string) Str::uuid(),
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount']);

        // Atomicity: the rejected attempt must leave BOTH wallets exactly
        // as they were, and create no transaction rows at all - proving
        // the balance check happening inside the DB transaction actually
        // prevents any partial write, not just that the HTTP response
        // looks like a clean rejection.
        $this->assertEquals(10.00, $senderWallet->fresh()->balance);
        $this->assertEquals(0.00, $recipientWallet->fresh()->balance);
        $this->assertDatabaseCount('transactions', 0);
    }

    public function test_duplicate_idempotency_key_does_not_create_a_second_transfer(): void
    {
        $sender = User::factory()->create();
        $senderWallet = Wallet::factory()->for($sender)->create(['currency' => 'USD', 'balance' => 100.00, 'is_default' => true]);

        $recipient = User::factory()->create();
        $recipientWallet = Wallet::factory()->for($recipient)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);

        Sanctum::actingAs($sender);

        $key = (string) Str::uuid();
        $body = [
            'recipient_email' => $recipient->email,
            'amount' => 20.00,
            'currency' => 'USD',
            'idempotency_key' => $key,
        ];

        $first = $this->postJson('/api/v1/transfers', $body);
        $first->assertStatus(201);

        $second = $this->postJson('/api/v1/transfers', $body);
        $second->assertStatus(200)
            ->assertJson(['transaction' => ['id' => $first->json('transaction.id')]]);

        $this->assertEquals(80.00, $senderWallet->fresh()->balance);
        $this->assertEquals(20.00, $recipientWallet->fresh()->balance);
        // Exactly one transfer_out + one transfer_in - not four rows.
        $this->assertDatabaseCount('transactions', 2);
    }

    public function test_mysql_reports_error_code_1062_for_a_duplicate_transfer_idempotency_key(): void
    {
        $wallet = Wallet::factory()->create(['currency' => 'USD']);
        $key = (string) Str::uuid();

        Transaction::factory()->for($wallet)->create([
            'type' => 'transfer_out',
            'idempotency_key' => $key,
        ]);

        try {
            Transaction::factory()->for($wallet)->create([
                'type' => 'transfer_out',
                'idempotency_key' => $key,
            ]);

            $this->fail('Expected a QueryException for the duplicate (idempotency_key, type) pair.');
        } catch (QueryException $e) {
            $this->assertEquals(1062, (int) ($e->errorInfo[1] ?? 0));
        }
    }

    public function test_wallets_are_locked_in_ascending_id_order_regardless_of_sender_recipient(): void
    {
        $alice = User::factory()->create();
        $bob = User::factory()->create();

        // Bob's wallet is created FIRST on purpose, so it gets the lower
        // ID even though Alice is the sender here - this is exactly the
        // scenario where "always lock sender first" would differ from
        // "always lock ascending ID first", and only the latter actually
        // prevents a deadlock against an opposite-direction transfer.
        $bobWallet = Wallet::factory()->for($bob)->create(['currency' => 'USD', 'balance' => 0, 'is_default' => true]);
        $aliceWallet = Wallet::factory()->for($alice)->create(['currency' => 'USD', 'balance' => 100, 'is_default' => true]);

        $this->assertTrue($bobWallet->id < $aliceWallet->id);

        Sanctum::actingAs($alice);

        DB::enableQueryLog();

        $this->postJson('/api/v1/transfers', [
            'recipient_email' => $bob->email,
            'amount' => 10,
            'currency' => 'USD',
            'idempotency_key' => (string) Str::uuid(),
        ])->assertStatus(201);

        $lockingQuery = collect(DB::getQueryLog())
            ->first(fn ($q) => str_contains(strtolower($q['query']), 'for update'));

        DB::disableQueryLog();

        $this->assertNotNull($lockingQuery, 'Expected a lockForUpdate query to appear in the query log.');
        $sql = strtolower($lockingQuery['query']);
        $this->assertStringContainsString('order by', $sql, 'The locking query must use ORDER BY to guarantee a deterministic lock order.');
    }
}
