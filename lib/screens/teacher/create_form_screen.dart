import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Para generar el QR con qr_flutter
import 'dart:typed_data'; // Para manejar datos binarios (Uint8List, ByteData)
import 'package:firebase_storage/firebase_storage.dart'; // Para subir el QR a Storage
import 'dart:ui' as ui; // Importar con prefijo para evitar conflictos con 'Image' de material.dart

// Las importaciones de image_gallery_saver y permission_handler ya NO son necesarias
// cuando el QR se sube a Firebase Storage, ya que no se guarda localmente.
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:permission_handler/permission_handler.dart';

class CreateFormScreen extends StatefulWidget {
  const CreateFormScreen({super.key});

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  // Controladores para los campos de texto del formulario
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  // Instancia de tu servicio de Firestore
  final FirestoreService _firestoreService = FirestoreService();

  // La variable _qrImageBytes y las funciones _requestPermission y _saveQrCode
  // ya NO son necesarias porque el QR no se guarda localmente.
  // Uint8List? _qrImageBytes; 

  @override
  void dispose() {
    // Es importante liberar los controladores cuando el widget se destruye
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // Las funciones _requestPermission y _saveQrCode se eliminan de aquí.
  // Future<bool> _requestPermission(Permission permission) async { ... }
  // Future<void> _saveQrCode() async { ... }

  // Función asíncrona para manejar la creación del formulario,
  // incluyendo la generación del QR, su subida a Storage y el guardado en Firestore.
  Future<void> _createForm() async {
    // 1. Validaciones básicas de entrada de datos
    if (_titleController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título y una URL para el formulario.')),
      );
      return; // Detiene la ejecución si los campos están vacíos
    }

    // Muestra un indicador de carga al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardando formulario y subiendo QR...')),
    );

    String? generatedQrCodeUrl; // Variable para almacenar la URL de descarga del QR
    String? formId; // Variable para almacenar el ID del formulario creado en Firestore

    try {
      // 2. Generar la imagen del QR usando la librería qr_flutter
      final qrPainter = QrPainter(
        data: _urlController.text, // La URL del formulario es el contenido del QR
        version: QrVersions.auto, // Versión automática del QR
        errorCorrectionLevel: QrErrorCorrectLevel.M, // Nivel de corrección de error
        gapless: true, // Sin espacios entre los módulos del QR
      );

      // Renderizar el QrPainter a ByteData (la imagen en formato de bytes)
      // Se utiliza un PictureRecorder para dibujar el QR en un lienzo y luego convertirlo a imagen.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      qrPainter.paint(canvas, const Size(200, 200)); // Dibuja el QR en un lienzo de 200x200
      final ui.Picture picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(200, 200); // Convierte el dibujo a una imagen real
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png); // Obtiene los bytes en formato PNG
      
      if (byteData == null) {
        throw Exception("No se pudo generar el ByteData del código QR.");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List(); // Convierte ByteData a Uint8List

      // 3. Subir la imagen del QR a Firebase Cloud Storage
      final storageRef = FirebaseStorage.instance.ref();
      // Genera un nombre de archivo único para el QR basado en la marca de tiempo
      final String qrFileName = 'qr_${DateTime.now().microsecondsSinceEpoch}.png';
      // Define la ruta completa en Storage (ej: qrcodes/qr_123456789.png)
      final uploadPath = 'qrcodes/$qrFileName'; 
      // Crea una referencia al archivo en Storage y sube los bytes
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
      // Si la subida del QR falla, el formulario se guardará sin la URL del QR
      generatedQrCodeUrl = ''; 
    }

    // 4. Guardar el formulario en Firestore con la URL del QR (o vacía si la subida falló)
    try {
      formId = await _firestoreService.addFormToFirestore(
        titulo: _titleController.text,
        urlDeForms: _urlController.text,
        qrCodeUrl: generatedQrCodeUrl ?? '', // Se pasa la URL de Storage aquí
      );

      // 5. Comprobar si el formulario se guardó exitosamente en Firestore
      if (formId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formulario "${_titleController.text}" creado con éxito.'),
            backgroundColor: Colors.green, // Mensaje de éxito en verde
          ),
        );
        // Limpiar los campos del formulario después de una creación exitosa
        _titleController.clear();
        _urlController.clear();
        // Opcional: Navegar de vuelta a la pantalla anterior o actualizar la lista de formularios
        // Navigator.pop(context); 
      } else {
        // Mensaje de error si el formulario no se pudo guardar en Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el formulario en Firestore.'),
            backgroundColor: Colors.red, // Mensaje de error en rojo
          ),
        );
      }
    } catch (e) {
      // Captura cualquier excepción general durante el proceso de guardado en Firestore
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
      appBar: AppBar(
        title: const Text("Crear Nuevo Formulario"),
        backgroundColor: Colors.blue.shade700, // Color de la barra de aplicación
        foregroundColor: Colors.white,         // Color del texto y los iconos
      ),
      body: SingleChildScrollView( // Permite desplazamiento si el contenido es demasiado largo
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar los widgets horizontalmente
          children: [
            // Campo de texto para el título del formulario
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Formulario',
                hintText: 'Ej: Encuesta de Satisfacción del Cliente',
                border: OutlineInputBorder(), // Borde alrededor del campo
                prefixIcon: Icon(Icons.title), // Icono decorativo
              ),
              keyboardType: TextInputType.text, // Tipo de teclado para texto
              textCapitalization: TextCapitalization.sentences, // Capitaliza la primera letra
            ),
            const SizedBox(height: 20), // Espacio vertical entre los campos

            // Campo de texto para la URL del formulario
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL del Formulario',
                hintText: 'Ej: https://docs.google.com/forms/d/e/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url, // Sugiere teclado URL
            ),
            const SizedBox(height: 30), // Espacio antes del botón

            // Botón para crear el formulario
            ElevatedButton.icon(
              onPressed: _createForm, // Llama a la función _createForm al presionar
              icon: const Icon(Icons.save),
              label: const Text(
                'Guardar Formulario',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15), // Relleno interno del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Bordes redondeados del botón
                ),
                backgroundColor: Colors.blue.shade600, // Color de fondo del botón
                foregroundColor: Colors.white,          // Color del texto y el icono del botón
              ),
            ),
            const SizedBox(height: 30),

            // En esta pantalla, ya NO mostramos el QR después de la creación
            // ni el botón de guardar en galería, ya que se sube automáticamente a Storage.
            // La visualización se hará en la pantalla "Mis Formularios" leyendo la URL de Firestore.
          ],
        ),
      ),
    );
  }
}
