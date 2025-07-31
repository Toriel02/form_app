import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_app/screens/encuesta_screen.dart';
import 'package:form_app/services/firestore_services.dart'; // Asegúrate de que la ruta sea correcta
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _dialogShown = false; // Para evitar que se muestren múltiples diálogos
  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      // Puedes configurar la cámara aquí si es necesario
      // cameraFacing: CameraFacing.back,
      // detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    controller.dispose(); // Asegúrate de disponer el controlador cuando el widget se destruye
    super.dispose();
  }

  // Función para verificar la encuesta y navegar
  Future<void> _verificarEncuesta(String code) async {
    // Verificar si el usuario está autenticado antes de intentar leer de Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      _showAlertDialog(
        'Error de Autenticación',
        'Debes iniciar sesión para escanear encuestas.',
        shouldRestartScanner: true, // Reiniciar escáner después de este diálogo
      );
      return;
    }

    Map<String, dynamic>? encuesta;
    try {
      // Intentar obtener la encuesta por su ID
      encuesta = await _firestoreService.obtenerEncuestaPorId(code);
    } on FirebaseException catch (e) {
      // Capturar errores específicos de Firebase (como permission-denied)
      if (!mounted) return;
      String errorMessage = 'Error desconocido al obtener encuesta.';
      if (e.code == 'permission-denied') {
        errorMessage = 'No tienes permisos para acceder a esta encuesta. Asegúrate de que tu cuenta sea de estudiante y esté configurada correctamente.';
      } else {
        errorMessage = 'Error de Firestore: ${e.message} (${e.code})';
      }
      _showAlertDialog(
        'Error de Acceso',
        errorMessage,
        shouldRestartScanner: true, // Reiniciar escáner después de este diálogo
      );
      print('Firebase Exception al obtener encuesta: $e');
      return;
    } catch (e) {
      // Capturar otros errores
      if (!mounted) return;
      _showAlertDialog(
        'Error',
        'Ocurrió un error inesperado al verificar la encuesta: ${e.toString()}',
        shouldRestartScanner: true, // Reiniciar escáner después de este diálogo
      );
      print('Excepción general al obtener encuesta: $e');
      return;
    }

    if (!mounted) return; // Asegurarse de que el widget aún está montado

    if (encuesta != null) {
      _showAlertDialog(
        'Encuesta Encontrada',
        'Encuesta: ${encuesta['titulo']}\n¿Deseas responderla?',
        onConfirm: () {
          Navigator.pop(context); // Cierra el AlertDialog
          // Navegar a la pantalla de la encuesta.
          // El escáner se reiniciará cuando se regrese de EncuestaScreen.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EncuestaScreen(id: code), // Pasa el ID de la encuesta
            ),
          ).then((_) {
            // Este .then() se ejecuta cuando se regresa de EncuestaScreen
            if (mounted) {
              controller.start(); // Reinicia el escáner al volver a esta pantalla
            }
          });
        },
        onCancel: () {
          Navigator.pop(context); // Cierra el AlertDialog
          if (mounted) {
            controller.start(); // Reinicia el escáner si el usuario cancela
          }
        },
        showCancelButton: true,
        shouldRestartScanner: false, // El reinicio se maneja en los callbacks específicos
      );
    } else {
      _showAlertDialog(
        'Encuesta No Encontrada',
        'No se encontró ninguna encuesta con ese ID. Por favor, escanea un código QR válido.',
        shouldRestartScanner: true, // Reiniciar escáner después de este diálogo
      );
    }
  }

  // Función genérica para mostrar AlertDialogs
  void _showAlertDialog(String title, String content, {
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showCancelButton = false,
    bool shouldRestartScanner = false,
  }) {
    if (_dialogShown && mounted) {
      // Si ya hay un diálogo visible, no mostrar otro
      return;
    }
    _dialogShown = true; // Marca que un diálogo está a punto de mostrarse

    showDialog(
      context: context,
      barrierDismissible: false, // No se cierra al tocar fuera
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (showCancelButton)
            TextButton(
              onPressed: () {
                // Llama al callback de cancelar si existe, de lo contrario, usa la lógica por defecto
                if (onCancel != null) {
                  onCancel();
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancelar'),
            ),
          TextButton(
            onPressed: () {
              // Llama al callback de confirmar si existe, de lo contrario, usa la lógica por defecto
              if (onConfirm != null) {
                  onConfirm();
              } else {
                  Navigator.pop(context);
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    ).then((_) {
      // Este .then() se ejecuta DESPUÉS de que el diálogo es cerrado (popped)
      if (mounted) { // Asegurarse de que el widget aún está montado
        _dialogShown = false; // Restablece la bandera del diálogo
        if (shouldRestartScanner) {
          controller.start(); // Reinicia el escáner solo si se indicó y el widget está montado
        }
      }
    });
  }

  // Callback cuando el escáner detecta un código QR
  void _onDetect(BarcodeCapture barcode) {
    final String? code = barcode.barcodes.first.rawValue;

    if (code != null && !_dialogShown) { // Solo procesar si no hay un diálogo activo
      print('Código QR detectado: $code');
      controller.stop(); // Detener el escáner para evitar múltiples detecciones mientras se procesa
      // _dialogShown se establece a true dentro de _showAlertDialog
      _verificarEncuesta(code); // Llamar a la función de verificación
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanea una Encuesta'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Puedes añadir un overlay aquí para guiar al usuario
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Apunta la cámara al código QR de la encuesta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
