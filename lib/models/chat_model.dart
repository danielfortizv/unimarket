import 'package:unimarket/models/mensaje_model.dart';

class Chat {
  final String id;
  final String clienteId;
  final String emprendedorId;
  final List<Mensaje> mensajes;

  Chat({
    required this.id,
    required this.clienteId,
    required this.emprendedorId,
    required this.mensajes,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      clienteId: map['clienteId'],
      emprendedorId: map['emprendedorId'],
      mensajes: map['mensajes'] != null
          ? List<Mensaje>.from(
              map['mensajes'].map((m) => Mensaje.fromMap(m)))
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'emprendedorId': emprendedorId,
      'mensajes': mensajes.map((m) => m.toMap()).toList(),
    };
  }

    Chat copyWith({
      String? id,
      String? clienteId,
      String? emprendedorId,
      List<Mensaje>? mensajes,
    }) {
      return Chat(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        emprendedorId: emprendedorId ?? this.emprendedorId,
        mensajes: mensajes ?? this.mensajes,
      );
    }

}
