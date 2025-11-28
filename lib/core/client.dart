import 'package:zifra/domain/entities/invoice.dart';

/// Mock Client to simulate Serverpod generated client
class Client {
  final InvoicesEndpoint invoices;

  Client({required this.invoices});
}

class InvoicesEndpoint {
  Future<List<Invoice>> getOpenProjectInvoices(String ruc) async {
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    print('Checking open projects for RUC: $ruc');
    
    // Return empty list to simulate no open projects found, or populate for testing
    // For the purpose of "checking if user has open projects", 
    // we might just check if the list is not empty.
    return []; 
  }
}

// Singleton instance or Provider can be used. 
// For now, we'll just expose a global instance for simplicity in the DataSource, 
// or better, inject it via Riverpod.
