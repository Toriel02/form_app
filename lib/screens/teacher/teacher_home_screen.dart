import 'package:flutter/material.dart';
import 'package:form_app/screens/teacher/create_intform_screen.dart';
import 'package:form_app/screens/teacher/internal_forms_screen.dart';
import 'package:form_app/screens/teacher/my_forms_screen.dart';
import 'package:form_app/services/auth_service.dart'; // Asegúrate de que la ruta sea correcta
import 'package:form_app/screens/auth/login_screen.dart'; // Asegúrate de que la ruta sea correcta
import 'package:firebase_auth/firebase_auth.dart'; // Importar User de firebase_auth
// import 'package:form_app/services/firestore_services.dart';

// Importa la pantalla de creación de formularios
import 'package:form_app/screens/teacher/create_form_screen.dart'; // <--- Importación clave

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final AuthService _authService = AuthService(); // Instancia del servicio de autenticación
  // final FirestoreService _firestoreService = FirestoreService();

  User? _currentUser; // Para almacenar el usuario actual
  // bool _encuestasSubidas = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();


  // void _verificarYSubirEncuestas(String teacherId) async {
  //   final encuestasExistentes = await _firestoreService.obtenerEncuestasPorProfesorUnaVez(teacherId);

  //   if (encuestasExistentes.isEmpty) {
  //     await _firestoreService.subirEncuestasPorProfesor(teacherId);
  //   }

  //   setState(() {
  //     _encuestasSubidas = true;
  //   });
  }


  // Función para cerrar sesión
  void _logout() async {
    await _authService.signOut(); // Llama al método de cerrar sesión del servicio de autenticación
    // Después de cerrar sesión, navega de regreso a la pantalla de inicio de sesión
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Profesor'),
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
              '¡Bienvenido, Profesor!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, color: Colors.blue.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_currentUser != null)
              Text(
                'Has iniciado sesión como: ${_currentUser!.email}',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            // Botón para crear nuevo formulario (navegando a una nueva pantalla)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateFormScreen()), // <--- Navegación a la pantalla
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Nuevo Formulario'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            // Otros botones o contenido para el profesor
            ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyFormsScreen()),
                  );
                },
                icon: const Icon(Icons.list_alt), // Un icono relevante, como una lista o formulario
                label: const Text(
                  'Ver Mis Formularios',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue.shade600, // Un color que combine con tu tema
                  foregroundColor: Colors.white,
                  elevation: 5, // Sombra para un efecto más elevado
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadInternalSurveysScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download), // Ícono de descarga
                label: const Text('Obtener Formularios'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
              ),
              // Botón para formularios internos
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InternalFormsScreen()),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: const Text('Formularios Internos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
              ),
            const SizedBox(height: 20),
             ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a la pantalla para ver respuestas
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ver Respuestas de Formularios (Próximamente)')),
                );
              },
              icon: const Icon(Icons.inbox),
              label: const Text('Ver Respuestas'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}