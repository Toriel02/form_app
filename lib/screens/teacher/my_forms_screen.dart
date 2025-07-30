 import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para el tipo Timestamp
import 'package:cached_network_image/cached_network_image.dart'; // Para cargar imágenes de red con caché
import 'package:url_launcher/url_launcher.dart'; // Para abrir la URL del formulario

class MyFormsScreen extends StatefulWidget {
  const MyFormsScreen({super.key});

  @override
  State<MyFormsScreen> createState() => _MyFormsScreenState();
}

class _MyFormsScreenState extends State<MyFormsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Formularios"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getMyForms(), // Escucha los formularios del profesor
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error en StreamBuilder de Mis Formularios: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No has creado ningún formulario aún.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Si hay datos, construye la lista
          final forms = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: forms.length,
            itemBuilder: (context, index) {
              final form = forms[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    form['titulo'] ?? 'Sin título',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('URL: ${form['urlDeForms'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                        
                        // Muestra la fecha de creación
                        if (form['fechaCreacion'] != null)
                          Text('Creado: ${ (form['fechaCreacion'] as Timestamp).toDate().toString().split(' ')[0] }',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        
                        // Muestra el QR si la URL está disponible
                        if (form['qrCodeUrl'] != null && (form['qrCodeUrl'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Center(
                              child: CachedNetworkImage( // Usa CachedNetworkImage para mejor manejo de caché
                                imageUrl: form['qrCodeUrl'],
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                                width: 100, // Tamaño del QR en la lista
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(top: 10.0),
                            child: Text(
                              'QR no disponible o en proceso de subida.',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                  onTap: () {
                    // Al hacer tap, muestra el QR y la URL en un diálogo
                    _showFormDetailsDialog(context, form);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función para mostrar los detalles del formulario y el QR en un diálogo
  void _showFormDetailsDialog(BuildContext context, Map<String, dynamic> form) {
    final String formUrl = form['urlDeForms'] ?? '';
    final String qrImageUrl = form['qrCodeUrl'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(form['titulo'] ?? 'Detalles del Formulario'),
          content: SingleChildScrollView( // Permite desplazamiento si el contenido es largo
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (qrImageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: qrImageUrl,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error, size: 50, color: Colors.red),
                    width: 250, // Tamaño más grande en el diálogo
                    height: 250,
                    fit: BoxFit.contain,
                  )
                else
                  const Text(
                    'QR no disponible. Asegúrate de que la URL del formulario sea válida y el QR se haya subido correctamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                const SizedBox(height: 10),
                Text(
                  'URL del Formulario:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 5),
                Text(
                  formUrl,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
                const SizedBox(height: 10),
                Text(
                  'Escanea este QR para acceder al formulario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse(formUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo abrir la URL: $formUrl')),
                  );
                }
                Navigator.of(context).pop(); // Cerrar diálogo después de intentar abrir
              },
              child: const Text('Abrir Formulario'),
            ),
            // Opcional: Botón para copiar la URL
            TextButton(
              onPressed: () {
                // Requiere 'package:flutter/services.dart'
                // Clipboard.setData(ClipboardData(text: formUrl));
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('URL copiada al portapapeles.')),
                // );
                // Navigator.of(context).pop();
              },
              child: const Text('Copiar URL'),
            ),
          ],
        );
      },
    );
  }
}
