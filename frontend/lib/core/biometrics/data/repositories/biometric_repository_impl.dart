import '../../domain/entities/biometric_attempt_result.dart';
import '../../domain/entities/biometric_capability.dart';
import '../../domain/repositories/biometric_repository.dart';
import '../datasource/biometric_local_datasource.dart';

/// Pure delegation to [BiometricLocalDataSource] — no business logic here,
/// same thinness as e.g. `AuthRepositoryImpl`.
class BiometricRepositoryImpl implements BiometricRepository {
  BiometricRepositoryImpl(this._dataSource);

  final BiometricLocalDataSource _dataSource;

  @override
  Future<BiometricCapability> checkCapability() => _dataSource.checkCapability();

  @override
  Future<BiometricAttemptResult> authenticate(String reason) =>
      _dataSource.authenticate(reason);
}
