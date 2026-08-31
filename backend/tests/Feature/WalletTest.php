<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WalletTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_to_wallets_index_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/wallets');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_request_to_default_wallet_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/wallets/default');

        $response->assertStatus(401);
    }

    public function test_authenticated_user_sees_only_their_own_wallets(): void
    {
        $user = User::factory()->create();
        $usdWallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'balance' => 42.50]);
        $khrWallet = Wallet::factory()->khr()->for($user)->create(['balance' => 1000]);

        // Another user's wallets must never appear in the response.
        $otherUser = User::factory()->create();
        Wallet::factory()->for($otherUser)->create();

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets');

        $response->assertStatus(200);
        $ids = collect($response->json('wallets'))->pluck('id');
        $this->assertCount(2, $ids);
        $this->assertTrue($ids->contains($usdWallet->id));
        $this->assertTrue($ids->contains($khrWallet->id));
    }

    public function test_wallet_index_response_envelope_matches_expected_shape(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->create([
            'name' => 'Nova Pay Wallet',
            'currency' => 'USD',
            'balance' => 99.99,
            'is_default' => true,
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets');

        $response->assertStatus(200)
            ->assertJson([
                'wallets' => [
                    [
                        'name' => 'Nova Pay Wallet',
                        'currency' => 'USD',
                        'balance' => 99.99,
                        'is_default' => true,
                    ],
                ],
            ])
            ->assertJsonStructure([
                'wallets' => [
                    ['id', 'name', 'currency', 'balance', 'is_default'],
                ],
            ]);
    }

    public function test_default_wallet_returns_the_wallet_flagged_as_default(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->khr()->for($user)->create();
        $defaultWallet = Wallet::factory()->for($user)->create(['currency' => 'USD', 'is_default' => true]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets/default');

        $response->assertStatus(200)
            ->assertJson([
                'wallet' => ['id' => $defaultWallet->id, 'currency' => 'USD', 'is_default' => true],
            ]);
    }

    public function test_default_wallet_404s_when_user_has_no_default_wallet(): void
    {
        $user = User::factory()->create();
        Wallet::factory()->for($user)->notDefault()->create();

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/wallets/default');

        $response->assertStatus(404);
    }

    public function test_user_a_cannot_access_user_b_default_wallet(): void
    {
        $userA = User::factory()->create();

        $userB = User::factory()->create();
        Wallet::factory()->for($userB)->create(['is_default' => true, 'balance' => 500]);

        // User A has no default wallet of their own — if the endpoint were
        // not scoped to the authenticated user, it could leak User B's.
        Sanctum::actingAs($userA);

        $response = $this->getJson('/api/v1/wallets/default');

        $response->assertStatus(404);
    }

    public function test_database_rejects_a_negative_wallet_balance(): void
    {
        $this->expectException(QueryException::class);

        Wallet::factory()->create(['balance' => -0.01]);
    }
}
