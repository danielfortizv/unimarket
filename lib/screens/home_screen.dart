import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _emprendimientos = List.generate(20, (index) {
    return {
      "nombre": "Emprendimiento ${index + 1}",
      "rating": 4.5,
      "precio": "\$80 - \$120",
      "descripcion": "Descripción breve del negocio número ${index + 1}.",
      "hashtags": "#emprendimiento #universitario #producto",
      "imagen":
          "https://via.placeholder.com/400x300.png?text=Producto+${index + 1}"
    };
  });

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildEmprendimientoCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF76C3BD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(item["nombre"], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            trailing: Text(item["precio"], style: const TextStyle(fontSize: 16)),
            subtitle: Row(
              children: [
                const Icon(Icons.star, size: 16),
                Text(item["rating"].toString()),
              ],
            ),
          ),
          Image.network(item["imagen"], fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(item["descripcion"]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(item["hashtags"], style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.chat_bubble_outline),
                SizedBox(width: 12),
                Icon(Icons.bookmark_border),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/octans_logo.png", height: 40),
            const SizedBox(width: 8),
            const Text("UniMarket", style: TextStyle(fontSize: 22)),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF102044),
      ),
      body: ListView.builder(
        itemCount: _emprendimientos.length,
        itemBuilder: (context, index) {
          return buildEmprendimientoCard(_emprendimientos[index]);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF102044),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
