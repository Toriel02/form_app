const functions = require('firebase-functions');
const admin = require('firebase-admin');
const qrcode = require('qrcode'); // Importa la librería qrcode

// Inicializa Firebase Admin SDK. Esto es crucial para interactuar con Firestore y Storage.
admin.initializeApp();

const firestore = admin.firestore();
const storage = admin.storage();

/**
 * Cloud Function: generateQrForForm
 *
 * Se dispara cada vez que un nuevo documento es creado en la colección 'forms'.
 * - Genera un código QR a partir de la 'urlDeForms' del nuevo formulario.
 * - Sube la imagen del QR a Firebase Cloud Storage.
 * - Actualiza el documento original del formulario en Firestore con la URL pública del QR.
 */
exports.generateQrForForm = functions.firestore
  .document('forms/{formId}') // Escucha los eventos de creación en la colección 'forms'
  .onCreate(async (snap, context) => { // 'snap' es el nuevo documento, 'context' contiene metadata
    const formData = snap.data(); // Obtiene los datos del nuevo documento del formulario
    const formId = context.params.formId; // Obtiene el ID del documento del formulario (ej. auto-generado por Firestore)
    const urlToEncode = formData.urlDeForms; // La URL que quieres convertir a QR

    // Si por alguna razón la URL no está presente, no hacemos nada.
    if (!urlToEncode) {
      console.log(`Formulario ${formId}: No se proporcionó 'urlDeForms'. Saltando la generación de QR.`);
      return null;
    }

    // El profesor ID para organizar los QRs en Storage, aunque no es estrictamente necesario si ya usas formId
    const teacherId = formData.teacherId; 

    try {
      // 1. Generar el código QR como un Buffer (datos binarios de la imagen)
      //    Puedes elegir el formato (por ejemplo, PNG)
      const qrImageBuffer = await qrcode.toBuffer(urlToEncode, { type: 'png', scale: 8 }); // 'scale' ajusta la resolución

      // 2. Definir la ruta de destino en Cloud Storage
      //    Es buena práctica organizar tus QRs. Por ejemplo: qrcodes/{teacherId}/{formId}.png
      const filePath = `qrcodes/${teacherId}/${formId}.png`;
      const file = storage.bucket().file(filePath);

      // 3. Subir el Buffer de la imagen al archivo en Cloud Storage
      await file.save(qrImageBuffer, {
        contentType: 'image/png', // Define el tipo de contenido
        public: true,             // Hace el archivo accesible públicamente (para obtener URL de descarga)
      });

      // 4. Obtener la URL pública de descarga del archivo subido
      //    Esta URL es la que guardarás en Firestore.
      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${storage.bucket().name}/o/${encodeURIComponent(filePath)}?alt=media`;

      // 5. Actualizar el documento original del formulario en Firestore
      //    Con la URL del QR recién generada y subida.
      await firestore.collection('forms').doc(formId).update({
        qrCodeUrl: publicUrl
      });

      console.log(`QR code para el formulario ${formId} generado y guardado en: ${publicUrl}`);
      return null; // Las Cloud Functions onCreate deben devolver null o una Promise
    } catch (error) {
      console.error(`Error al generar o subir QR para el formulario ${formId}:`, error);
      return null;
    }
  });