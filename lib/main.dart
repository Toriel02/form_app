import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:form_app/screens/auth/login_screen.dart';
import 'package:form_app/screens/students/student_qr.dart';
import 'package:form_app/screens/teacher/teacher_home_screen.dart';
import 'package:form_app/screens/students/student_home_screen.dart';
import 'package:form_app/services/auth_service.dart';
// Asegúrate de que este archivo exista y contenga las opciones de Firebase para tu proyecto.
// Se genera automáticamente al ejecutar `flutterfire configure`.
import 'package:form_app/firebase_options.dart';

void main() async {
  // Asegura que los widgets de Flutter estén inicializados antes de usar Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase con las opciones de la plataforma actual.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feedback App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Usando la fuente Inter para una estética moderna
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Esquinas redondeadas para botones
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // Esquinas redondeadas para campos de entrada
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Esquinas redondeadas para tarjetas
          ),
          margin: const EdgeInsets.all(8.0),
        ),
      ),
      // StreamBuilder escucha los cambios de estado de autenticación de Firebase.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('StreamBuilder: ConnectionState: ${snapshot.connectionState}');
          print('StreamBuilder: Has data (user): ${snapshot.hasData}');
          print('StreamBuilder: User UID: ${snapshot.data?.uid}');

          // Muestra un indicador de carga mientras se verifica el estado de autenticación.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }
          // Si hay un usuario autenticado...
          if (snapshot.hasData) {
            // ...obtiene el rol del usuario desde Firestore.
            return FutureBuilder<String?>(
              future: AuthService().getUserRole(snapshot.data!.uid),
              builder: (context, roleSnapshot) {
                print('FutureBuilder (Role): ConnectionState: ${roleSnapshot.connectionState}');
                print('FutureBuilder (Role): Has data (role): ${roleSnapshot.hasData}');
                print('FutureBuilder (Role): Role: ${roleSnapshot.data}');
                print('FutureBuilder (Role): Error: ${roleSnapshot.error}');


                // Muestra un indicador de carga mientras se obtiene el rol.
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  );
                }
                // Si el rol está disponible, redirige según el rol.
                if (roleSnapshot.hasData && roleSnapshot.data != null) {
                  final role = roleSnapshot.data;
                  if (role == 'teacher') {
                    print('Navegando a TeacherHomeScreen');
                    return const TeacherHomeScreen(); // Redirige a la pantalla del profesor
                  } else if (role == 'student') {
                    print('Navegando a StudentHomeScreen');
                    return const StudentHomeScreen(); // Redirige a la pantalla del estudiante
                  }
                }
                // Si no se encuentra el rol o hay un error, redirige a la pantalla de inicio de sesión.
                // Esto podría ocurrir si el documento del usuario no tiene el campo 'role' por alguna razón.
                print('Volviendo a LoginScreen: Rol no encontrado o error.');
                return const LoginScreen();
              },
            );
          }
          // Si no hay un usuario autenticado, muestra la pantalla de inicio de sesión.
          print('Volviendo a LoginScreen: No hay usuario autenticado.');
          return const LoginScreen();
        },
      ),
    );
  }
}
