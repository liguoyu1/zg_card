import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/roguelite_run.dart';
import '../../l10n/locale_service.dart';

/// 路径图 — 竖向滚动的 Roguelite 节点选择
class PathMap extends StatelessWidget {
  final RogueliteRun run;
  final void Function(RogueliteNode) onNodeTap;

  const PathMap({super.key, required this.run, required this.onNodeTap});

  static const _goldAccent = Color(0xFFB8860B);
  static const _parchment = Color(0xFFE8D5B7);

  Color _nodeColor(RogueliteNodeType type, bool accessible) {
    if (!accessible) return Colors.grey;
    switch (type) {
      case RogueliteNodeType.battle: return const Color(0xFF4CAF50);
      case RogueliteNodeType.boss: return const Color(0xFFF44336);
      case RogueliteNodeType.rest: return const Color(0xFF2196F3);
      case RogueliteNodeType.shop: return const Color(0xFF9C27B0);
    }
  }

  IconData _nodeIcon(RogueliteNodeType type) {
    switch (type) {
      case RogueliteNodeType.battle: return Icons.shield;
      case RogueliteNodeType.boss: return Icons.whatshot;
      case RogueliteNodeType.rest: return Icons.local_hospital;
      case RogueliteNodeType.shop: return Icons.shopping_cart;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(run.layers.length),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: run.layers.length,
        itemBuilder: (_, layerIdx) {
          final nodes = run.layers[layerIdx];
          final isCurrentLayer = layerIdx <= run.currentLayer + 1;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: nodes.map((node) {
                final accessible = run.canAccessNode(node) && run.isActive;
                final isSelected = node.id == run.currentNodeId;
                final color = _nodeColor(node.type, accessible);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: accessible ? () => onNodeTap(node) : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accessible ? color.withAlpha(40) : Colors.grey.withAlpha(30),
                            border: Border.all(
                              color: isSelected ? _goldAccent : color.withAlpha(accessible ? 180 : 60),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: _goldAccent.withAlpha(100), blurRadius: 12)]
                                : null,
                          ),
                          child: Icon(
                            _nodeIcon(node.type),
                            color: accessible ? color : Colors.grey,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            node.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? _goldAccent
                                  : (accessible ? _parchment : Colors.grey),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _goldAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(LocaleService.I.t('roguelite.current'),
                                style: const TextStyle(color: _goldAccent, fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// 连线绘制
class _LinePainter extends CustomPainter {
  final int layerCount;
  _LinePainter(this.layerCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8860B).withAlpha(60)
      ..strokeWidth = 2;

    for (var i = 0; i < layerCount - 1; i++) {
      final y1 = i * 88.0 + 56;
      final y2 = (i + 1) * 88.0 + 56;
      canvas.drawLine(Offset(size.width * 0.3, y1), Offset(size.width * 0.3, y2), paint);
      canvas.drawLine(Offset(size.width * 0.5, y1), Offset(size.width * 0.5, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
