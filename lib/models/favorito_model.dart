class Favorito {
  final String id;
  final String clienteId;
  final String emprendedorId;

  Favorito({
    required this.id,
    required this.clienteId,
    required this.emprendedorId,
  });

  factory Favorito.fromMap(Map<String, dynamic> map, String id) {
    return Favorito(
      id: id,
      clienteId: map['clienteId'],
      emprendedorId: map['emprendedorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'emprendedorId': emprendedorId,
    };
  }
}