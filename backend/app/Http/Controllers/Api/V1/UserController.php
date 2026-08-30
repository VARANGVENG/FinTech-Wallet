<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::where('email', $request->query('email'))->first();

        if (! $user) {
            return response()->json([
                'message' => 'No user found with that email.',
            ], 404);
        }

        return response()->json([
            'user' => new UserResource($user),
        ]);
    }
}
