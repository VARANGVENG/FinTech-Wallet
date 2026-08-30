import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import '../../data/model/recipient.dart';

abstract class TransferRepository {
  Future<Recipient> findRecipient(String email);

  Future<Transaction> submitTransfer({
    required String recipientEmail,
    required double amount,
    required String currency,
    required String idempotencyKey,
    String? note,
  });
}