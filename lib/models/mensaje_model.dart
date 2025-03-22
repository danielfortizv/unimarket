class Mensaje {
  final String contenido;
  final String emisorId;
  final String hora;
  final String tipo;

  Mensaje({
    required this.contenido,
    required this.emisorId,
    required this.hora,
    required this.tipo,
  });

  factory Mensaje.fromMap(Map<String, dynamic> map) {
    return Mensaje(
      contenido: map['contenido'],
      emisorId: map['emisorId'],
      hora: map['hora'],
      tipo: map['tipo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contenido': contenido,
      'emisorId': emisorId,
      'hora': hora,
      'tipo': tipo,
    };
  }
}