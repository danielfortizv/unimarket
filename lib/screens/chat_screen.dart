import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unimarket/models/chat_model.dart';
import 'package:unimarket/models/mensaje_model.dart';
import 'package:unimarket/services/mensaje_service.dart';
import 'package:unimarket/screens/emprendimiento_screen.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/widgets/avatar.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String currentUserId; // cliente o emprendedor actual
  final String nombreEmprendimiento;
  final String fotoEmprendimiento;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.nombreEmprendimiento,
    required this.fotoEmprendimiento,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final MensajeService _mensajeService = MensajeService();
  String? _fotoOtroParticipante;
  String? _nombreOtroParticipante;
  bool _esEmprendedor = false;

  @override
  void initState() {
    super.initState();
    _verificarTipoUsuarioYObtenerInfo();
    _marcarComoLeidos();
  }

  Future<void> _verificarTipoUsuarioYObtenerInfo() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    // Verificar si es emprendedor
    final emprendedorDoc = await FirebaseFirestore.instance
        .collection('emprendedores')
        .doc(userId)
        .get();
    
    _esEmprendedor = emprendedorDoc.exists;
    
    if (_esEmprendedor) {
      // Si soy emprendedor, obtener info del cliente
      final clienteDoc = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.chat.clienteId)
          .get();
      
      if (clienteDoc.exists) {
        final clienteData = clienteDoc.data()!;
        _nombreOtroParticipante = clienteData['nombre'];
        _fotoOtroParticipante = clienteData['fotoPerfil'];
      }
    } else {
      // Si soy cliente, mostrar nombre e imagen del EMPRENDIMIENTO
      final emprendimientoDoc = await FirebaseFirestore.instance
          .collection('emprendimientos')
          .doc(widget.chat.emprendimientoId)
          .get();
      
      if (emprendimientoDoc.exists) {
        final empData = emprendimientoDoc.data()!;
        
        // CORREGIDO: Usar nombre e imagen del emprendimiento, no del emprendedor
        _nombreOtroParticipante = empData['nombre']; // Nombre del emprendimiento
        _fotoOtroParticipante = empData['imagenes'] != null && 
                               (empData['imagenes'] as List).isNotEmpty
                               ? empData['imagenes'][0] 
                               : null; // Primera imagen del emprendimiento
      }
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _marcarComoLeidos() async {
    await _mensajeService.marcarMensajesComoLeidos(widget.chat.id, widget.currentUserId);
  }

  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    final ahora = DateTime.now();
    final mensaje = Mensaje(
      tipo: "texto",
      emisorId: widget.currentUserId,
      contenido: texto,
      hora: ahora.toIso8601String(),
      leidoPor: [widget.currentUserId], // El emisor ya ha "leído" su propio mensaje
    );

    await _mensajeService.crearMensaje(mensaje, widget.chat.id);
    _mensajeController.clear();
  }

  String _formatearCabecera(DateTime fechaMsg) {
    final hoy  = DateTime.now();
    final hoySolo  = DateTime(hoy.year, hoy.month, hoy.day);
    final ayerSolo = hoySolo.subtract(const Duration(days: 1));
    final fechaSolo= DateTime(fechaMsg.year, fechaMsg.month, fechaMsg.day);

    if (fechaSolo == hoySolo)       return 'Hoy';
    if (fechaSolo == ayerSolo)      return 'Ayer';
    return DateFormat("d 'de' MMMM", 'es').format(fechaMsg); // 16 de abril
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () async {
            final service = EmprendimientoService();
            final emp = await service.obtenerPorId(widget.chat.emprendimientoId);
            if (emp != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmprendimientoScreen(emprendimiento: emp),
                ),
              );
            }
          },
          child: Row(
            children: [
              const SizedBox(width: 4),
              AvatarConDefault(
                imageUrl: _fotoOtroParticipante,
                radius: 20,
                placeholderName: _nombreOtroParticipante ?? widget.nombreEmprendimiento,
              ),
              const SizedBox(width: 12),
              Text(
                _nombreOtroParticipante ?? widget.nombreEmprendimiento,
                style: const TextStyle(fontSize: 20, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Mensaje>>(
              stream: _mensajeService.obtenerMensajesDeChat(widget.chat.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensajes = snapshot.data!;
                final agrupadoPorFecha = <String, List<Mensaje>>{};

                for (var mensaje in mensajes) {
                  final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(mensaje.hora));
                  agrupadoPorFecha.putIfAbsent(fecha, () => []).add(mensaje);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: agrupadoPorFecha.length,
                  itemBuilder: (context, index) {
                    final mensajesDelDia = agrupadoPorFecha.values.elementAt(index);
                    final cabecera = _formatearCabecera(
                      DateTime.parse(mensajesDelDia.first.hora).toLocal(),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cabecera,
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ),
                        ),
                        ...mensajesDelDia.map((mensaje) {
                          final esMio = mensaje.emisorId == widget.currentUserId;
                          final hora = DateFormat('hh:mm a').format(DateTime.parse(mensaje.hora));
                          return Align(
                            alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: const BoxConstraints(maxWidth: 300),
                              decoration: BoxDecoration(
                                color: esMio ? const Color(0xFFB2EBF2) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    mensaje.contenido,
                                    style: const TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        hora,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                      if (esMio) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          mensaje.leidoPor.length > 1
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 16,
                                          color: mensaje.leidoPor.length > 1
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribe...',
                      filled: true,
                      fillColor: const Color(0xFFE3F2FD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.black87),
                  onPressed: _enviarMensaje,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}