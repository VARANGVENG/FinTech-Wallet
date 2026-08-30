<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'recipient_email' => ['required', 'email'],
            'amount' => ['required', 'decimal:0,2', 'min:0.01'],
            'currency' => ['required', 'string', 'in:USD,KHR'],
            'idempotency_key' => ['required', 'string', 'max:64'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }
}
