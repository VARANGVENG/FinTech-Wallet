<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Wallet>
 */
class WalletFactory extends Factory
{
    protected $model = Wallet::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => 'Nova Pay Wallet',
            'currency' => 'USD',
            'balance' => 0,
            'is_default' => true,
        ];
    }

    public function khr(): static
    {
        return $this->state(fn (array $attributes) => [
            'name' => 'Nova Pay Wallet (KHR)',
            'currency' => 'KHR',
            'is_default' => false,
        ]);
    }

    public function notDefault(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_default' => false,
        ]);
    }
}
