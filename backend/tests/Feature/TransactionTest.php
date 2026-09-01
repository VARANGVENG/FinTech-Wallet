<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TransactionTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_to_default_wallet_transactions_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/wallets/default/transactions');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_request_to_currency_transactions_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/wallets/USD/transactions');

        $response->assertStatus(401);
    }

    public function test_empty_wallet_returns_empty_list_with_correct_pagination_meta(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets/default/transactions');

        $response->assertStatus(200)
            ->assertJson([
                'transactions' => [],
                'meta' => [
                    'current_page' => 1,
                    'last_page' => 1,
                    'per_page' => 20,
                    'total' => 0,
                ],
            ]);
    }

    public function test_authenticated_user_sees_their_own_default_wallet_transactions(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);

        $transaction = Transaction::factory()->for($wallet)->create([
            'type' => 'topup',
            'amount' => 25.50,
            'balance_after' => 25.50,
            'status' => 'completed',
            'description' => 'Top-up via Linked Bank',
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets/default/transactions');

        $response->assertStatus(200)
            ->assertJson([
                'transactions' => [
                    [
                        'id' => $transaction->id,
                        'type' => 'topup',
                        'amount' => 25.50,
                        'balance_after' => 25.50,
                        'status' => 'completed',
                        'description' => 'Top-up via Linked Bank',
                    ],
                ],
            ])
            ->assertJsonStructure([
                'transactions' => [
                    ['id', 'type', 'amount', 'balance_after', 'status', 'description', 'related_wallet_id', 'created_at'],
                ],
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ]);
    }

    public function test_transactions_are_ordered_newest_first(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);

        $older = Transaction::factory()->for($wallet)->create(['created_at' => now()->subMinutes(10)]);
        $newer = Transaction::factory()->for($wallet)->create(['created_at' => now()]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets/default/transactions');

        $ids = collect($response->json('transactions'))->pluck('id');
        $this->assertEquals([$newer->id, $older->id], $ids->toArray());
    }

    public function test_pagination_meta_is_correct_across_multiple_pages(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);

        Transaction::factory()->for($wallet)->count(25)->create();

        Sanctum::actingAs($user);

        $page1 = $this->getJson('/api/v1/wallets/default/transactions')->json();
        $this->assertCount(20, $page1['transactions']);
        $this->assertEquals(1, $page1['meta']['current_page']);
        $this->assertEquals(2, $page1['meta']['last_page']);
        $this->assertEquals(25, $page1['meta']['total']);

        $page2 = $this->getJson('/api/v1/wallets/default/transactions?page=2')->json();
        $this->assertCount(5, $page2['transactions']);
        $this->assertEquals(2, $page2['meta']['current_page']);
    }

    public function test_user_a_cannot_see_user_b_transactions(): void
    {
        $userA = User::factory()->create();
        Wallet::factory()->for($userA)->create(['currency' => 'USD', 'is_default' => true]);

        $userB = User::factory()->create();
        $walletB = Wallet::factory()->for($userB)->create(['currency' => 'USD', 'is_default' => true]);
        Transaction::factory()->for($walletB)->create();

        Sanctum::actingAs($userA);

        $response = $this->getJson('/api/v1/wallets/default/transactions');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'transactions');
    }

    public function test_by_currency_returns_the_correct_wallets_transactions(): void
    {
        $user = User::factory()->create();
        $usdWallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);
        $khrWallet = Wallet::factory()->khr()->for($user)->create();

        Transaction::factory()->for($usdWallet)->create(['description' => 'USD transaction']);
        Transaction::factory()->for($khrWallet)->create(['description' => 'KHR transaction']);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets/KHR/transactions');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'transactions')
            ->assertJson([
                'transactions' => [
                    ['description' => 'KHR transaction'],
                ],
            ]);
    }

    public function test_by_currency_404s_for_a_currency_the_user_does_not_hold(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);

        Sanctum::actingAs($user);

        // The user has no KHR wallet at all in this test (unlike the
        // registration flow, which always creates one) - this exercises
        // the firstOrFail() 404 path directly.
        $response = $this->getJson('/api/v1/wallets/KHR/transactions');

        $response->assertStatus(404);
    }
}
