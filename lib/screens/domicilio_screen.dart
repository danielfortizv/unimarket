import 'package:flutter/material.dart';

class DomicilioPlaceholderScreen extends StatelessWidget {
  const DomicilioPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Domicilio')),
      body: const Center(child: Text('Pantalla de Domicilio')),
    );
  }
}