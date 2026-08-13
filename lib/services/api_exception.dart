/// A user-friendly error surfaced from an API call.
class ApiException implements Exception {
  final String message;
  final bool estoqueInsuficiente;

  const ApiException(this.message, {this.estoqueInsuficiente = false});

  @override
  String toString() => message;
}
