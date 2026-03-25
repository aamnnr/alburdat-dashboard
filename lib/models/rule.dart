class Rule {
  final int minHst;
  final double maxHst; // menggunakan double agar bisa menerima Infinity
  final double dosis;

  const Rule({
    required this.minHst,
    required this.maxHst,
    required this.dosis,
  });

  // Cek apakah HST termasuk dalam rentang aturan ini
  bool matches(int hst) {
    return hst >= minHst && hst <= maxHst;
  }
}