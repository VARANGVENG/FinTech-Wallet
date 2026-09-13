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
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // Globally unique, not scoped to user_id: a token identifies one
            // device install. If a different user logs into the same phone,
            // re-registering must move the token to them, not create a
            // second row - otherwise the previous user keeps getting pushes
            // meant for the new one.
            $table->string('token')->unique();
            $table->string('platform')->default('android');
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};
