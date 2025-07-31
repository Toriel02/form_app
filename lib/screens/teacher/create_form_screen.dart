import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data'; // Para manejar datos binarios (Uint8List, ByteData)
import 'package:firebase_storage/firebase_storage.dart'; 
import 'dart:ui' as ui; 

class CreateFormScreen extends StatefulWidget {
  const CreateFormScreen({super.key});

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // Función asíncrona para manejar la creación del formulario,
  // incluyendo la generación del QR, su subida a Storage y el guardado en Firestore.
  Future<void> _createForm() async {
    // 1. Validaciones básicas de entrada de datos
    if (_titleController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título y una URL para el formulario.')),
      );
      return;
    }

    // Muestra un indicador de carga al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardando formulario y subiendo QR...')),
    );

    String? generatedQrCodeUrl; // Variable para almacenar la URL de descarga del QR
    String? formId; // Variable para almacenar el ID del formulario creado en Firestore

    try {
      final qrPainter = QrPainter(
        data: _urlController.text, 
        version: QrVersions.auto, 
        errorCorrectionLevel: QrErrorCorrectLevel.M, 
        gapless: true,
      );

      // Renderizar el QrPainter a ByteData (la imagen en formato de bytes)
      // Se utiliza un PictureRecorder para dibujar el QR en un lienzo y luego convertirlo a imagen.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      qrPainter.paint(canvas, const Size(200, 200));
      final ui.Picture picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(200, 200);
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception("No se pudo generar el ByteData del código QR.");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      //Sube la imagen del QR a Firebase Cloud Storage
      final storageRef = FirebaseStorage.instance.ref();
      final String qrFileName = 'qr_${DateTime.now().microsecondsSinceEpoch}.png';
      final uploadPath = 'qrcodes/$qrFileName'; 
      final uploadTask = storageRef.child(uploadPath).putData(pngBytes); 
      // Esperar a que la subida se complete
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      // Obtener la URL de descarga de la imagen subida
      generatedQrCodeUrl = await snapshot.ref.getDownloadURL();
      print("QR subido a Storage con URL: $generatedQrCodeUrl");

    } catch (e) {
      // Manejo de errores durante la generación o subida del QR
      print('Error al generar o subir QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar o subir el código QR: ${e.toString()}')),
      );
      generatedQrCodeUrl = ''; 
    }

    //Guardar el formulario en Firestore con la URL del QR (o vacía si la subida falló)
    try {
      formId = await _firestoreService.addFormToFirestore(
        titulo: _titleController.text,
        urlDeForms: _urlController.text,
        qrCodeUrl: generatedQrCodeUrl ?? '', // Se pasa la URL de Storage aquí
      );

      //Comprobar si el formulario se guardó exitosamente en Firestore
      if (formId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formulario "${_titleController.text}" creado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        
        _titleController.clear();
        _urlController.clear();
        // Opcional: Navegar de vuelta a la pantalla anterior o actualizar la lista de formularios
        // Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el formulario en Firestore.'),
            backgroundColor: Colors.red, 
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error inesperado al guardar el formulario: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Excepción general al crear formulario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Crear Nuevo Formulario",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del Formulario',
                hintText: 'Ej: Encuesta de Satisfacción del Cliente',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL del Formulario',
                hintText: 'Ej: https://docs.google.com/forms/d/e/...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _createForm,
              icon: const Icon(Icons.save),
              label: const Text(
                'Guardar Formulario',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF0D47A1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}