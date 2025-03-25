class Producto {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final List<String> imagenes;
  final List<String> comentarioIds;
  final String emprendimientoId;
  final double? rating;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.imagenes,
    required this.emprendimientoId,
    this.rating,
    required this.comentarioIds,
  });

  factory Producto.fromMap(Map<String, dynamic> map, String id) {
    return Producto(
      id: id,
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: (map['precio'] as num).toDouble(),
      imagenes: List<String>.from(map['imagenes']),
      emprendimientoId: map['emprendimientoId'],
      rating: map['rating']?.toDouble(),
      comentarioIds: List<String>.from(map['comentarioIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagenes': imagenes,
      'emprendimientoId': emprendimientoId,
      'rating': rating,
      'comentarioIds': comentarioIds,
    };
  }
}