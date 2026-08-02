import 'package:fintech_wallet/features/topup/data/datasource/topup_remote_datasurce.dart';
import 'package:fintech_wallet/features/topup/data/repositories/topup_respositories_Imp.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/topup_repository.dart';
// import '../data/datasources/topup_remote_data_source.dart';
// import '../data/repositories/topup_repository_impl.dart';
// import '../domain/repositories/topup_repository.dart';
// import '../models/payment_method.dart';

/// The top of the stack: `Screen -> Provider -> Repository -> RemoteDataSource`.
///
/// `TopUpProvider` is a `ChangeNotifier` — it holds every piece of mutable
/// UI state for the Top-up screen (amount, selected method, loading/error
/// flags) and calls `notifyListeners()` whenever that state changes. The
/// widget tree listens via `context.watch<TopUpProvider>()` and rebuilds
/// automatically — this is what replaces the screen's own `setState` calls
/// from the previous version.
///
/// Crucially, this class only ever imports [TopUpRepository] (the abstract
/// contract), never [TopUpRepositoryImpl] or the remote data source
/// directly. That's what makes `TopUpProvider(FakeTopUpRepository())`
/// possible in a widget test with zero changes to this file.
class TopUpProvider extends ChangeNotifier {
  final TopUpRepository _repository;

  TopUpProvider(this._repository);

  static const quickAmounts = [25.0, 50.0, 100.0, 250.0];

  double amount = 100.0;
  String currency = 'USD';
  PaymentMethodType? selectedMethod = PaymentMethodType.linkedBank;

  List<PaymentMethod> methods = [];
  bool loadingMethods = true;
  bool submitting = false;
  String? errorMessage;

  /// Called once from the screen's `initState`. Kept as an explicit method
  /// — rather than firing automatically in the constructor — so the screen
  /// controls exactly when loading starts.
  Future<void> loadPaymentMethods() async {
    loadingMethods = true;
    errorMessage = null;
    notifyListeners();

    try {
      methods = await _repository.getPaymentMethods();
    } catch (e) {
      // The provider is where a thrown exception finally becomes a
      // human-readable string for the UI — neither the repository nor the
      // data source below it deal in user-facing copy.
      errorMessage = 'Could not load payment methods.';
    } finally {
      loadingMethods = false;
      notifyListeners();
    }
  }

  void selectQuickAmount(double value) {
    amount = value;
    notifyListeners();
  }

  void selectMethod(PaymentMethodType type) {
    selectedMethod = type;
    notifyListeners();
  }

  /// Returns the result so the screen can decide what to do next (show a
  /// snackbar, navigate, etc.) — the provider itself never triggers
  /// navigation or shows UI, keeping it testable without a `BuildContext`.
  Future<TopUpResult?> submit() async {
    if (selectedMethod == null) return null;

    submitting = true;
    notifyListeners();

    try {
      final result = await _repository.submitTopUp(
        amount: amount,
        currency: currency,
        method: selectedMethod!,
      );
      return result;
    } catch (e) {
      return const TopUpResult(success: false, message: 'Something went wrong.');
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}

/// Convenience factory so `main.dart` can build a fully-wired provider in
/// one line: `ChangeNotifierProvider(create: (_) => buildTopUpProvider(...))`.
TopUpProvider buildTopUpProvider({required String baseUrl}) {
  final dataSource = HttpTopUpRemoteDataSource(baseUrl: baseUrl);
  final repository = TopUpRepositoryImpl(dataSource);
  return TopUpProvider(repository);
}