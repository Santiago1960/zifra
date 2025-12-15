import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/presentation/providers/auth_provider.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';
import 'package:zifra/presentation/screens/invoice_list_screen.dart';
import 'package:zifra/presentation/widgets/custom_app_bar.dart';
import 'package:zifra/presentation/widgets/invoice_drop_zone.dart';
import 'package:zifra/presentation/widgets/user_registration_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: authState.status == AuthStatus.authenticated 
        ? const CustomAppBar() 
        : null,
      body: Center(
        child: Builder(
          builder: (context) {
            switch (authState.status) {
              case AuthStatus.initial:
              case AuthStatus.checking:
                return const CircularProgressIndicator();
              case AuthStatus.unauthenticated:
                // Show dialog or registration screen
                // Since we want to block usage until registered, we can show the dialog here
                // or a full screen form. The requirement said "abrimos un modal".
                // We can show a background and the dialog on top.
                return const Stack(
                  children: [
                    // Background or placeholder
                    Center(child: Text('Esperando registro...')),
                    // Modal
                    Opacity(
                      opacity: 1, 
                      child: UserRegistrationDialog(),
                    ),
                  ],
                );
              case AuthStatus.authenticated:
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: 800.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Bienvenido, ${authState.user?.name}'),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () {
                                ref.read(authProvider.notifier).logout();
                              },
                              icon: const Icon(Icons.logout, color: Colors.red,),
                              tooltip: 'Cerrar Sesión',
                            ),
                          ],
                        ),
                        authState.user?.ruc.length == 13 
                          ? Text('RUC: ${authState.user?.ruc}') 
                          : Text('Cédula: ${authState.user?.ruc}'),
                        const SizedBox(height: 20),
                        if (authState.hasOpenProjects)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: authState.projects.length,
                            itemBuilder: (context, index) {
                              final project = authState.projects[index];
                              return Card(
                                elevation: 4,
                                child: InkWell(
                                  onTap: () async {
                                    if (project.id == null) return;

                                    // Show loading
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator()),
                                    );

                                    try {
                                      final invoices = await ref.read(projectRemoteDataSourceProvider).getProjectInvoices(project.id!);
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context); // Hide loading
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => InvoiceListScreen(
                                              invoices: invoices,
                                              projectId: project.id,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Hide loading
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al cargar facturas: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          project.nombre,
                                          style: Theme.of(context).textTheme.titleLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Cliente: ${project.cliente}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RUC: ${project.rucBeneficiario ?? "N/A"}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          const Text('No se encontraron proyectos abiertos.', style: TextStyle(color: Colors.orange)),
                        const SizedBox(height: 30),
                        const InvoiceDropZone(),
                      ],
                    ),
                  ),
                );
              case AuthStatus.error:
                return const Text('Ocurrió un error. Reinicia la app.');
            }
          },
        ),
      ),
    );
  }
}
