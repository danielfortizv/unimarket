class CarritoDeMercado {
  final String id;
  final String clienteId;
  final String emprendedorId;
  final List<String> productoIds;

  CarritoDeMercado({
    required this.id,
    required this.clienteId,
    required this.emprendedorId,
    required this.productoIds,
  });

  factory CarritoDeMercado.fromMap(Map<String, dynamic> map, String id) {
    return CarritoDeMercado(
      id: id,
      clienteId: map['clienteId'],
      emprendedorId: map['emprendedorId'],
      productoIds: List<String>.from(map['productoIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'emprendedorId': emprendedorId,
      'productoIds': productoIds,
    };
  }
}