class CalculationResult {
  final double dosisPerTanaman; // gram/tanaman
  final double totalPupukGram;  // gram
  final double totalPupukKg;    // kg

  CalculationResult({
    required this.dosisPerTanaman,
    required this.totalPupukGram,
  }) : totalPupukKg = totalPupukGram / 1000;
}