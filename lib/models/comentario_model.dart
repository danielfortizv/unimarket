class Comentario {
  final String id;
  final String productoId;
  final String clienteId;
  final String texto;
  final int rating;
  final String fecha;
  final int likes;

  Comentario({
    required this.id,
    required this.productoId,
    required this.clienteId,
    required this.texto,
    required this.rating,
    required this.fecha,
    required this.likes,
  });

  factory Comentario.fromMap(Map<String, dynamic> map, String id) {
    return Comentario(
      id: id,
      productoId: map['productoId'],
      clienteId: map['clienteId'],
      texto: map['texto'],
      rating: map['rating'],
      fecha: map['fecha'],
      likes: map['likes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'clienteId': clienteId,
      'texto': texto,
      'rating': rating,
      'fecha': fecha,
      'likes': likes,
    };
  }
}