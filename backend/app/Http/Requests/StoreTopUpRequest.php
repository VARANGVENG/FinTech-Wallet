<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTopUpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'amount' => ['required', 'decimal:0,2', 'min:0.01'],
            'currency' => ['required', 'string', 'in:USD,KHR'],
            'method' => ['required', 'string', 'in:linkedBank,debitCard,applePay'],
            'idempotency_key' => ['required', 'string', 'max:64'],
        ];
    }
}
