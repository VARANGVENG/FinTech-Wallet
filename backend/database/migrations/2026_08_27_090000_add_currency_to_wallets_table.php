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
        Schema::table('wallets', function (Blueprint $table) {
            $table->string('currency')->default('USD')->after('name');
        });

        DB::statement("ALTER TABLE wallets ADD CONSTRAINT chk_wallets_currency CHECK (currency IN ('USD','KHR'))");
        DB::statement('ALTER TABLE wallets ADD CONSTRAINT uq_wallets_user_currency UNIQUE (user_id, currency)');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE wallets DROP CONSTRAINT chk_wallets_currency');

        Schema::table('wallets', function (Blueprint $table) {
            $table->dropUnique('uq_wallets_user_currency');
            $table->dropColumn('currency');
        });
    }
};
