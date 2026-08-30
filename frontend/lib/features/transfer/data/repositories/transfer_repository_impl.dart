import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import '../datasource/transfer_remote_datasource.dart';
import '../model/recipient.dart';
import '../../domain/repositories/transfer_repository.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource _remote;

  TransferRepositoryImpl(this._remote);

  @override
  Future<Recipient> findRecipient(String email) {
    return _remote.findRecipient(email);
  }

  @override
  Future<Transaction> submitTransfer({
    required String recipientEmail,
    required double amount,
    required String currency,
    required String idempotencyKey,
    String? note,
  }) {
    return _remote.submitTransfer(
      recipientEmail: recipientEmail,
      amount: amount,
      currency: currency,
      idempotencyKey: idempotencyKey,
      note: note,
    );
  }
}