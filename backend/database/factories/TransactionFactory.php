<?php

namespace Database\Factories;

use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Transaction>
 */
class TransactionFactory extends Factory
{
    protected $model = Transaction::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'wallet_id' => Wallet::factory(),
            'related_wallet_id' => null,
            'type' => 'topup',
            'amount' => 10,
            'balance_after' => 10,
            'status' => 'completed',
            'description' => 'Top-up via Linked Bank',
            'idempotency_key' => (string) Str::uuid(),
        ];
    }

    public function transferOut(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'transfer_out',
            'description' => 'Transfer',
        ]);
    }

    public function transferIn(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'transfer_in',
            'description' => 'Transfer',
        ]);
    }
}
