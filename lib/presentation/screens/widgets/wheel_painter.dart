// lib/widgets/wheel_painter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';

class WheelPainter extends CustomPainter {
  final SpinWheel wheel;
  final List<SpinWheel> allWheels;
  final double rotationAngle; // radians

  WheelPainter({
    required this.wheel,
    required this.allWheels,
    this.rotationAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 4;

    final effectiveWeights = wheel.effectiveWeights(allWheels);
    final activeOpts = wheel.options.where((o) => (effectiveWeights[o.id] ?? 0) > 0).toList();

    if (activeOpts.isEmpty) {
      _drawEmpty(canvas, cx, cy, radius);
      return;
    }

    // Calcul des couleurs (dégradé ou couleurs individuelles)
    final gradientColors = wheel.gradientColors();
    Color optColor(WheelOption opt) =>
        gradientColors.isNotEmpty ? (gradientColors[opt.id] ?? opt.color) : opt.color;

    final total = activeOpts.fold(0.0, (s, o) => s + (effectiveWeights[o.id] ?? 0));
    double startAngle = rotationAngle - math.pi / 2;

    for (final opt in activeOpts) {
      final w = effectiveWeights[opt.id] ?? 0;
      final sweep = (w / total) * math.pi * 2;
      final color = optColor(opt);

      // Segment coloré
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweep,
        true,
        fillPaint,
      );

      // Bordure
      final strokePaint = Paint()
        ..color = Colors.black.withAlpha(76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweep,
        true,
        strokePaint,
      );

      // Label – adaptatif : taille de police et longueur selon arc disponible
      final midAngle = startAngle + sweep / 2;
      // Position sur 62% du rayon (zone lisible entre centre et bord)
      final labelRadius = radius * 0.62;
      final lx = cx + labelRadius * math.cos(midAngle);
      final ly = cy + labelRadius * math.sin(midAngle);

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(midAngle + math.pi / 2);

      // Longueur de l'arc disponible à mi-rayon (zone de texte)
      final arcLength = sweep * labelRadius;
      // Hauteur disponible dans le segment (le long du rayon)
      final segHeight = radius * 0.55;

      // Taille de police : s'adapte à l'arc disponible
      // On vise ~6px par caractère de largeur → on calcule combien tient dans arcLength
      double fontSize = (arcLength / 7.0).clamp(7.0, 15.0);

      // Contraste adaptatif
      final luminance = color.computeLuminance();
      final textColor = luminance > 0.4
          ? Colors.black.withAlpha(204)
          : Colors.white.withAlpha(230);

      // Combien de caractères tiennent sur une ligne à cette taille ?
      final charsPerLine = (arcLength / (fontSize * 0.62)).floor().clamp(3, 40);
      // Combien de lignes tiennent en hauteur ?
      final maxLines = (segHeight / (fontSize * 1.3)).floor().clamp(1, 4);

      // Découper le label en lignes en respectant les mots
      final words = opt.name.split(' ');
      final lines = <String>[];
      var current = '';
      for (final word in words) {
        final test = current.isEmpty ? word : '$current $word';
        if (test.length <= charsPerLine) {
          current = test;
        } else {
          if (current.isNotEmpty) lines.add(current);
          // Si le mot seul est trop long, on le tronque
          current = word.length > charsPerLine
              ? '${word.substring(0, charsPerLine - 1)}…'
              : word;
        }
        if (lines.length >= maxLines) break;
      }
      if (current.isNotEmpty && lines.length < maxLines) lines.add(current);
      // Si on a débordé, tronquer la dernière ligne
      if (lines.isNotEmpty && lines.length == maxLines && current != lines.last) {
        final last = lines.last;
        if (last.length > 2) lines[lines.length - 1] = '${last.substring(0, last.length - 1)}…';
      }
      final labelText = lines.join('\n');

      final tp = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            fontFamily: 'DM Sans',
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: maxLines,
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();

      startAngle += sweep;
    }

    // Cercle central
    final centerPaint = Paint()
      ..color = const Color(0xFF0D0E14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 22, centerPaint);

    final centerBorderPaint = Paint()
      ..color = const Color(0xFF7C6FF7).withAlpha(153)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 22, centerBorderPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF7C6FF7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 8, dotPaint);
  }

  void _drawEmpty(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF1C1D2B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, paint);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Aucune option',
        style: TextStyle(color: Color(0xFF5A5878), fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.rotationAngle != rotationAngle ||
      oldDelegate.wheel != wheel;
}

// ──────────────────────────────────────────────
// Widget complet: roue + pointeur + animation
// ──────────────────────────────────────────────

class SpinWheelWidget extends StatefulWidget {
  final SpinWheel wheel;
  final List<SpinWheel> allWheels;
  final double size;
  final void Function(WheelOption winner)? onResult;

  const SpinWheelWidget({
    super.key,
    required this.wheel,
    required this.allWheels,
    this.size = 320,
    this.onResult,
  });

  @override
  State<SpinWheelWidget> createState() => SpinWheelWidgetState();
}

class SpinWheelWidgetState extends State<SpinWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _currentAngle = 0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addListener(() {
      setState(() => _currentAngle = _anim.value);
    });
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _spinning = false;
        _announceResult();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get isSpinning => _spinning;

  void spin() {
    if (_spinning) return;
    final opts = widget.wheel.options;
    if (opts.isEmpty) return;

    _spinning = true;
    final extra = math.pi * 2 * (6 + math.Random().nextDouble() * 4);
    final target = _currentAngle + extra;

    final duration = Duration(milliseconds: (3000 + math.Random().nextInt(1500)).toInt());

    _anim = Tween<double>(begin: _currentAngle, end: target).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.duration = duration;
    _ctrl.forward(from: 0);
  }

  void _announceResult() {
    final effectiveWeights = widget.wheel.effectiveWeights(widget.allWheels);
    final activeOpts = widget.wheel.options
        .where((o) => (effectiveWeights[o.id] ?? 0) > 0)
        .toList();
    if (activeOpts.isEmpty) return;

    final total = activeOpts.fold(0.0, (s, o) => s + (effectiveWeights[o.id] ?? 0));
    // Angle normalisé dans [0, 2π]
    final finalAngle = _currentAngle % (math.pi * 2);
    // Le pointeur est en haut (−π/2). On cherche l'option sous le pointeur.
    final pointer = ((math.pi * 2) - finalAngle) % (math.pi * 2);

    double cum = 0;
    WheelOption? winner;
    for (final opt in activeOpts) {
      final w = effectiveWeights[opt.id] ?? 0;
      cum += (w / total) * math.pi * 2;
      if (pointer < cum) {
        winner = opt;
        break;
      }
    }
    winner ??= activeOpts.last;
    widget.onResult?.call(winner);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Pointeur
          Positioned(
            top: 0,
            child: _PointerArrow(),
          ),
          // Roue
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CustomPaint(
              size: Size(widget.size - 32, widget.size - 32),
              painter: WheelPainter(
                wheel: widget.wheel,
                allWheels: widget.allWheels,
                rotationAngle: _currentAngle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointerArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 32),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF7C16F)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);

    final shadow = Paint()
      ..color = const Color(0xFFF7C16F).withAlpha(102)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, shadow);
  }

  @override
  bool shouldRepaint(_) => false;
}