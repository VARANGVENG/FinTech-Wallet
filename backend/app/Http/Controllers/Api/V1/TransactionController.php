<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\TransactionResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallets()->where('is_default', true)->firstOrFail();

        return $this->respondWithPage($wallet->transactions()->latest()->paginate(20));
    }

    public function byCurrency(Request $request, string $currency): JsonResponse
    {
        $wallet = $request->user()->wallets()->where('currency', $currency)->firstOrFail();

        return $this->respondWithPage($wallet->transactions()->latest()->paginate(20));
    }

    private function respondWithPage(LengthAwarePaginator $paginator): JsonResponse
    {
        return response()->json([
            'transactions' => TransactionResource::collection($paginator),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }
}
