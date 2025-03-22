class Notificacion {
  final String id;
  final String receptorId; // ID del cliente, emprendedor o domiciliario
  final String titulo;
  final String mensaje;
  final String tipo; // ejemplo: 'pedido', 'chat', 'promocion'
  final String fecha; // formato legible o timestamp
  final bool leida;

  Notificacion({
    required this.id,
    required this.receptorId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    this.leida = false,
  });

  factory Notificacion.fromMap(Map<String, dynamic> map, String id) {
    return Notificacion(
      id: id,
      receptorId: map['receptorId'],
      titulo: map['titulo'],
      mensaje: map['mensaje'],
      tipo: map['tipo'],
      fecha: map['fecha'],
      leida: map['leida'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receptorId': receptorId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fecha': fecha,
      'leida': leida,
    };
  }
}
