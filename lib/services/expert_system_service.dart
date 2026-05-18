import 'package:alburdat_dashboard/data/knowledge_base.dart';
import 'package:alburdat_dashboard/models/calculation_input.dart';
import 'package:alburdat_dashboard/models/calculation_result.dart';

class ExpertSystemService {
  static double getBaseDosis(int commodityId, double hst) {
    final rules = knowledgeBase[commodityId];
    if (rules == null) throw Exception("Commodity tidak ditemukan");

    final rule = rules.firstWhere(
      (r) => hst >= r.minHst && hst <= r.maxHst,
      orElse: () => rules.last,
    );

    return rule.dosis;
  }

  static double calculateDosisPerTanaman(
    int commodityId,
    double hst,
    int fertilizerId,
  ) {
    final base = getBaseDosis(commodityId, hst);
    final multiplier = fertilizerMultipliers[fertilizerId] ?? 1.0;

    return base * multiplier;
  }

  static CalculationResult calculate(CalculationInput input) {
    final dosisPerTanaman = calculateDosisPerTanaman(
      input.commodityId,
      input.hst,
      input.fertilizerId,
    );

    final totalGram = dosisPerTanaman * input.jumlahTanaman;

    return CalculationResult(
      dosisPerTanaman: dosisPerTanaman,
      totalPupukGram: totalGram,
    );
  }
}