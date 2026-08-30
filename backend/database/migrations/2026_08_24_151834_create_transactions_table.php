<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('related_wallet_id')->nullable()->constrained('wallets')->nullOnDelete();
            $table->string('type');
            $table->decimal('amount', 15, 2);
            $table->decimal('balance_after', 15, 2);
            $table->string('status');
            $table->string('description')->nullable();
            $table->timestamps();

            $table->index(['wallet_id', 'created_at']);
        });

        DB::statement("ALTER TABLE transactions ADD CONSTRAINT chk_transactions_type CHECK (type IN ('topup','transfer_in','transfer_out'))");
        DB::statement('ALTER TABLE transactions ADD CONSTRAINT chk_transactions_amount_positive CHECK (amount > 0)');
        DB::statement('ALTER TABLE transactions ADD CONSTRAINT chk_transactions_balance_after_nonneg CHECK (balance_after >= 0)');
        DB::statement("ALTER TABLE transactions ADD CONSTRAINT chk_transactions_status CHECK (status IN ('pending','completed'))");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
