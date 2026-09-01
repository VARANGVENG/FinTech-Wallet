<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserSearchTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_to_user_search_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/users/search?email=someone@example.com');

        $response->assertStatus(401);
    }

    public function test_search_fails_without_an_email_query_param(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/users/search');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_search_fails_with_a_malformed_email(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/users/search?email=not-an-email');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_search_finds_an_existing_user_by_exact_email(): void
    {
        $requester = User::factory()->create();
        $target = User::factory()->create([
            'full_name' => 'Bob Recipient',
            'email' => 'bob@example.com',
        ]);

        Sanctum::actingAs($requester);

        $response = $this->getJson('/api/v1/users/search?email=bob@example.com');

        $response->assertStatus(200)
            ->assertJson([
                'user' => [
                    'id' => $target->id,
                    'full_name' => 'Bob Recipient',
                    'email' => 'bob@example.com',
                ],
            ])
            ->assertJsonMissingPath('user.password');
    }

    public function test_search_returns_404_for_an_email_that_does_not_exist(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/users/search?email=nobody@example.com');

        $response->assertStatus(404)
            ->assertJson(['message' => 'No user found with that email.']);
    }
}
