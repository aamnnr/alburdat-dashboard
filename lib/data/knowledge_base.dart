import 'package:alburdat_dashboard/models/commodity.dart';
import 'package:alburdat_dashboard/models/fertilizer.dart';
import 'package:alburdat_dashboard/models/rule.dart';

/// ========================
/// FERTILIZER MASTER DATA
/// ========================
const fertilizers = [
  Fertilizer(id: 1, name: 'NPK'),
  Fertilizer(id: 2, name: 'Urea'),
];

/// multiplier pupuk
const fertilizerMultipliers = {
  1: 1.0,
  2: 0.7,
};

/// ========================
/// COMMODITY + JARAK TANAM
/// ========================
const List<Commodity> commodities = [
  Commodity(id: 1, name: 'Jagung', jarakTanam: 0.7),
  Commodity(id: 2, name: 'Cabai Merah', jarakTanam: 0.5),
  Commodity(id: 3, name: 'Kentang', jarakTanam: 0.4),
  Commodity(id: 4, name: 'Alpukat', jarakTanam: 5.0),
  Commodity(id: 5, name: 'Buah Naga', jarakTanam: 3.0),
  Commodity(id: 6, name: 'Durian', jarakTanam: 8.0),
  Commodity(id: 7, name: 'Kakao', jarakTanam: 3.0),
  Commodity(id: 8, name: 'Karet', jarakTanam: 6.0),
  Commodity(id: 9, name: 'Sawit', jarakTanam: 9.0),
  Commodity(id: 10, name: 'Kopi', jarakTanam: 2.0),
  Commodity(id: 11, name: 'Pala', jarakTanam: 6.0),
  Commodity(id: 12, name: 'Pisang', jarakTanam: 3.0),
  Commodity(id: 13, name: 'Tebu', jarakTanam: 1.2),
];

const Map<int, List<Rule>> knowledgeBase = {
  1: [
    Rule(minHst: 0, maxHst: 20, dosis: 3.6),
    Rule(minHst: 21, maxHst: double.infinity, dosis: 2.9),
  ],
  2: [
    Rule(minHst: 0, maxHst: double.infinity, dosis: 2.9),
  ],
  3: [
    Rule(minHst: 0, maxHst: 20, dosis: 6.0),
    Rule(minHst: 21, maxHst: double.infinity, dosis: 2.4),
  ],
  4: [
    Rule(minHst: 0, maxHst: 90, dosis: 80.0),
    Rule(minHst: 91, maxHst: 180, dosis: 315.0),
    Rule(minHst: 181, maxHst: double.infinity, dosis: 1325.0),
  ],
  5: [
    Rule(minHst: 0, maxHst: double.infinity, dosis: 15.0),
  ],
  6: [
    Rule(minHst: 0, maxHst: 720, dosis: 200.0),
    Rule(minHst: 721, maxHst: 1440, dosis: 400.0),
    Rule(minHst: 1441, maxHst: 2880, dosis: 600.0),
    Rule(minHst: 2881, maxHst: double.infinity, dosis: 850.0),
  ],
  7: [
    Rule(minHst: 0, maxHst: 360, dosis: 25.0),
    Rule(minHst: 361, maxHst: 720, dosis: 45.0),
    Rule(minHst: 721, maxHst: 1080, dosis: 90.0),
    Rule(minHst: 1081, maxHst: 1440, dosis: 180.0),
    Rule(minHst: 1441, maxHst: double.infinity, dosis: 220.0),
  ],

  // ========================
  // TAMBAHAN (8–13)
  // ========================

  8: [ // Karet
    Rule(minHst: 0, maxHst: 1080, dosis: 250.0),
    Rule(minHst: 1081, maxHst: 1440, dosis: 300.0),
    Rule(minHst: 1441, maxHst: 1800, dosis: 350.0),
    Rule(minHst: 1801, maxHst: double.infinity, dosis: 200.0),
  ],
  9: [ // Sawit
    Rule(minHst: 0, maxHst: 30, dosis: 100.0),
    Rule(minHst: 31, maxHst: 240, dosis: 150.0),
    Rule(minHst: 241, maxHst: double.infinity, dosis: 200.0),
  ],
  10: [ // Kopi
    Rule(minHst: 0, maxHst: 14, dosis: 106.0),
    Rule(minHst: 15, maxHst: 120, dosis: 80.0),
    Rule(minHst: 121, maxHst: 210, dosis: 53.0),
    Rule(minHst: 211, maxHst: 330, dosis: 26.0),
    Rule(minHst: 331, maxHst: double.infinity, dosis: 20.0),
  ],
  11: [ // Pala
    Rule(minHst: 0, maxHst: 720, dosis: 20.0),
    Rule(minHst: 721, maxHst: 1440, dosis: 40.0),
    Rule(minHst: 1441, maxHst: 2520, dosis: 80.0),
    Rule(minHst: 2521, maxHst: 5400, dosis: 100.0),
    Rule(minHst: 5401, maxHst: double.infinity, dosis: 120.0),
  ],
  12: [ // Pisang
    Rule(minHst: 0, maxHst: 167, dosis: 100.0),
    Rule(minHst: 168, maxHst: double.infinity, dosis: 150.0),
  ],
  13: [ // Tebu
    Rule(minHst: 0, maxHst: double.infinity, dosis: 3.75),
  ],
};