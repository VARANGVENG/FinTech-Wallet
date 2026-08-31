<?php

use App\Http\Controllers\Api\V1\TransferController;
use App\Http\Controllers\Api\V1\UserController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\TopUpController;
use App\Http\Controllers\Api\V1\TransactionController;
use App\Http\Controllers\Api\V1\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])->middleware('guest');
    Route::post('/login', [AuthController::class, 'login'])->middleware('guest');
    Route::get('/me', [AuthController::class, 'me'])->middleware('auth:sanctum');
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

    Route::get('/wallets', [WalletController::class, 'index'])->middleware('auth:sanctum');
    Route::get('/wallets/default', [WalletController::class, 'default'])->middleware('auth:sanctum');
    Route::get('/wallets/default/transactions', [TransactionController::class, 'index'])->middleware('auth:sanctum');
    Route::get('/wallets/{currency}/transactions', [TransactionController::class, 'byCurrency'])->middleware('auth:sanctum');

    Route::get('/payment-methods', [TopUpController::class, 'methods'])->middleware('auth:sanctum');
    Route::post('/topups', [TopUpController::class, 'store'])->middleware('auth:sanctum');

    Route::get('/users/search', [UserController::class, 'search'])->middleware('auth:sanctum');
    Route::post('/transfers', [TransferController::class, 'store'])->middleware('auth:sanctum');
});
