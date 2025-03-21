import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UNIMARKET',
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shopping_cart_outlined, size: 28),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('emprendimientos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay emprendimientos aún."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final List<dynamic> imagenes = data['imagenes'] ?? [];

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila: Nombre + Rating/Precio
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data['nombre'] ?? '',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
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
                                    (data['rating'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                data['rango_precios'] ?? '',
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

                    // Carrusel de imágenes debajo del título
                    if (imagenes.isNotEmpty)
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: imagenes.length,
                          itemBuilder: (context, index) {
                            final imagenUrl = imagenes[index];
                            return Image.network(
                              imagenUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 220,
                            );
                          },
                        ),
                      ),

                    // Descripción alineada a la izquierda
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
                      child: Text(
                        data['descripcion'] ?? '',
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),

                    // Hashtags + Iconos (alineados)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              (data['hashtags'] as List<dynamic>?)?.join(" ") ?? '',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chat_bubble_outline, size: 21),
                          const SizedBox(width: 12),
                          const Icon(Icons.bookmark_border, size: 23),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed, // <-- espaciado uniforme
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
