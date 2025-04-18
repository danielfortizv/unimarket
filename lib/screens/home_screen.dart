import 'package:flutter/material.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/widgets/emprendimiento_card.dart';

class HomeScreen extends StatelessWidget {
  final EmprendimientoService _emprendimientoService = EmprendimientoService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Emprendimiento>>(

        stream: _emprendimientoService.obtenerTodos(),
        
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay emprendimientos aún."));
          }

          final emprendimientos = snapshot.data!;

          return ListView.builder(
            itemCount: emprendimientos.length,
            itemBuilder: (context, index) {
              final emprendimiento = emprendimientos[index];
              return EmprendimientoCard(emprendimiento: emprendimiento, onMostrarComentarios: mostrarComentarios,);
            },
          );
        },
      ),
    );
  }

  void mostrarComentarios(BuildContext context, Emprendimiento emprendimiento) {
    // Por ahora los comentarios están embebidos en productos, esto es solo placeholder
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Comentarios",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                const Expanded(
                  child: Center(
                    child: Text('Aquí irían los comentarios del emprendimiento'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
