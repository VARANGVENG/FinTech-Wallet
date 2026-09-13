<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\DestroyDeviceTokenRequest;
use App\Http\Requests\StoreDeviceTokenRequest;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;

class DeviceTokenController extends Controller
{
    public function store(StoreDeviceTokenRequest $request): JsonResponse
    {
        // Query DeviceToken directly rather than
        // $request->user()->deviceTokens()->updateOrCreate(...) - the
        // relation-scoped version scopes the *lookup* to this user's own
        // tokens too, so a token already owned by a different user (same
        // physical device, different account) wouldn't match and would hit
        // the unique constraint on insert instead of transferring ownership.
        DeviceToken::updateOrCreate(
            ['token' => $request->validated('token')],
            [
                'user_id' => $request->user()->id,
                'platform' => $request->validated('platform', 'android'),
                'last_used_at' => now(),
            ],
        );

        return response()->json(['message' => 'Device token registered.'], 201);
    }

    public function destroy(DestroyDeviceTokenRequest $request): JsonResponse
    {
        $request->user()->deviceTokens()->where('token', $request->validated('token'))->delete();

        return response()->json(['message' => 'Device token removed.']);
    }
}
