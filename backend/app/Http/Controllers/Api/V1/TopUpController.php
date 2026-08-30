<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTopUpRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TopUpController extends Controller
{
    /**
     * Not backed by a database table — no real payment processor is
     * integrated, so this is a fixed set the frontend picks from.
     */
    private const PAYMENT_METHODS = [
        ['type' => 'linkedBank', 'title' => 'Linked Bank', 'subtitle' => '•••• 1234', 'iconAsset' => 'bank'],
        ['type' => 'debitCard', 'title' => 'Debit Card', 'subtitle' => '•••• 4242', 'iconAsset' => 'card'],
        ['type' => 'applePay', 'title' => 'Apple Pay', 'subtitle' => 'Secure & fast', 'iconAsset' => 'apple_pay'],
    ];

    public function methods(Request $request): JsonResponse
    {
        return response()->json([
            'methods' => self::PAYMENT_METHODS,
        ]);
    }

    public function store(StoreTopUpRequest $request): JsonResponse
    {
        $amount = $request->validated('amount');
        $currency = $request->validated('currency');
        $method = $request->validated('method');
        $idempotencyKey = $request->validated('idempotency_key');

        // Fast path: this exact attempt was already processed (a retried
        // request, a double-tap the client didn't fully block). Return the
        // original result instead of doing the work again.
        $existing = Transaction::where('idempotency_key', $idempotencyKey)->first();
        if ($existing) {
            return response()->json([
                'transaction' => new TransactionResource($existing),
            ]);
        }

        $methodTitle = collect(self::PAYMENT_METHODS)->firstWhere('type', $method)['title'] ?? $method;

        try {
            $transaction = DB::transaction(function () use ($request, $amount, $currency, $methodTitle, $idempotencyKey) {
                $wallet = $request->user()
                    ->wallets()
                    ->where('currency', $currency)
                    ->lockforUpdate()
                    ->firstOrFail();

                $wallet->increment('balance', $amount);

                return $wallet->transactions()->create([
                    'type' => 'topup',
                    'amount' => $amount,
                    'balance_after' => $wallet->balance,
                    'status' => 'completed',
                    'description' => "Top-up via {$methodTitle}",
                    'idempotency_key' => $idempotencyKey,
                ]);
            });
        } catch (QueryException $e) {
            // Two requests with the same idempotency_key raced past the
            // check above and both reached this point. Only one insert can
            // win (the unique constraint from the migration guarantees
            // that), so the loser's whole transaction — including its
            // balance increment — rolls back automatically. Return the
            // winner's result instead of surfacing an error.
            if ((int) ($e->errorInfo[1] ?? 0) === 1062) {
                $existing = Transaction::where('idempotency_key', $idempotencyKey)->firstOrFail();
                return response()->json([
                    'transaction' => new TransactionResource($existing),
                ]);
            }
            throw $e;
        }

        return response()->json([
            'transaction' => new TransactionResource($transaction),
        ], 201);
    }
}
