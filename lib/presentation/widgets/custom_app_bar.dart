import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/presentation/providers/auth_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/icon.png',
            height: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'Zifra - Análisis de Facturas SRI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            ref.read(authProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout, color: Colors.red,),
          tooltip: 'Cerrar Sesión',
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
