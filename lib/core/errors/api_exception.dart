/// One exception type for every network failure, thrown by [ApiClient].
///
/// Without this, each feature's `RemoteDataSource` (e.g.
/// `TopUpRemoteDataSource`) would need to know about Dio's `DioException`
/// directly, which leaks an HTTP-client-specific type into every feature.
/// With this, a `RepositoryImpl` only ever needs `catch (e) when (e is
/// ApiException)` — swapping Dio for another client later means editing
/// `ApiClient` only, not every feature's data layer.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  /// True for network-level failures (no connection, timeout) as opposed
  /// to the server responding with an error status — useful for showing
  /// "Check your connection" vs. "Something went wrong" in the UI.
  bool get isConnectivityIssue => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}