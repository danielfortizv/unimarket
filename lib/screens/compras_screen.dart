import 'package:flutter/material.dart';

class ComprasPlaceholderScreen extends StatelessWidget {
  const ComprasPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de Compras')),
      body: const Center(child: Text('Pantalla de Compras')),
    );
  }
}