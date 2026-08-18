// Web 专属：页内嵌 Adsterra 原生横幅（zone 30760823）。
//
// 通过 HtmlElementView 将 Adsterra 的 DOM 广告容器嵌入 Flutter 页面。
// 插槽高度自适应广告实际渲染高度：广告填充后经 MutationObserver 把真实
// 高度发布到 window，Flutter 侧轮询读取并调整插槽高度，宽度始终填满父级。
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'ad_slot_scope.dart';

const String _adBannerViewType = 'adsterra-banner-slot';

// Adsterra 原生横幅（zone 30760823）的注入脚本与容器 id。
const String _nativeBannerScript =
    'https://pl30861322.effectivecpmnetwork.com/2cbc3e5f4588b232019879b4813fbe28/invoke.js';
const String _nativeBannerContainerId = 'container-2cbc3e5f4588b232019879b4813fbe28';

// 广告实际渲染高度存于全局（window），供 Flutter 侧轮询读取以自适应插槽高度。
const String _adHeightKey = '__zgAdH';
// 初始兜底高度：广告尚未渲染时占位，避免塌陷。
const double _defaultHeight = 90;

bool _registered = false;

void _ensureRegistered() {
  if (_registered) return;
  _registered = true;
  // 每次创建视图时返回一个新的 div，并把 Adsterra 原生横幅脚本注入其中。
  ui_web.platformViewRegistry.registerViewFactory(
    _adBannerViewType,
    (int viewId) {
      final wrapper = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.background = 'rgba(0,0,0,0.35)'
        ..style.overflow = 'hidden';
      final container = web.HTMLDivElement()
        ..id = _nativeBannerContainerId
        ..style.width = '100%'
        // 高度不写死：由 Adsterra 横幅素材自然决定，Flutter 侧据此自适应。
        ..style.height = 'auto'
        ..style.margin = '0 auto';
      // 让横幅素材尽量拉伸填充容器宽度（响应式横幅会据此填满整行）。
      final styleEl = web.HTMLStyleElement()
        ..textContent = '#$_nativeBannerContainerId iframe{'
            'display:block;margin:0 auto;max-width:100%!important}';
      wrapper.append(styleEl);
      wrapper.append(container);
      // 注入 Adsterra 原生横幅脚本（每次新视图都会重新拉取并渲染）。
      final script = web.HTMLScriptElement()
        ..async = true
        ..type = 'text/javascript'
        ..src = _nativeBannerScript;
      wrapper.append(script);
      // 广告渲染后测量真实高度并写入 window，驱动 Flutter 自适应插槽高度。
      final observer = web.MutationObserver(
        ((JSArray<web.MutationRecord> records, web.MutationObserver obs) {
          _publishAdHeight();
        }).toJS,
      );
      observer.observe(
        container,
        web.MutationObserverInit(
          childList: true,
          subtree: true,
        ),
      );
      // 脚本 onload 后也可能有延迟布局，测一次。
      script.onload = ((web.Event _) {
        web.window.setTimeout((() => _publishAdHeight()).toJS, null, 400);
      }).toJS;
      return wrapper;
    },
  );
}

/// 把容器当前实际高度发布到全局，供 Dart 侧轮询读取。
void _publishAdHeight() {
  if (web.document.body == null) return;
  final c = web.document.getElementById(_nativeBannerContainerId);
  if (c == null) return;
  var h = (c as web.HTMLElement).clientHeight;
  // 若容器高度为 0（广告尚未撑开），尝试取首个 iframe 的高度。
  if (h <= 0) {
    final ifr = c.querySelector('iframe') as web.HTMLElement?;
    if (ifr != null) h = ifr.clientHeight;
  }
  if (h > 0) {
    globalContext.setProperty(_adHeightKey.toJS, h.toJS);
  }
}

/// 页内嵌横幅插槽（Web 版，真实广告）。
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  double _height = _defaultHeight;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ensureRegistered();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 仅当本插槽可见（当前唯一挂载广告的页面）时才轮询高度；
    // 隐藏占位时不轮询、不 setState，避免常驻计时器浪费。
    final visible = adSlotVisible(context);
    if (visible && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        final v =
            globalContext.getProperty<JSNumber?>(_adHeightKey.toJS)?.toDartDouble;
        if (v != null && v > 0) {
          final h = v.toDouble();
          if ((h - _height).abs() > 1) {
            setState(() => _height = h);
          }
        }
      });
    } else if (!visible && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 同一时刻只让可见页面的插槽挂载广告 DOM：IndexedStack 同时挂载 4 个 Tab，
    // 每页都创建同一 Adsterra 容器 id 会互抢同 zone，导致只有首页能加载出广告。
    // 其余插槽渲染等尺寸占位，切换页面时自动重新挂载。
    if (!adSlotVisible(context)) {
      return const SizedBox(width: double.infinity, height: _defaultHeight);
    }
    return SizedBox(
      width: double.infinity,
      height: _height,
      child: const HtmlElementView(viewType: _adBannerViewType),
    );
  }
}