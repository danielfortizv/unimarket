import 'package:flutter/material.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/models/comentario_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductoDetailScreen extends StatefulWidget {
  final Producto producto;

  const ProductoDetailScreen({super.key, required this.producto});

  @override
  State<ProductoDetailScreen> createState() => _ProductoDetailScreenState();
}

class _ProductoDetailScreenState extends State<ProductoDetailScreen> {
  int cantidad = 1;

  String formatCurrency(num value) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final total = producto.precio * cantidad;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          'UNIMARKET',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nombre y rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  producto.nombre,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final rating = producto.rating ?? 0;
                  return Icon(
                    index < rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Carrusel de imágenes
          SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: producto.imagenes.length,
              itemBuilder: (context, index) {
                return Hero(
                  tag: producto.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      producto.imagenes[index], // 👈 Importante: index, no .first
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),


          const SizedBox(height: 20),
          Text(
            formatCurrency(producto.precio),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Text(producto.descripcion ?? '', style: const TextStyle(fontSize: 16, fontFamily: 'Poppins')),

          const SizedBox(height: 24),
          const Text('Comentarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('comentarios')
                .where('productoId', isEqualTo: producto.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final comentarios = snapshot.data!.docs
                  .map((doc) => Comentario.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .toList();

              if (comentarios.isEmpty) {
                return const Text("Este producto aún no tiene comentarios.");
              }

              return Column(
                children: comentarios.map((comentario) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comentario.texto, style: const TextStyle(fontFamily: 'Poppins')),
                              Text(
                                '★ ${comentario.rating.toString()}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
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
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (cantidad > 1) {
                            setState(() {
                              cantidad--;
                            });
                          }
                        },
                      ),
                      Text(
                        cantidad.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            cantidad++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(

                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  // Acción para agregar al carrito
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Add", style: TextStyle(fontSize: 16)),
                    Text(
                      formatCurrency(total),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
