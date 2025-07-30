import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data'; // Para ByteData

// Nuevas importaciones para guardar imagen y manejar permisos
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateFormScreen extends StatefulWidget {
  const CreateFormScreen({super.key});

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  Uint8List? _qrImageBytes; // Para almacenar el QR generado en memoria

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // Función para solicitar permisos de almacenamiento
  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    }
    final result = await permission.request();
    return result == PermissionStatus.granted;
  }

  // Función para guardar el QR en la galería
  Future<void> _saveQrCode() async {
    if (_qrImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero genera un código QR.')),
      );
      return;
    }

    // Solicitar permiso de almacenamiento (específico para Android 10+ o iOS)
    PermissionStatus status;
    if (Theme.of(context).platform == TargetPlatform.android) {
        // En Android 13+ puede ser mejor MediaLibrary o Photos para guardar imágenes
        // Para simplificar, usamos Storage aquí que cubre versiones anteriores y aún es común.
        status = await Permission.storage.request();
    } else {
        // iOS usa Photos para guardar en la galería
        status = await Permission.photos.request();
    }
    
    // if (status.isGranted) {
    //   try {
    //     final result = await ImageGallerySaver.saveImage(
    //       _qrImageBytes!,
    //       quality: 80, // Calidad de la imagen (0-100)
    //       name: "QR_Formulario_${_titleController.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}",
    //     );
    //     print("QR guardado: $result");
    //     if (result['isSuccess']) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text('Código QR guardado en la galería!')),
    //       );
    //     } else {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text('Error al guardar QR: ${result['errorMessage']}')),
    //       );
    //     }
    //   } catch (e) {
    //     print('Excepción al guardar QR: $e');
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Error al guardar el código QR: $e')),
    //     );
    //   }
    // } else if (status.isDenied) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Permiso de almacenamiento denegado. No se pudo guardar el QR.')),
    //   );
    // } else if (status.isPermanentlyDenied) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(
    //             content: const Text('Permiso de almacenamiento permanentemente denegado. Habilítalo en Ajustes.'),
    //             action: SnackBarAction(label: 'Abrir Ajustes', onPressed: openAppSettings),
    //         ),
    //     );
    // }
  }

  Future<void> _createForm() async {
    if (_titleController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título y una URL para el formulario.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardando formulario...')),
    );

    setState(() {
      _qrImageBytes = null; // Reiniciar antes de generar uno nuevo
    });

    String? formId;
    try {
      formId = await _firestoreService.addFormToFirestore(
        titulo: _titleController.text,
        urlDeForms: _urlController.text,
        qrCodeUrl: '', // Se mantiene vacío ya que el QR no se guarda en Storage
      );

      if (formId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formulario "${_titleController.text}" creado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );

        // Generar la imagen del QR para visualización y posible guardado
        try {
          final qrPainter = QrPainter(
            data: _urlController.text,
            version: QrVersions.auto,
            gapless: true,
          );

          final ByteData? byteData = await qrPainter.toImageData(200);
          if (byteData != null) {
            setState(() {
              _qrImageBytes = byteData.buffer.asUint8List();
            });
          } else {
            print('Advertencia: No se pudo generar ByteData para el QR.');
          }
        } catch (qrError) {
          print('Error al generar la imagen del QR: $qrError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al generar la imagen del QR: ${qrError.toString()}'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Limpiar los campos solo si se quiere permitir crear otro
        // _titleController.clear();
        // _urlController.clear();

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
          content: Text('Ocurrió un error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Excepción general al crear formulario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Nuevo Formulario"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Formulario',
                hintText: 'Ej: Encuesta de Satisfacción del Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL del Formulario',
                hintText: 'Ej: https://docs.google.com/forms/d/e/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _createForm,
              icon: const Icon(Icons.save),
              label: const Text(
                'Guardar Formulario',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Mostrar el QR generado y el botón para guardar
            if (_qrImageBytes != null)
              Column(
                children: [
                  const Text(
                    'Código QR Generado:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Image.memory(
                    _qrImageBytes!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saveQrCode, // Botón para guardar el QR
                    icon: const Icon(Icons.download),
                    label: const Text('Guardar QR en Galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Guarda este QR para compartirlo con tus estudiantes.',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (_qrImageBytes == null && (_titleController.text.isNotEmpty || _urlController.text.isNotEmpty))
              const Text(
                'El QR se mostrará aquí después de guardar el formulario.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}