import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/NavigationBar/home_page.dart';
import 'package:graduation_project/NavigationBar/manage_page.dart';
import 'package:graduation_project/NavigationBar/medications_page.dart';
import 'package:graduation_project/NavigationBar/refills_page.dart';
import 'package:graduation_project/pages/profile_page.dart';
import 'package:graduation_project/pages/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// Navigation pages
  final List<Widget> _pages = [
    const HomePage(),
    const RefillsPage(),
    const MedicationsPage(),
    const ManagePage(),
  ];

  /// Switch between bottom navigation pages
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Build title with user's full name
  Widget _buildTitle() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Guest',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        } else if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text('User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        } else {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final firstName = data['firstName'] ?? 'User';
          final lastName = data['lastName'] ?? '';
          return Text('$firstName $lastName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle, size: 40, color: Colors.black),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
          },
        ),
        title: _buildTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kBottomNavigationBarHeight - kToolbarHeight,
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Highlight color
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_mode), label: 'Refills'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Medications'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Manage'),
        ],
      ),
    );
  }
}
