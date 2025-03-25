class Emprendimiento {
  final String id;
  final String nombre;
  final String? descripcion;
  final List<String> productoIds; // Referencia a productos
  final String? rangoPrecios;
  final double? rating;
  final Map<String, String?> preguntasFrecuentes; // Pregunta: Respuesta (nullable)
  final String emprendedorId; // Asociado
  final List<String> imagenes;
  final List<String> hashtags;
  final String? info; // Información de contacto con posibles saltos de línea

  Emprendimiento({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.productoIds,
    this.rangoPrecios,
    this.rating,
    required this.preguntasFrecuentes,
    required this.emprendedorId,
    required this.imagenes,
    required this.hashtags,
    this.info,
  });

  factory Emprendimiento.fromMap(Map<String, dynamic> map, String id) {
    return Emprendimiento(
      id: id,
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      productoIds: List<String>.from(map['productoIds']),
      rangoPrecios: map['rangoPrecios'],
      rating: map['rating']?.toDouble(),
      preguntasFrecuentes: Map<String, String?>.from(map['preguntasFrecuentes'] ?? {}),
      emprendedorId: map['emprendedorId'],
      imagenes: List<String>.from(map['imagenes']),
      hashtags: List<String>.from(map['hashtags']),
      info: map['info'],
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
      'hashtags': hashtags,
      'info': info,
    };
  }
}