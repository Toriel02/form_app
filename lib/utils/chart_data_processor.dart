
/// Procesa respuestas para preguntas de tipo "escala" (ej. 1 al 5).
/// Retorna un mapa donde la clave es la opción (como String) y el valor es el conteo.
Map<String, int> procesarRespuestasEscala(
  List<Map<String, dynamic>> todasLasRespuestas,
  String preguntaId,
  List<dynamic> opcionesEscala, // Las opciones originales de la escala (ej. [1, 2, 3, 4, 5])
) {
  final Map<String, int> conteoRespuestas = {};

  // Inicializar conteos para todas las opciones posibles de la escala
  for (var opcion in opcionesEscala) {
    conteoRespuestas[opcion.toString()] = 0;
  }

  for (var respuestaUsuario in todasLasRespuestas) {
    // Las respuestas de las preguntas están dentro del campo 'data'
    final respuestas = respuestaUsuario['data'] as Map<String, dynamic>;
    if (respuestas.containsKey(preguntaId)) {
      final respuesta = respuestas[preguntaId];
      if (respuesta != null) {
        // Asegúrate de que la respuesta sea un número y conviértela a String para la clave
        conteoRespuestas[respuesta.toString()] =
            (conteoRespuestas[respuesta.toString()] ?? 0) + 1;
      }
    }
  }
  return conteoRespuestas;
}

/// Procesa respuestas para preguntas de tipo "si_no" (ej. "Sí" o "No").
/// Retorna un mapa con "Sí" y "No" y sus conteos.
Map<String, int> procesarRespuestasSiNo(
  List<Map<String, dynamic>> todasLasRespuestas,
  String preguntaId,
) {
  final Map<String, int> conteoRespuestas = {
    "Sí": 0,
    "No": 0,
  };

  for (var respuestaUsuario in todasLasRespuestas) {
    // Las respuestas de las preguntas están dentro del campo 'data'
    final respuestas = respuestaUsuario['data'] as Map<String, dynamic>;
    if (respuestas.containsKey(preguntaId)) {
      final respuesta = respuestas[preguntaId];

      // La pantalla de encuesta está enviando "Sí" o "No" como String.
      if (respuesta is String) {
        if (respuesta == "Sí") {
          conteoRespuestas["Sí"] = (conteoRespuestas["Sí"] ?? 0) + 1;
        } else if (respuesta == "No") {
          conteoRespuestas["No"] = (conteoRespuestas["No"] ?? 0) + 1;
        }
      }
      // Opcional: Si en algún momento guardas booleanos (true/false) para si_no,
      // también puedes manejarlos aquí.
      else if (respuesta is bool) {
        if (respuesta) {
          conteoRespuestas["Sí"] = (conteoRespuestas["Sí"] ?? 0) + 1;
        } else {
          conteoRespuestas["No"] = (conteoRespuestas["No"] ?? 0) + 1;
        }
      }
    }
  }
  return conteoRespuestas;
}

// Puedes añadir una función dummy para preguntas de texto si necesitas
// mostrar su presencia sin un gráfico de barras.
Map<String, int> procesarRespuestasTexto(
    List<Map<String, dynamic>> todasLasRespuestas, String preguntaId) {
  // Para preguntas de texto, no generamos un gráfico de barras.
  // Podrías devolver un mapa vacío o contar cuántas respuestas hay.
  return {"Respuestas de texto": todasLasRespuestas.length};
}