import 'package:fintech_wallet/core/biometrics/data/datasource/biometric_local_datasource.dart';
import 'package:fintech_wallet/core/biometrics/data/repositories/biometric_repository_impl.dart';
import 'package:fintech_wallet/core/biometrics/domain/entities/biometric_attempt_result.dart';
import 'package:fintech_wallet/core/biometrics/domain/entities/biometric_capability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBiometricLocalDataSource extends Mock implements BiometricLocalDataSource {}

void main() {
  late MockBiometricLocalDataSource dataSource;
  late BiometricRepositoryImpl repository;

  setUp(() {
    dataSource = MockBiometricLocalDataSource();
    repository = BiometricRepositoryImpl(dataSource);
  });

  test('checkCapability forwards the data source result', () async {
    when(() => dataSource.checkCapability())
        .thenAnswer((_) async => BiometricCapability.available);

    final result = await repository.checkCapability();

    expect(result, BiometricCapability.available);
    verify(() => dataSource.checkCapability()).called(1);
  });

  test('authenticate forwards the reason and the data source result', () async {
    when(() => dataSource.authenticate('Unlock Novapay'))
        .thenAnswer((_) async => BiometricAttemptResult.success);

    final result = await repository.authenticate('Unlock Novapay');

    expect(result, BiometricAttemptResult.success);
    verify(() => dataSource.authenticate('Unlock Novapay')).called(1);
  });
}
