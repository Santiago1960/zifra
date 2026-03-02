import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/presentation/providers/auth_provider.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';
import 'package:zifra/presentation/screens/invoice_list_screen.dart';
import 'package:zifra/presentation/widgets/custom_app_bar.dart';
import 'package:zifra/presentation/widgets/invoice_drop_zone.dart';
import 'package:zifra/presentation/widgets/sri_password_dialog.dart';
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 27, 120, 197),
        foregroundColor: Colors.white,
        tooltip: 'Descargar facturas del SRI',
        shape: const CircleBorder(),
        onPressed: authState.status != AuthStatus.authenticated ? null : () async {
          final ruc = authState.user?.ruc;
          if (ruc == null) return;

          // 1. Verificar que el usuario tiene un proyecto activo
          if (!authState.hasOpenProjects || authState.projects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Crea un proyecto primero para asociar las facturas.')),
            );
            return;
          }

          // 2. Pedir contraseña y períodos
          final result = await SriPasswordDialog.show(context);
          if (result == null || !context.mounted) return;

          // 3. Seleccionar proyecto destino (si hay más de uno, tomar el más reciente)
          final targetProject = authState.projects.first;
          if (targetProject.id == null) return;

          // 4. Mostrar loading mientras el bot trabaja
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              content: SizedBox(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Descargando facturas del SRI...', textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text('Esto puede tardar varios minutos.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );

          try {
            final downloadResult = await ref.read(sriRemoteDataSourceProvider).downloadAndSave(
              ruc: ruc,
              password: result.password,
              projectId: targetProject.id!,
              periods: result.periods,
            );

            if (!context.mounted) return;
            Navigator.pop(context); // cerrar loading

            // 5. Mostrar resumen por período
            final months = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Descarga Completada'),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...downloadResult.periods.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${months[p.month]} ${p.year}:', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text('✓ ${p.descargadas}'),
                            if (p.duplicadas > 0) Text('  dup: ${p.duplicadas}', style: const TextStyle(color: Colors.orange)),
                            if (p.errores > 0) Text('  err: ${p.errores}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Color(0xFF1B78C5), size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text('${downloadResult.totalDescargadas} facturas certificadas guardadas en "${targetProject.nombre}"')),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                  if (downloadResult.totalDescargadas > 0)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Ver facturas'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (!context.mounted) return;
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                        try {
                          final invoices = await ref.read(projectRemoteDataSourceProvider).getProjectInvoices(targetProject.id!);
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => InvoiceListScreen(invoices: invoices, projectId: targetProject.id),
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) { Navigator.pop(context); }
                        }
                      },
                    ),
                ],
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
