{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    /* 强制使用本地 canvaskit/ 引擎（含 skwasm），避免从 gstatic CDN 动态 import（国内/受限网络会失败导致白屏） */
    canvasKitBaseUrl: "canvaskit"
  }
});
