import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;

/// 全局卡片图片预加载队列：按入队顺序每批最多 3 张并发，
/// 完成一张才允许 Image 渲染，保证页面从前到后依次点亮。
class AssetPreloadQueue {
  AssetPreloadQueue._();
  static final AssetPreloadQueue I = AssetPreloadQueue._();

  final List<String> _queue = [];
  final Set<String> _done = {};
  final Map<String, List<VoidCallback>> _listeners = {};
  int _inFlight = 0;
  static const int _maxConcurrent = 3;
  static const int _maxQueue = 400;

  bool isDone(String path) => _done.contains(path);

  void listen(String path, VoidCallback cb) {
    if (_done.contains(path)) { cb(); return; }
    (_listeners[path] ??= []).add(cb);
    ensure(path);
  }

  void ensure(String path) {
    if (path.isEmpty || _done.contains(path) || _queue.contains(path)) return;
    if (_queue.length >= _maxQueue) return;
    _queue.add(path);
    _pump();
  }

  void _pump() {
    while (_inFlight < _maxConcurrent && _queue.isNotEmpty) {
      final p = _queue.removeAt(0);
      _inFlight++;
      _load(p);
    }
  }

  void _load(String path) {
    final provider = AssetImage(path);
    final stream = provider.resolve(ImageConfiguration.empty);
    bool finished = false;
    late ImageStreamListener listener;
    void finish() {
      if (finished) return;
      finished = true;
      stream.removeListener(listener);
      _done.add(path);
      final cbs = _listeners.remove(path) ?? const [];
      for (final cb in cbs) {
        try { cb(); } catch (_) {}
      }
      _inFlight--;
      _pump();
    }
    listener = ImageStreamListener(
      (image, sync) => finish(),
      onError: (error, stack) => finish(),
    );
    stream.addListener(listener);
  }

  void reset() {
    _queue.clear();
    _done.clear();
    _listeners.clear();
    _inFlight = 0;
  }
}

/// 顺序加载的资产图片：加载完成前显示 [placeholder]，完成后无缝显示图片。
class QueuedAssetImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Color? placeholderColor;
  final Widget Function(String path)? placeholderBuilder;

  const QueuedAssetImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.placeholderColor,
    this.placeholderBuilder,
  });

  @override
  State<QueuedAssetImage> createState() => _QueuedAssetImageState();
}

class _QueuedAssetImageState extends State<QueuedAssetImage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ready = AssetPreloadQueue.I.isDone(widget.path);
    AssetPreloadQueue.I.listen(widget.path, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void didUpdateWidget(QueuedAssetImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _ready = AssetPreloadQueue.I.isDone(widget.path);
      AssetPreloadQueue.I.listen(widget.path, () {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      if (widget.placeholderBuilder != null) return widget.placeholderBuilder!(widget.path);
      return ColoredBox(
        color: widget.placeholderColor ?? const Color(0xFF2A2A2A),
        child: const Center(child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38))),
      );
    }
    return Image.asset(widget.path, fit: widget.fit, alignment: widget.alignment,
        errorBuilder: (_, __, ___) => ColoredBox(
            color: widget.placeholderColor ?? const Color(0xFF2A2A2A)));
  }
}
