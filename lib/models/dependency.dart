// lib/models/dependency.dart

/// Représente une dépendance entre deux roues d'un même groupe.
///
/// Quand la roue [sourceWheelId] donne un résultat, les poids des options
/// de la roue cible sont remplacés par la matrice [weights].
///
/// Structure de [weights]:
///   { sourceOptionId: { targetOptionId: double } }
///
/// Exemple: si la roue "Classe" tombe sur "Guerrier" (id: "abc"),
/// alors dans la roue "Arme", "Épée" (id: "xyz") aura un poids de 5.0.
class Dependency {
  final String sourceWheelId;

  /// weights[sourceOptionId][targetOptionId] = double
  final Map<String, Map<String, double>> weights;

  const Dependency({
    required this.sourceWheelId,
    required this.weights,
  });

  Dependency copyWith({
    String? sourceWheelId,
    Map<String, Map<String, double>>? weights,
  }) {
    return Dependency(
      sourceWheelId: sourceWheelId ?? this.sourceWheelId,
      weights: weights ?? this.weights,
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceWheelId': sourceWheelId,
        'weights': weights.map(
          (k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2, v2))),
        ),
      };

  factory Dependency.fromJson(Map<String, dynamic> json) {
    final rawWeights = json['weights'] as Map<String, dynamic>? ?? {};
    final weights = rawWeights.map(
      (srcId, tgtMap) => MapEntry(
        srcId,
        (tgtMap as Map<String, dynamic>).map(
          (tgtId, val) => MapEntry(tgtId, (val as num).toDouble()),
        ),
      ),
    );
    return Dependency(
      sourceWheelId: json['sourceWheelId'] as String,
      weights: weights,
    );
  }
}