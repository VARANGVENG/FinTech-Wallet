<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\WalletResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{

    public function index(Request $request): JsonResponse
    {
        $wallets = $request->user()->wallets()->get();

        return response()->json([
            'wallets' => WalletResource::collection($wallets),
        ]);
    }
    public function default(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallets()->where('is_default', true)->firstOrFail();

        return response()->json([
            'wallet' => new WalletResource($wallet),
        ]);
    }
}
