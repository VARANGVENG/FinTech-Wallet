import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transfer/data/datasource/transfer_remote_datasource.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/transfer_repository.dart';

class TransferState {
  final Recipient? recipient;
  final double amount;
  final String currency;
  final String? note;
  final bool submitting;
  final String? errorMessage;
  final String idempotencyKey;

  const TransferState({
    this.recipient,
    this.amount = 0.0,
    this.currency = 'USD',
    this.note,
    this.submitting = false,
    this.errorMessage,
    required this.idempotencyKey,
  });

  TransferState copyWith({
    Recipient? recipient,
    double? amount,
    String? currency,
    String? note,
    bool? submitting,
    String? errorMessage,
    String? idempotencyKey,
  }) {
    return TransferState(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferRepository _repository;
  final Uuid _uuid;

  TransferNotifier(this._repository, this._uuid)
    : super(TransferState(idempotencyKey: _uuid.v4()));

  void setRecipient(Recipient recipient) {
    state = state.copyWith(recipient: recipient, idempotencyKey: _uuid.v4());
  }

  void setAmount(double value) {
    state = state.copyWith(amount: value, idempotencyKey: _uuid.v4());
  }

  void setCurrency(String currency) {
    if (currency == state.currency) return;

    state = state.copyWith(
      currency: currency,
      amount: 0.0,
      idempotencyKey: _uuid.v4(),
    );
  }

  void setNote(String value) {
    state = state.copyWith(note: value, idempotencyKey: _uuid.v4());
  }

  Future<Transaction?> submit() async {
    final recipient = state.recipient;
    if (recipient == null || state.amount <= 0) return null;

    state = state.copyWith(submitting: false, errorMessage: null);

    try {
      final transaction = await _repository.submitTransfer(
        recipientEmail: recipient.email,
        amount: state.amount,
        currency: state.currency,
        idempotencyKey: state.idempotencyKey,
        note: state.note,
      );
      state = state.copyWith(submitting: false);
      return transaction;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransferRepositoryImpl(TransferRemoteDataSource(apiClient));
});

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>(
  (ref) {
    final repository = ref.watch(transferRepositoryProvider);
    return TransferNotifier(repository, Uuid());
  },
);
