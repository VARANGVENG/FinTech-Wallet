import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import '../datasource/topup_remote_datasource.dart';
import '../model/payment_method.dart';
import '../../domain/repositories/topup_repository.dart';

class TopUpRepositoryImpl implements TopUpRepository {
  final TopUpRemoteDataSource remoteDataSource;

  TopUpRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    return remoteDataSource.getPaymentMethods();
  }

  @override
  Future<Transaction> submitTopUp({
    required double amount,
    required String currency,
    required PaymentMethodType method,
    required String idempotencyKey,
  }) async {
    return remoteDataSource.submitTopUp(
      amount: amount,
      currency: currency,
      method: method,
      idempotencyKey: idempotencyKey,
    );
  }
}