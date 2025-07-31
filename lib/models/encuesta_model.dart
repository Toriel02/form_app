class Encuesta {
  final String id;
  final String titulo;
  final String pregunta;
  final List<String> opciones;

  Encuesta({
    required this.id,
    required this.titulo,
    required this.pregunta,
    required this.opciones,
  });

  factory Encuesta.fromMap(String id, Map<String, dynamic> data) {
    return Encuesta(
      id: id,
      titulo: data['titulo'],
      pregunta: data['pregunta'],
      opciones: List<String>.from(data['opciones']),
    );
  }
}