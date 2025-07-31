import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_app/screens/forms_qr.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:form_app/screens/encuesta_screen.dart'; // Asumo que tienes esta pantalla para mostrar encuesta por ID

class InternalFormsScreen extends StatefulWidget {
  const InternalFormsScreen({super.key});

  @override
  State<InternalFormsScreen> createState() => _InternalFormsScreenState();
}

class _InternalFormsScreenState extends State<InternalFormsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Formularios Internos')),
        body: const Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Formularios Internos')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.obtenerEncuestasPorProfesor(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final encuestas = snapshot.data ?? [];

          if (encuestas.isEmpty) {
            return const Center(child: Text('No hay encuestas disponibles'));
          }

         for (var encuesta in encuestas) {
          print('Encuesta recibida: $encuesta');
        }

          return ListView(
            children: encuestas.map((encuesta) {
              final titulo = encuesta['titulo'] ?? 'Sin título';
              final encuestaId = encuesta['id'];
              return ListTile(
                title: Text(titulo),
                subtitle: Text(encuestaId ?? ''),
                trailing: IconButton(
                icon: const Icon(Icons.qr_code),
                tooltip: 'Mostrar QR',
                onPressed: () {
                  print('Botón QR presionado, ID: $encuestaId');
                  if (encuestaId != null && encuestaId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QrScreen(encuestaId: encuestaId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID de encuesta no válido')),
                    );
                  }
                },
              ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
