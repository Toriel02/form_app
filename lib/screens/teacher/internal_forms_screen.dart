import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  void _mostrarQRModal(String? encuestaId) {
    if (encuestaId == null || encuestaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de encuesta no válido')),
      );
      return;
    }

    showDialog(
  context: context,
  barrierDismissible: true,
  builder: (context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escanea este código para responder la encuesta',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            height: 220,
            child: Builder(
              builder: (context) {
                try {
                  return QrImageView(
                    data: encuestaId.toString(),
                    version: QrVersions.auto,
                    size: 220.0,
                  );
                } catch (e) {
                  return const Text(
                    'No se pudo generar el código QR.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  );
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
          ),
          child: const Text('Cerrar'),
        ),
      ],
    );
  },
);

  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Formularios Internos'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white, // Texto blanco
        ),
        body: const Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formularios Internos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white, // Texto blanco en el título
        elevation: 0,
      ),
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

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: encuestas.length,
            itemBuilder: (context, index) {
              final encuesta = encuestas[index];
              final titulo = encuesta['titulo'] ?? 'Sin título';
              final encuestaId = encuesta['id'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.article_outlined, size: 32, color: Colors.blueGrey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            encuestaId ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                      iconSize: 30,
                      tooltip: 'Mostrar QR',
                      onPressed: () {
                        _mostrarQRModal(encuestaId);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
