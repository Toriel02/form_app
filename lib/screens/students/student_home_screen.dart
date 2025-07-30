import 'package:flutter/material.dart';
import 'package:form_app/screens/students/student_qr.dart';
import 'package:form_app/services/auth_service.dart'; // Asegúrate de que la ruta sea correcta
import 'package:form_app/screens/auth/login_screen.dart'; // Asegúrate de que la ruta sea correcta
import 'package:firebase_auth/firebase_auth.dart'; // Importar User de firebase_auth
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService _authService = AuthService(); // Instancia del servicio de autenticación
  User? _currentUser; // Para almacenar el usuario actual

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser(); // Obtener el usuario actual al iniciar la pantalla
  }

  // Función para cerrar sesión
  void _logout() async {
    await _authService.signOut(); // Llama al método de cerrar sesión del servicio de autenticación
    // Después de cerrar sesión, navega de regreso a la pantalla de inicio de sesión
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _goToQRScanner() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QRScannerScreen()));
  }

  Future<String?> _getUserName() async {
  final uid = _currentUser?.uid;
  if (uid == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
  if (doc.exists) {
    return doc.data()?['name'] as String?;
  }
  return null;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Estudiante'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Llama a la función de cerrar sesión
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, Estudiante!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, color: Colors.blue.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_currentUser != null)
              FutureBuilder<String?>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error al cargar el nombre: ${snapshot.error}');
                  } else if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Has iniciado sesión como: ${snapshot.data}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    );
                  } else {
                    // fallback si no hay nombre guardado
                    return Text(
                      'Has iniciado sesión como: ${_currentUser!.email}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    );
                  }
                },
              ),
            const SizedBox(height: 32),
            // Aquí irán las opciones para acceder a formularios, ver historial, etc.
            // Por ahora, solo un marcador de posición.
            Text(
              'Esta es tu pantalla principal como estudiante.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Responder Encuesta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _goToQRScanner,
            ),
          ],
        ),
      ),
    );
  }
}
