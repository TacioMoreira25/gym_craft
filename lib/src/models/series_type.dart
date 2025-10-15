enum SeriesType {
  valid('Válida', 'Série principal do exercício'),
  warmup('Aquecimento', 'Série de aquecimento'),
  recognition('Reconhecimento', 'Série para reconhecer o peso'),
  dropset('Drop Set', 'Série com redução de carga'),
  failure('Falha', 'Série até a falha muscular'),
  rest('Descanso', 'Série de descanso ativo'),
  negativa('Negativa', 'Série focada na fase negativa');

  const SeriesType(this.displayName, this.description);
  
  final String displayName;
  final String description;

  static SeriesType fromString(String value) {
    return SeriesType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SeriesType.valid,
    );
  }
}