import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/models/comentario_model.dart';
import 'package:unimarket/models/carrito_mercado_model.dart';
import 'package:unimarket/screens/compras_screen.dart';
import 'package:unimarket/services/carrito_mercado_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
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
  int _currentImage = 0;
  bool _showImageCounter = true;
  late PageController _pageController;
  bool _addingToCart = false;
  
  final CarritoService _carritoService = CarritoService();
  final EmprendimientoService _emprendimientoService = EmprendimientoService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentImage = index;
      _showImageCounter = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showImageCounter = false);
    });
  }

  String formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO', 
      symbol: '\$', 
      decimalDigits: 0, 
      customPattern: '\u00A4#,##0'
    );
    return formatter.format(value);
  }

  Future<void> _addToCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      // Obtener información del emprendimiento
      final emprendimiento = await _emprendimientoService.obtenerPorId(widget.producto.emprendimientoId);
      if (emprendimiento == null) {
        throw Exception('Emprendimiento no encontrado');
      }

      // Buscar si ya existe un carrito para este emprendimiento (no emprendedor)
      final carritosExistentes = await _carritoService.obtenerCarritosPorCliente(userId).first;
      CarritoDeMercado? carritoExistente;
      
      for (final carrito in carritosExistentes) {
        if (carrito.emprendedorId == widget.producto.emprendimientoId) { // Aquí estaba el error
          carritoExistente = carrito;
          break;
        }
      }

      if (carritoExistente != null) {
        // Agregar al carrito existente (con múltiples productos si cantidad > 1)
        for (int i = 0; i < cantidad; i++) {
          await _carritoService.agregarProductoAlCarrito(carritoExistente.id, widget.producto.id);
        }
      } else {
        // Crear nuevo carrito - Obtener un ID generado automáticamente
        final docRef = FirebaseFirestore.instance.collection('carritos').doc();
        final nuevoCarrito = CarritoDeMercado(
          id: docRef.id, // Usar el ID generado automáticamente
          clienteId: userId,
          emprendedorId: widget.producto.emprendimientoId, // Usar emprendimientoId aquí
          productoIds: List.generate(cantidad, (index) => widget.producto.id),
        );
        await _carritoService.crearCarrito(nuevoCarrito);
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$cantidad ${cantidad > 1 ? 'productos agregados' : 'producto agregado'} al carrito'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver carrito',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarritoScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar al carrito: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CarritoScreen()),
              );
            },
          ),
        ],
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

          // Carrusel con indicadores y contador
          if (producto.imagenes.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: producto.imagenes.length,
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: producto.id,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            producto.imagenes[index],
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(producto.imagenes.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImage == index ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentImage == index ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ),
                if (producto.imagenes.length > 1 && _showImageCounter)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedOpacity(
                      opacity: _showImageCounter ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImage + 1}/${producto.imagenes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _addingToCart ? null : _addToCart,
                child: _addingToCart
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Agregar al carrito",
                            style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                          ),
                          Text(
                            formatCurrency(total),
                            style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
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