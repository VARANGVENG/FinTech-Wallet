import 'package:fintech_wallet/core/network/api_endpoints.dart';
import 'package:fintech_wallet/features/topup/data/datasource/topup_remote_datasurce.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/topup/data/repositories/topup_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/topup_repository.dart';

/// Immutable snapshot of everything the Top-up screen needs to render.
/// Replaced wholesale via [copyWith] rather than mutated in place — this is
/// the same convention `AuthState` already uses, so there's one way to
/// represent "feature state" across the app, not two.
class TopUpState {
  final double amount;
  final String currency;
  final PaymentMethodType? selectedMethod;
  final List<PaymentMethod> methods;
  final bool loadingMethods;
  final bool submitting;
  final String? errorMessage;

  const TopUpState({
    this.amount = 100.0,
    this.currency = 'USD',
    this.selectedMethod = PaymentMethodType.linkedBank,
    this.methods = const [],
    this.loadingMethods = true,
    this.submitting = false,
    this.errorMessage,
  });

  TopUpState copyWith({
    double? amount,
    String? currency,
    PaymentMethodType? selectedMethod,
    List<PaymentMethod>? methods,
    bool? loadingMethods,
    bool? submitting,
    String? errorMessage,
  }) {
    return TopUpState(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      methods: methods ?? this.methods,
      loadingMethods: loadingMethods ?? this.loadingMethods,
      submitting: submitting ?? this.submitting,
      // Matches AuthState's copyWith: errorMessage is NOT preserved with
      // `??` like the other fields — any call that doesn't explicitly pass
      // it resets it to null. See the note below the code for why.
      errorMessage: errorMessage,
    );
  }
}

/// Same four operations `TopUpProvider` (the old `ChangeNotifier`) had —
/// only the mechanism for announcing a change is different (`state =` here,
/// `notifyListeners()` there). The domain/data layers below this class are
/// completely unchanged.
class TopUpNotifier extends StateNotifier<TopUpState> {
  final TopUpRepository _repository;

  TopUpNotifier(this._repository) : super(const TopUpState());

  static const quickAmounts = [25.0, 50.0, 100.0, 250.0];

  Future<void> loadPaymentMethods() async {
    state = state.copyWith(loadingMethods: true, errorMessage: null);

    try {
      final methods = await _repository.getPaymentMethods();
      state = state.copyWith(methods: methods, loadingMethods: false);
    } catch (e) {
      state = state.copyWith(
        loadingMethods: false,
        errorMessage: 'Could not load payment methods.',
      );
    }
  }

  void setAmount(double value) {
    state = state.copyWith(amount: value);
  }

  void selectMethod(PaymentMethodType type) {
    state = state.copyWith(selectedMethod: type);
  }

  Future<TopUpResult?> submit() async {
    if (state.selectedMethod == null) return null;

    state = state.copyWith(submitting: true);

    try {
      final result = await _repository.submitTopUp(
        amount: state.amount,
        currency: state.currency,
        method: state.selectedMethod!,
      );
      return result;
    } catch (e) {
      return const TopUpResult(
        success: false,
        message: 'Something went wrong.',
      );
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}

/// Builds the repository this feature depends on. Kept as its own provider
/// (rather than constructed inline inside `topUpProvider`) so a test could
/// override just this one piece — e.g. `topUpRepositoryProvider.overrideWithValue(FakeTopUpRepository())`
/// — without touching `TopUpNotifier` at all.
final topUpRepositoryProvider = Provider<TopUpRepository>((ref) {
  final dataSource = HttpTopUpRemoteDataSource(baseUrl: ApiEndpoints.baseUrl);
  return TopUpRepositoryImpl(dataSource);
});

final topUpProvider = StateNotifierProvider<TopUpNotifier, TopUpState>((ref) {
  final repository = ref.watch(topUpRepositoryProvider);
  return TopUpNotifier(repository);
});
