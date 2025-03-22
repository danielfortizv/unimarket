class Emprendimiento {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> productoIds; // Referencia a productos
  final String rangoPrecios;
  final double rating;
  final List<String> preguntasFrecuentes;
  final String emprendedorId; // Asociado
  final List<String> imagenes;

  Emprendimiento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.productoIds,
    required this.rangoPrecios,
    required this.rating,
    required this.preguntasFrecuentes,
    required this.emprendedorId,
    required this.imagenes,
  });

  factory Emprendimiento.fromMap(Map<String, dynamic> map, String id) {
    return Emprendimiento(
      id: id,
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      productoIds: List<String>.from(map['productoIds']),
      rangoPrecios: map['rangoPrecios'],
      rating: map['rating']?.toDouble() ?? 0.0,
      preguntasFrecuentes: List<String>.from(map['preguntasFrecuentes']),
      emprendedorId: map['emprendedorId'],
      imagenes: List<String>.from(map['imagenes']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'productoIds': productoIds,
      'rangoPrecios': rangoPrecios,
      'rating': rating,
      'preguntasFrecuentes': preguntasFrecuentes,
      'emprendedorId': emprendedorId,
      'imagenes': imagenes,
    };
  }
}
