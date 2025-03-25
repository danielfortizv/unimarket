import 'package:flutter/material.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/screens/emprendimiento_screen.dart';
import 'package:unimarket/services/emprendimiento_service.dart';

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

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmprendimientoScreen(emprendimiento: emprendimiento),
                                  ),
                                );
                              },
                              child: Text(
                                emprendimiento.nombre,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    emprendimiento.rating?.toStringAsFixed(1) ?? '-',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                emprendimiento.rangoPrecios ?? '-',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (emprendimiento.imagenes.isNotEmpty)
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: emprendimiento.imagenes.length,
                          itemBuilder: (context, index) {
                            final imagenUrl = emprendimiento.imagenes[index];
                            return Image.network(
                              imagenUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 220,
                            );
                          },
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
                      child: Text(
                        emprendimiento.descripcion ?? '',
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              (emprendimiento.hashtags).join(" "),
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, size: 24),
                            onPressed: () => mostrarComentarios(context, emprendimiento),
                          ),
                          const SizedBox(width: 0),
                          const Icon(Icons.bookmark_border, size: 27),
                        ],
                      ),
                    ),
                  ],
                ),
              );
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
