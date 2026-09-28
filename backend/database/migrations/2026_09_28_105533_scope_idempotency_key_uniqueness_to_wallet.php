<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // (idempotency_key, type) alone is unique across ALL users' wallets,
        // so a key collision between two different users' requests (a
        // replay, a guess, or a genuine UUID collision) makes the second
        // request's pre-check and 1062-recovery both match the FIRST user's
        // row instead of ever attempting the second user's own transaction.
        // Scoping uniqueness to wallet_id as well closes that at the schema
        // level: two different users can never share a wallet_id, so their
        // idempotency keys can never collide regardless of what the
        // application-layer query does.
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropUnique(['idempotency_key', 'type']);
            $table->unique(['idempotency_key', 'type', 'wallet_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropUnique(['idempotency_key', 'type', 'wallet_id']);
            $table->unique(['idempotency_key', 'type']);
        });
    }
};
