import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadInternalSurveysScreen extends StatefulWidget {
  const UploadInternalSurveysScreen({super.key});

  @override
  State<UploadInternalSurveysScreen> createState() => _UploadInternalSurveysScreenState();
}

class _UploadInternalSurveysScreenState extends State<UploadInternalSurveysScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploading = false;
  String _message = '';

  Future<void> _uploadSurveys() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _message = 'No hay usuario autenticado.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _message = 'Subiendo encuestas...';
    });

    try {
      await _firestoreService.subirEncuestasPorProfesor(user.uid);
      setState(() {
        _message = 'Encuestas subidas correctamente.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error al subir encuestas: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _uploadSurveys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Encuestas Internas')),
      body: Center(
        child: _isUploading
            ? const CircularProgressIndicator()
            : Text(_message, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}