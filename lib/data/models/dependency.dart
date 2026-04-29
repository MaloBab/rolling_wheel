// lib/data/models/dependency.dart

/// Dépendance de poids entre deux roues.
///
/// Quand la roue [sourceWheelId] donne un résultat, les poids des options
/// de la roue cible sont remplacés par la matrice [weights].
///
/// Structure : weights[sourceOptionId][targetOptionId] = double
final class Dependency {
  final String sourceWheelId;
  final Map<String, Map<String, double>> weights;

  const Dependency({
    required this.sourceWheelId,
    required this.weights,
  });

  Dependency copyWith({
    String? sourceWheelId,
    Map<String, Map<String, double>>? weights,
  }) =>
      Dependency(
        sourceWheelId: sourceWheelId ?? this.sourceWheelId,
        weights: weights ?? this.weights,
      );

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