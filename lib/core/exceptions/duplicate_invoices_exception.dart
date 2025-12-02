class DuplicateInvoicesException implements Exception {
  final List<String> messages;
  DuplicateInvoicesException(this.messages);

  @override
  String toString() => 'Facturas duplicadas encontradas';
}
