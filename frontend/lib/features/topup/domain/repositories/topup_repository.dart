import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';

abstract class TopUpRepository {
  Future<List<PaymentMethod>> getPaymentMethods();

  Future<Transaction> submitTopUp({
    required double amount,
    required String currency,
    required PaymentMethodType method,
    required String idempotencyKey,
  });
}
