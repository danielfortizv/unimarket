class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final List<String> imagenes;
  final String emprendedorId;
  final double rating;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenes,
    required this.emprendedorId,
    required this.rating,
  });

  factory Producto.fromMap(Map<String, dynamic> map, String id) {
    return Producto(
      id: id,
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      imagenes: List<String>.from(map['imagenes']),
      emprendedorId: map['emprendedorId'],
      rating: map['rating']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagenes': imagenes,
      'emprendedorId': emprendedorId,
      'rating': rating,
    };
  }
}