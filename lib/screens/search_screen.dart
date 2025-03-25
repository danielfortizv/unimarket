import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/screens/emprendimiento_screen.dart';

class BuscadorScreen extends StatefulWidget {
  const BuscadorScreen({super.key});

  @override
  State<BuscadorScreen> createState() => _BuscadorScreenState();
}

class _BuscadorScreenState extends State<BuscadorScreen> {
  final TextEditingController _controller = TextEditingController();
  final EmprendimientoService _service = EmprendimientoService();
  List<Emprendimiento> resultados = [];
  List<String> recientes = [];
  bool buscando = false;

  @override
  void initState() {
    super.initState();
    cargarRecientes();
  }

  Future<void> cargarRecientes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recientes = prefs.getStringList('busquedasRecientes') ?? [];
    });
  }

  Future<void> guardarReciente(String termino) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recientes.remove(termino);
      recientes.insert(0, termino);
      if (recientes.length > 10) recientes = recientes.sublist(0, 10);
    });
    await prefs.setStringList('busquedasRecientes', recientes);
  }

  Future<void> eliminarReciente(String termino) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => recientes.remove(termino));
    await prefs.setStringList('busquedasRecientes', recientes);
  }

  Future<void> buscar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() => buscando = true);
    final resultado = await _service.buscador(texto);
    await guardarReciente(texto);
    setState(() {
      resultados = resultado;
      buscando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuscadorConClearButton(
              controller: _controller,
              onBuscar: buscar,
            ),
            const SizedBox(height: 20),
            if (resultados.isEmpty) ...[
              const Text('Recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              for (var item in recientes)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _controller.text = item;
                          buscar();
                        },
                        child: Text('     - $item', style: const TextStyle(fontFamily: 'Poppins')),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => eliminarReciente(item),
                    )
                  ],
                ),
            ] else ...[
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: resultados.length,
                  itemBuilder: (context, index) {
                    final emp = resultados[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmprendimientoScreen(emprendimiento: emp),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      emp.nombre,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            emp.rating?.toStringAsFixed(1) ?? '-',
                                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        emp.rangoPrecios ?? '',
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            if (emp.imagenes.isNotEmpty)
                              SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: PageView.builder(
                                  itemCount: emp.imagenes.length,
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      emp.imagenes[index],
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(emp.descripcion ?? '', style: const TextStyle(fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class BuscadorConClearButton extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onBuscar;

  const BuscadorConClearButton({
    super.key,
    required this.controller,
    required this.onBuscar,
  });

  @override
  State<BuscadorConClearButton> createState() => _BuscadorConClearButtonState();
}

class _BuscadorConClearButtonState extends State<BuscadorConClearButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {}); // Redibuja cuando cambia el texto
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: '¿Qué necesitas?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFE3F2FD), // Azul pastel sobrio
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => widget.onBuscar(),
            ),
          ),
        ],
      ),
    );
  }
}
