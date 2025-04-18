import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'chats_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, required int initialIndex});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    BuscadorScreen(),
    ChatsScreen(),
    PerfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UNIMARKET',
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.delivery_dining, size: 32),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shopping_cart_outlined, size: 28),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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
