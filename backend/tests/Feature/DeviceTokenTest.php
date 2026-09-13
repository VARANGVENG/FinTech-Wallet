<?php

namespace Tests\Feature;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeviceTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_to_register_device_token_is_rejected(): void
    {
        $response = $this->postJson('/api/v1/device-tokens', ['token' => 'abc']);

        $response->assertStatus(401);
    }

    public function test_authenticated_user_can_register_a_device_token(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/device-tokens', [
            'token' => 'fcm-token-123',
            'platform' => 'android',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $user->id,
            'token' => 'fcm-token-123',
            'platform' => 'android',
        ]);
    }

    public function test_registering_the_same_token_twice_does_not_duplicate_it(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/device-tokens', ['token' => 'fcm-token-123'])->assertStatus(201);
        $this->postJson('/api/v1/device-tokens', ['token' => 'fcm-token-123'])->assertStatus(201);

        $this->assertDatabaseCount('device_tokens', 1);
    }

    public function test_registering_a_token_already_owned_by_another_user_reassigns_it(): void
    {
        $alice = User::factory()->create();
        $bob = User::factory()->create();

        DeviceToken::factory()->for($alice)->create(['token' => 'shared-device-token']);

        Sanctum::actingAs($bob);
        $this->postJson('/api/v1/device-tokens', ['token' => 'shared-device-token'])->assertStatus(201);

        $this->assertDatabaseCount('device_tokens', 1);
        $this->assertDatabaseHas('device_tokens', [
            'token' => 'shared-device-token',
            'user_id' => $bob->id,
        ]);
    }

    public function test_user_can_unregister_their_device_token(): void
    {
        $user = User::factory()->create();
        DeviceToken::factory()->for($user)->create(['token' => 'fcm-token-123']);
        Sanctum::actingAs($user);

        $response = $this->deleteJson('/api/v1/device-tokens', ['token' => 'fcm-token-123']);

        $response->assertStatus(200);
        $this->assertDatabaseMissing('device_tokens', ['token' => 'fcm-token-123']);
    }

    public function test_user_cannot_unregister_a_token_belonging_to_another_user(): void
    {
        $alice = User::factory()->create();
        $bob = User::factory()->create();
        DeviceToken::factory()->for($alice)->create(['token' => 'alices-token']);

        Sanctum::actingAs($bob);
        $this->deleteJson('/api/v1/device-tokens', ['token' => 'alices-token'])->assertStatus(200);

        $this->assertDatabaseHas('device_tokens', ['token' => 'alices-token', 'user_id' => $alice->id]);
    }
}
