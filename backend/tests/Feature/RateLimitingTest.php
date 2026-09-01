<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RateLimitingTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_is_throttled_after_five_attempts_for_the_same_email_and_ip(): void
    {
        User::factory()->create([
            'email' => 'victim@example.com',
            'password' => 'password123',
        ]);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/login', [
                'email' => 'victim@example.com',
                'password' => 'wrongpassword',
            ])->assertStatus(401);
        }

        // The 6th attempt within the same minute is throttled outright,
        // not just rejected as another bad-credentials guess.
        $this->postJson('/api/v1/login', [
            'email' => 'victim@example.com',
            'password' => 'wrongpassword',
        ])->assertStatus(429);
    }

    public function test_login_throttle_is_scoped_per_email_so_one_locked_out_account_does_not_block_others(): void
    {
        User::factory()->create(['email' => 'victim@example.com', 'password' => 'password123']);
        User::factory()->create(['email' => 'other@example.com', 'password' => 'password123']);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/login', [
                'email' => 'victim@example.com',
                'password' => 'wrongpassword',
            ]);
        }

        // victim@example.com is now locked out from this IP, but the
        // limiter key includes the email, not just the IP - so an
        // attacker spamming one victim's address can't also lock every
        // other account out from that same IP.
        $this->postJson('/api/v1/login', [
            'email' => 'other@example.com',
            'password' => 'password123',
        ])->assertStatus(200);
    }

    public function test_register_is_throttled_after_six_attempts_from_the_same_ip(): void
    {
        for ($i = 0; $i < 6; $i++) {
            $this->postJson('/api/v1/register', [
                'full_name' => "User {$i}",
                'email' => "user{$i}@example.com",
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ])->assertStatus(201);
        }

        $this->postJson('/api/v1/register', [
            'full_name' => 'One Too Many',
            'email' => 'onetoomany@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertStatus(429);
    }

    public function test_general_api_throttle_blocks_after_sixty_requests_per_minute_for_the_same_user(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        for ($i = 0; $i < 60; $i++) {
            $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/me')
                ->assertStatus(200);
        }

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/me')
            ->assertStatus(429);
    }
}
