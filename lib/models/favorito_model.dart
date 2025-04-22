class Favorito {
  String id;
  final String clienteId;
  final String emprendimientoId;

  Favorito({
    required this.id,
    required this.clienteId,
    required this.emprendimientoId,
  });

  factory Favorito.fromMap(Map<String, dynamic> map, String id) {
    return Favorito(
      id: id,
      clienteId: map['clienteId'],
      emprendimientoId: map['emprendimientoId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'emprendimientoId': emprendimientoId,
    };
  }
}