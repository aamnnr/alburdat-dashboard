import 'package:alburdat_dashboard/data/knowledge_base.dart';
import 'package:alburdat_dashboard/models/commodity.dart';

class ExpertSystemService {
  static double? getDosis({required int commodityId, required int hst}) {
    final rules = knowledgeBase[commodityId];
    if (rules == null) return null;

    for (final rule in rules) {
      if (rule.matches(hst)) {
        return rule.dosis;
      }
    }
    return null;
  }

  static double getRecommendedDosis(Commodity commodity, double hst) {
    final dosis = getDosis(commodityId: commodity.id, hst: hst.toInt());
    if (dosis != null) return dosis;
    throw Exception(
      'Tidak ada rekomendasi dosis untuk komoditas ${commodity.name} pada HST ${hst.toInt()}',
    );
  }

  static List<Commodity> getAllCommodities() {
    return commodities;
  }

  static String? getCommodityName(int id) {
    try {
      return commodities.firstWhere((c) => c.id == id).name;
    } catch (e) {
      return null;
    }
  }
}
