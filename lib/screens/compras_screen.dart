import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/carrito_mercado_model.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/carrito_mercado_service.dart';
import 'package:unimarket/services/producto_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final CarritoService _carritoService = CarritoService();
  final ProductoService _productoService = ProductoService();
  final EmprendimientoService _emprendimientoService = EmprendimientoService();
  final NumberFormat _formatoPesos = NumberFormat.currency(
    locale: 'es_CO', 
    symbol: '\$', 
    decimalDigits: 0, 
    customPattern: '\u00A4#,##0'
  );

  bool _isLoading = false;
  Map<String, int> _cantidades = {}; // productoId -> cantidad
  Map<String, double> _precios = {}; // productoId -> precio
  
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tu carrito',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<CarritoDeMercado>>(
        stream: _carritoService.obtenerCarritosPorCliente(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyCart();
          }

          final carritos = snapshot.data!;
          
          // Verificar si hay productos en los carritos
          bool hasProducts = carritos.any((carrito) => carrito.productoIds.isNotEmpty);
          
          if (!hasProducts) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: carritos.length,
                  itemBuilder: (context, index) {
                    final carrito = carritos[index];
                    if (carrito.productoIds.isEmpty) {
                      return const SizedBox();
                    }
                    return _buildCarritoSection(carrito);
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos para comenzar',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Explorar productos',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoSection(CarritoDeMercado carrito) {
    return FutureBuilder<Emprendimiento?>(
      future: _emprendimientoService.obtenerPorId(carrito.emprendedorId),
      builder: (context, empSnapshot) {
        if (!empSnapshot.hasData) {
          return const SizedBox();
        }

        final emprendimiento = empSnapshot.data!;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmprendimientoHeader(emprendimiento),
              _buildProductList(carrito.productoIds),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmprendimientoHeader(Emprendimiento emprendimiento) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: emprendimiento.imagenes.isNotEmpty
                ? NetworkImage(emprendimiento.imagenes.first)
                : null,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              emprendimiento.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<String> productoIds) {
    // Agrupar productos por ID para contar duplicados
    final productGroups = <String, int>{};
    for (final id in productoIds) {
      productGroups[id] = (productGroups[id] ?? 0) + 1;
    }
    
    final uniqueProductIds = productGroups.keys.toList();
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: uniqueProductIds.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final productoId = uniqueProductIds[index];
        final cantidadEnCarrito = productGroups[productoId] ?? 1;
        return _buildProductItem(productoId, cantidadEnCarrito);
      },
    );
  }

  Widget _buildProductItem(String productoId, int cantidadInicial) {
    return FutureBuilder<Producto?>(
      future: _productoService.obtenerProductoPorId(productoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            title: Text('Cargando...'),
            trailing: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final producto = snapshot.data!;
        // Usar la cantidad del carrito o la cantidad manejada localmente
        final cantidad = _cantidades[productoId] ?? cantidadInicial;
        
        // Almacenar el precio para el cálculo del total solo si no existe
        if (!_precios.containsKey(productoId)) {
          _precios[productoId] = producto.precio;
        }
        
        // Solo inicializar la cantidad si no existe
        if (!_cantidades.containsKey(productoId)) {
          // Usar Future.microtask para evitar setState durante build
          Future.microtask(() {
            setState(() {
              _cantidades[productoId] = cantidadInicial;
            });
          });
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  producto.imagenes.isNotEmpty 
                      ? producto.imagenes.first 
                      : 'https://via.placeholder.com/60',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatoPesos.format(producto.precio),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuantityControls(productoId, cantidad),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuantityControls(String productoId, int cantidad) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: () => _updateQuantity(productoId, cantidad - 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              cantidad.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: () => _updateQuantity(productoId, cantidad + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    // Solo verificar si hay productos válidos en las cantidades
    bool hasValidProducts = _cantidades.values.any((cantidad) => cantidad > 0);
    
    if (!hasValidProducts) {
      return const SizedBox(); // No mostrar la sección inferior si no hay productos
    }
    
    // Calcular total basado en los datos actuales
    double total = 0;
    _cantidades.forEach((productoId, cantidad) {
      if (_precios.containsKey(productoId) && cantidad > 0) {
        total += _precios[productoId]! * cantidad;
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    _formatoPesos.format(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Proceder al pago',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateQuantity(String productoId, int nuevaCantidad) async {
    if (nuevaCantidad < 1) {
      // Remover del carrito completamente
      await _removeAllProductFromCart(productoId);
    } else {
      final cantidadActual = _cantidades[productoId] ?? 1;
      final diferencia = nuevaCantidad - cantidadActual;
      
      setState(() {
        _cantidades[productoId] = nuevaCantidad;
      });
      
      if (diferencia > 0) {
        // Agregar productos
        await _addProductsToCart(productoId, diferencia);
      } else if (diferencia < 0) {
        // Remover productos
        await _removeProductsFromCart(productoId, -diferencia);
      }
    }
  }
  
  Future<void> _addProductsToCart(String productoId, int cantidad) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final carritos = await _carritoService.obtenerCarritosPorCliente(userId).first;
    
    // Encontrar el carrito que contiene este producto
    for (final carrito in carritos) {
      if (carrito.productoIds.contains(productoId)) {
        for (int i = 0; i < cantidad; i++) {
          await _carritoService.agregarProductoAlCarrito(carrito.id, productoId);
        }
        break;
      }
    }
  }
  
  Future<void> _removeProductsFromCart(String productoId, int cantidad) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final carritos = await _carritoService.obtenerCarritosPorCliente(userId).first;
    
    // Encontrar el carrito que contiene este producto
    for (final carrito in carritos) {
      if (carrito.productoIds.contains(productoId)) {
        for (int i = 0; i < cantidad; i++) {
          await _carritoService.eliminarProductoDelCarritoDeMercado(carrito.id, productoId);
        }
        break;
      }
    }
  }
  
  Future<void> _removeAllProductFromCart(String productoId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final carritos = await _carritoService.obtenerCarritosPorCliente(userId).first;
    
    // Remover todas las instancias del producto
    for (final carrito in carritos) {
      while (carrito.productoIds.contains(productoId)) {
        await _carritoService.eliminarProductoDelCarritoDeMercado(carrito.id, productoId);
      }
    }
    
    setState(() {
      _cantidades.remove(productoId);
      _precios.remove(productoId);
    });
  }

  Future<void> _proceedToCheckout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular proceso de checkout
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido realizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar carritos después del checkout
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final carritos = await _carritoService.obtenerCarritosPorCliente(userId).first;
        for (final carrito in carritos) {
          await _carritoService.eliminarCarrito(carrito.id);
        }
        
        // Limpiar el estado local
        setState(() {
          _cantidades.clear();
          _precios.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}