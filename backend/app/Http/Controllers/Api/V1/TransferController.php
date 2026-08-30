<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTransferRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TransferController extends Controller
{
    public function store(StoreTransferRequest $request): JsonResponse
    {
        $amount = $request->validated('amount');
        $currency = $request->validated('currency');
        $recipientEmail = $request->validated('recipient_email');
        $idempotencyKey = $request->validated('idempotency_key');
        $note = $request->validated('note');

        $sender = $request->user();

        if (strcasecmp($recipientEmail, $sender->email) === 0) {
            return response()->json([
                'message' => 'You cannot transfer to yourself.',
            ], 422);
        }

        $recipient = User::where('email', $recipientEmail)->first();
        if (! $recipient) {
            return response()->json([
                'message' => 'No user found with that email.',
            ], 404);
        }

        // Fast path: this exact attempt was already processed. Only the
        // transfer_out row needs checking — it and its transfer_in sibling
        // are created together inside one DB::transaction below, so if one
        // exists, both do.
        $existing = Transaction::where('idempotency_key', $idempotencyKey)
            ->where('type', 'transfer_out')
            ->first();
        if ($existing) {
            return response()->json([
                'transaction' => new TransactionResource($existing),
            ]);
        }

        $outDescription = $note
            ? "Transfer to {$recipient->full_name} — {$note}"
            : "Transfer to {$recipient->full_name}";
        $inDescription = $note
            ? "Transfer from {$sender->full_name} — {$note}"
            : "Transfer from {$sender->full_name}";

        try {
            $outTransaction = DB::transaction(function () use (
                $sender,
                $recipient,
                $amount,
                $currency,
                $idempotencyKey,
                $outDescription,
                $inDescription
            ) {
                $senderWalletId = $sender->wallets()->where('currency', $currency)->value('id');
                $recipientWalletId = $recipient->wallets()->where('currency', $currency)->value('id');

                if (! $senderWalletId || ! $recipientWalletId) {
                    throw ValidationException::withMessages([
                        'currency' => ['Wallet not found for the selected currency.'],
                    ]);
                }

                $wallets = Wallet::whereIn('id', [$senderWalletId, $recipientWalletId])
                    ->orderBy('id')
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('id');

                $senderWallet = $wallets[$senderWalletId];
                $recipientWallet = $wallets[$recipientWalletId];

                if ($senderWallet->balance < $amount) {
                    throw ValidationException::withMessages([
                        'amount' => ['Insufficient balance.'],
                    ]);
                }

                $senderWallet->decrement('balance', $amount);
                $recipientWallet->increment('balance', $amount);

                $recipientWallet->transactions()->create([
                    'related_wallet_id' => $senderWallet->id,
                    'type' => 'transfer_in',
                    'amount' => $amount,
                    'balance_after' => $recipientWallet->balance,
                    'status' => 'completed',
                    'description' => $inDescription,
                    'idempotency_key' => $idempotencyKey,
                ]);

                return $senderWallet->transactions()->create([
                    'related_wallet_id' => $recipientWallet->id,
                    'type' => 'transfer_out',
                    'amount' => $amount,
                    'balance_after' => $senderWallet->balance,
                    'status' => 'completed',
                    'description' => $outDescription,
                    'idempotency_key' => $idempotencyKey,
                ]);
            });
        } catch (QueryException $e) {
            if ((int) ($e->errorInfo[1] ?? 0) === 1062) {
                $existing = Transaction::where('idempotency_key', $idempotencyKey)
                    ->where('type', 'transfer_out')
                    ->firstOrFail();
                return response()->json([
                    'transaction' => new TransactionResource($existing),
                ]);
            }
            throw $e;
        }

        return response()->json([
            'transaction' => new TransactionResource($outTransaction),
        ], 201);
    }
}
