import 'package:flutter/material.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/screens/emprendimiento_screen.dart';

class EmprendimientoCard extends StatefulWidget {
  final Emprendimiento emprendimiento;
  final void Function(BuildContext context, Emprendimiento emp) onMostrarComentarios;

  const EmprendimientoCard({
    super.key,
    required this.emprendimiento,
    required this.onMostrarComentarios,
  });

  @override
  State<EmprendimientoCard> createState() => _EmprendimientoCardState();
}

class _EmprendimientoCardState extends State<EmprendimientoCard> {
  int currentImage = 0;
  bool showImageCounter = true;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentImage = index;
      showImageCounter = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => showImageCounter = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.emprendimiento;

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmprendimientoScreen(emprendimiento: emp)),
                      );
                    },
                    child: Text(
                      emp.nombre,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
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
                          style: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                    Text(
                      _formatearRango(emp.rangoPrecios),
                      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Carrusel de imágenes con indicadores
          if (emp.imagenes.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: emp.imagenes.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        emp.imagenes[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 220,
                      );
                    },
                  ),
                ),
                // Paginador en la parte inferior como punticos
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(emp.imagenes.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: currentImage == index ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: currentImage == index ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ),
                // Contador arriba a la derecha (1/5)
                if (widget.emprendimiento.imagenes.length > 1 && showImageCounter)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedOpacity(
                      opacity: showImageCounter ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.6 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentImage + 1}/${widget.emprendimiento.imagenes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Descripción
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 4),
            child: Text(emp.descripcion ?? '', style: const TextStyle(fontFamily: 'Poppins')),
          ),

          // Hashtags + botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    (emp.hashtags).join(" "),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 24),
                  onPressed: () => widget.onMostrarComentarios(context, emp)
                ),
                const Icon(Icons.bookmark_border, size: 27),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearRango(String? rango) {
    if (rango == null || rango == '-') return '-';

    final partes = rango.replaceAll('\$', '').split('-');
    if (partes.length != 2) return '\$$rango';

    final int? min = int.tryParse(partes[0].trim());
    final int? max = int.tryParse(partes[1].trim());
    if (min == null || max == null) return '\$$rango';

    final String formattedMin = _formatearNumero(min);
    final String formattedMax = _formatearNumero(max);

    return min == max ? '\$$formattedMin' : '\$$formattedMin - \$$formattedMax';
  }

  String _formatearNumero(int valor) {
    final str = valor.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

}
