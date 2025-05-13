class Mensaje {
  final String contenido;
  final String emisorId;
  final String hora;
  final String tipo;
  final List<String> leidoPor; // Nuevo campo para rastrear quién ha leído el mensaje

  Mensaje({
    required this.contenido,
    required this.emisorId,
    required this.hora,
    required this.tipo,
    this.leidoPor = const [],
  });

  factory Mensaje.fromMap(Map<String, dynamic> map) {
    return Mensaje(
      contenido: map['contenido'],
      emisorId: map['emisorId'],
      hora: map['hora'],
      tipo: map['tipo'],
      leidoPor: List<String>.from(map['leidoPor'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contenido': contenido,
      'emisorId': emisorId,
      'hora': hora,
      'tipo': tipo,
      'leidoPor': leidoPor,
    };
  }
}