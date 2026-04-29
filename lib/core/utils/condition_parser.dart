// lib/core/utils/condition_parser.dart
//
// Parseur récursif descendant d'expressions booléennes.
//
// Grammaire :
//   expr       = or_expr
//   or_expr    = and_expr ( '||' and_expr )*
//   and_expr   = not_expr ( '&&' not_expr )*
//   not_expr   = '!' not_expr | atom
//   atom       = '(' expr ')' | comparison
//   comparison = identifier ( '==' | '!=' ) string_literal
//
// Les identifiants sont les noms des roues (peuvent contenir des espaces).
// Les valeurs sont des chaînes entre guillemets simples ou doubles.
//
// Exemples valides :
//   Race == "Elfe"
//   (Race == "Elfe" || Race == "Humain") && Classe != "Guerrier"
//   !Race == "Orc"

final class ConditionParser {
  final String _source;
  final Map<String, String?> _wheelResults;
  int _pos = 0;

  ConditionParser._({
    required String source,
    required Map<String, String?> wheelResults,
  })  : _source = source,
        _wheelResults = wheelResults;

  // ── API publique ──────────────────────────────────────────────────────────

  /// Évalue [expression] avec les [wheels] fournis (liste de (name, result)).
  /// Retourne true si la roue doit être affichée.
  /// En cas d'erreur de syntaxe, retourne true (pas de masquage silencieux).
  static bool evaluate(
    String? expression,
    List<({String name, String? result})> wheels,
  ) {
    if (expression == null || expression.trim().isEmpty) return true;
    final results = {for (final w in wheels) w.name: w.result};
    try {
      final parser = ConditionParser._(
        source: expression.trim(),
        wheelResults: results,
      );
      final result = parser._parseExpr();
      parser._skipWs();
      if (parser._pos != parser._source.length) return true; // non consommé
      return result;
    } catch (_) {
      return true;
    }
  }

  /// Valide la syntaxe sans évaluer.
  /// Retourne null si OK, sinon un message d'erreur humain.
  static String? validate(String expression) {
    if (expression.trim().isEmpty) return null;
    final parser = ConditionParser._(
      source: expression.trim(),
      wheelResults: {},
    );
    try {
      parser._parseExpr();
      parser._skipWs();
      if (parser._pos != parser._source.length) {
        return 'Expression incomplète à la position ${parser._pos}';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Règles de grammaire ───────────────────────────────────────────────────

  bool _parseExpr() => _parseOr();

  bool _parseOr() {
    var left = _parseAnd();
    while (true) {
      _skipWs();
      if (_peek('||')) {
        _pos += 2;
        left = left || _parseAnd();
      } else {
        break;
      }
    }
    return left;
  }

  bool _parseAnd() {
    var left = _parseNot();
    while (true) {
      _skipWs();
      if (_peek('&&')) {
        _pos += 2;
        left = left && _parseNot();
      } else {
        break;
      }
    }
    return left;
  }

  bool _parseNot() {
    _skipWs();
    if (_pos < _source.length &&
        _source[_pos] == '!' &&
        !(_pos + 1 < _source.length && _source[_pos + 1] == '=')) {
      _pos++;
      return !_parseNot();
    }
    return _parseAtom();
  }

  bool _parseAtom() {
    _skipWs();
    if (_pos < _source.length && _source[_pos] == '(') {
      _pos++;
      final result = _parseExpr();
      _skipWs();
      if (_pos >= _source.length || _source[_pos] != ')') {
        throw FormatException('Parenthèse fermante manquante');
      }
      _pos++;
      return result;
    }
    return _parseComparison();
  }

  bool _parseComparison() {
    _skipWs();
    final wheelName = _parseIdentifier();
    if (wheelName.isEmpty) {
      throw FormatException(
        'Identifiant de roue attendu à la position $_pos',
      );
    }
    _skipWs();

    final String op;
    if (_peek('==')) {
      op = '==';
      _pos += 2;
    } else if (_peek('!=')) {
      op = '!=';
      _pos += 2;
    } else {
      throw FormatException(
        'Opérateur == ou != attendu à la position $_pos',
      );
    }

    _skipWs();
    final value = _parseStringLiteral();
    final result = _wheelResults[wheelName];
    return op == '==' ? result == value : result != value;
  }

  // ── Primitives lexicales ──────────────────────────────────────────────────

  String _parseIdentifier() {
    final buf = StringBuffer();
    while (_pos < _source.length) {
      if (_peek('==') || _peek('!=') || _peek('&&') || _peek('||')) break;
      final ch = _source[_pos];
      if (ch == '(' || ch == ')' || ch == '!') break;
      buf.write(ch);
      _pos++;
    }
    return buf.toString().trimRight();
  }

  String _parseStringLiteral() {
    if (_pos >= _source.length) {
      throw FormatException('Chaîne littérale attendue à la position $_pos');
    }
    final quote = _source[_pos];
    if (quote != '"' && quote != "'") {
      throw FormatException('Guillemet attendu à la position $_pos');
    }
    _pos++;
    final buf = StringBuffer();
    while (_pos < _source.length && _source[_pos] != quote) {
      if (_source[_pos] == '\\' && _pos + 1 < _source.length) {
        _pos++;
        buf.write(_source[_pos]);
      } else {
        buf.write(_source[_pos]);
      }
      _pos++;
    }
    if (_pos >= _source.length) {
      throw FormatException('Guillemet fermant manquant');
    }
    _pos++;
    return buf.toString();
  }

  void _skipWs() {
    while (_pos < _source.length && _source[_pos] == ' ') {
      _pos++;
    }
  }

  bool _peek(String s) {
    if (_pos + s.length > _source.length) return false;
    return _source.substring(_pos, _pos + s.length) == s;
  }
}