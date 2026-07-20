import 'package:flutter/material.dart';
import '../../domain/models/roguelite_run.dart';

/// 路径图 — 竖向滚动的 Roguelite 节点选择
class PathMap extends StatelessWidget {

  const PathMap({super.key, required this.run, required this.onNodeTap});
  final RogueliteRun run;
  final void Function(RogueliteNode) onNodeTap;

  static const _gold = Color(0xFFB8860B);
  static const _parch = Color(0xFFE8D5B7);

  Color _nodeColor(RogueliteNodeType type, bool acc) {
    if (!acc) return Colors.grey;
    return switch (type) {
      RogueliteNodeType.battle => const Color(0xFFC0392B),
      RogueliteNodeType.boss => const Color(0xFFFF4500),
      RogueliteNodeType.rest => const Color(0xFF27AE60),
      RogueliteNodeType.shop => const Color(0xFF8E44AD),
    };
  }

  Widget _nodeIcon(RogueliteNodeType type, Color c) {
    final m = <RogueliteNodeType, IconData>{
      RogueliteNodeType.battle: Icons.shield,
      RogueliteNodeType.boss: Icons.local_fire_department,
      RogueliteNodeType.rest: Icons.hotel_class,
      RogueliteNodeType.shop: Icons.store,
    };
    return Icon(m[type] ?? Icons.circle, color: c, size: 22);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: run.layers.length,
      itemBuilder: (_, li) {
        final nodes = run.layers[li];
        final isCur = li <= run.currentLayer + 1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: nodes.map((node) {
              final acc = run.canAccessNode(node) && run.isActive;
              final sel = node.id == run.currentNodeId;
              final c = _nodeColor(node.type, acc);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(
                  onTap: acc ? () => onNodeTap(node) : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: acc ? LinearGradient(
                            colors: [c.withAlpha(180), c.withAlpha(80)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ) : null,
                          color: acc ? null : Colors.grey.withAlpha(30),
                          border: Border.all(
                            color: sel ? _gold : c.withAlpha(acc ? 200 : 60),
                            width: sel ? 3 : 2,
                          ),
                          boxShadow: sel
                              ? [BoxShadow(color: _gold.withAlpha(120), blurRadius: 14)]
                              : (acc ? [BoxShadow(color: c.withAlpha(50), blurRadius: 6)] : null),
                        ),
                        child: _nodeIcon(node.type, acc ? Colors.white : Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 72,
                        child: Text(node.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: sel ? _gold : (acc ? _parch : Colors.grey),
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}