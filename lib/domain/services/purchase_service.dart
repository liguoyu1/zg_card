import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart'
    show InAppPurchasePlatformAddition;
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

/// 购买结果 — 携带收据数据供后端验证
class PurchaseResult {
  final bool success;
  final String? receipt;       // serverVerificationData
  final String? transactionId;
  final String? productId;
  final String? error;

  const PurchaseResult({
    required this.success,
    this.receipt,
    this.transactionId,
    this.productId,
    this.error,
  });
}

/// 内购服务 — Apple StoreKit / Google Play Billing
/// 无 mock 路径，无伪成功返回
class PurchaseService {
  PurchaseService._();
  static final PurchaseService _instance = PurchaseService._();
  static PurchaseService get I => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Set<String> _purchasedIds = {};
  final List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  final _restoredController = StreamController<PurchaseResult>.broadcast();
  Stream<PurchaseResult> get restoredStream => _restoredController.stream;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<bool> initialize() async {
    if (_initialized || kIsWeb) return false;
    try {
      _initialized = await _iap.isAvailable();
      debugPrint('🔵 IAP isAvailable: $_initialized');
      if (!_initialized) return false;
      _sub = _iap.purchaseStream.listen((events) async {
        for (final e in events) {
          if (e.status == PurchaseStatus.purchased) {
            // Fresh purchase — handled directly by purchase(). Do NOT emit
            // to restoredStream (that would trigger the restore listener &
            // double-credit gems).
            _purchasedIds.add(e.productID);
            if (e.pendingCompletePurchase) {
              _iap.completePurchase(e);
            }
          } else if (e.status == PurchaseStatus.restored) {
            // Restored purchase — emit receipt data so consumer uploads to
            // backend for server-side verification & crediting.
            _purchasedIds.add(e.productID);
            final receipt = await _serverReceipt(e.verificationData.serverVerificationData);
            _restoredController.add(PurchaseResult(
              success: true,
              receipt: receipt.isNotEmpty ? receipt : null,
              transactionId: e.purchaseID,
              productId: e.productID,
            ));
            if (e.pendingCompletePurchase) {
              _iap.completePurchase(e);
            }
          } else if (e.status == PurchaseStatus.error) {
            _restoredController.add(PurchaseResult(
              success: false,
              error: e.error?.message ?? '恢复购买错误',
            ));
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (kIsWeb || !_initialized) return [];
    try {
      const ids = <String>{'gem_60', 'gem_300', 'gem_600', 'gem_1500', 'gem_3000'};
      final resp = await _iap.queryProductDetails(ids);
      debugPrint('🔵 IAP queryProductDetails: got ${resp.productDetails.length}/${ids.length}');
      debugPrint('🔵 IAP error: ${resp.error}');
      _products
        ..clear()
        ..addAll(resp.productDetails);
      return resp.productDetails;
    } catch (e) {
      debugPrint('🔴 IAP loadProducts exception: $e');
      return [];
    }
  }

  Future<bool> ensureReady() async {
    if (kIsWeb) return false;
    if (!_initialized && !await initialize()) return false;
    if (_products.isEmpty) await loadProducts();
    return _products.isNotEmpty;
  }

  /// 购买 — 真实 StoreKit 流程，无 mock 路径
  Future<PurchaseResult> purchase(String productId) async {
    if (!await ensureReady()) {
      return PurchaseResult(
        success: false,
        productId: productId,
        error: 'IAP 商品加载失败，请检查 StoreKit 配置或 App Store Connect 商品状态',
      );
    }

    try {
      var detail = _products.where((p) => p.id == productId).firstOrNull;
      if (detail == null) {
        final resp = await _iap.queryProductDetails({productId});
        detail = resp.productDetails.where((p) => p.id == productId).firstOrNull;
      }
      if (detail == null) {
        return PurchaseResult(success: false, productId: productId, error: '商品不可用');
      }

      final completer = Completer<PurchaseResult>();
      StreamSubscription<List<PurchaseDetails>>? sub;
      sub = _iap.purchaseStream.listen((events) async {
        for (final e in events) {
          if (e.productID == productId) {
            if (e.status == PurchaseStatus.purchased || e.status == PurchaseStatus.restored) {
              final receipt = await _serverReceipt(e.verificationData.serverVerificationData);
              if (e.pendingCompletePurchase) _iap.completePurchase(e);
              completer.complete(PurchaseResult(
                success: true,
                receipt: receipt.isNotEmpty ? receipt : null,
                transactionId: e.purchaseID,
                productId: productId,
              ));
            } else if (e.status == PurchaseStatus.error) {
              completer.complete(PurchaseResult(
                success: false,
                productId: productId,
                error: e.error?.message ?? '支付失败',
              ));
            }
            sub?.cancel();
            return;
          }
        }
      });

      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: detail),
      );

      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          sub?.cancel();
          return PurchaseResult(success: false, productId: productId, error: '支付超时');
        },
      );
    } catch (e) {
      return PurchaseResult(success: false, productId: productId, error: e.toString());
    }
  }

  bool isPurchased(String productId) => _purchasedIds.contains(productId);

  Future<bool> restorePurchases() async {
    if (kIsWeb || !_initialized) return false;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _initialized = false;
    _products.clear();
  }

  /// StoreKit 2 下 serverVerificationData 是 JWS 交易签名，不是 App Store receipt，
  /// 直接发给服务端 verifyReceipt 会返回 21002。iOS 上先刷新出传统 base64 receipt。
  static bool _isJws(String s) => s.split('.').length == 3;

  static Future<String?> _appStoreReceipt() async {
    if (kIsWeb || !Platform.isIOS) return null;
    final addition = InAppPurchasePlatformAddition.instance;
    if (addition is! InAppPurchaseStoreKitPlatformAddition) return null;
    try {
      final vd = await addition.refreshPurchaseVerificationData();
      final receipt = vd?.serverVerificationData ?? '';
      return receipt.isNotEmpty ? receipt : null;
    } catch (e) {
      debugPrint('🔴 IAP receipt refresh failed: $e');
      return null;
    }
  }

  /// 组装可上传的 receipt：SK2(JWS) 时先取传统 receipt，取不到则回退 JWS 原样上传。
  static Future<String> _serverReceipt(String serverVerificationData) async {
    if (!kIsWeb && Platform.isIOS && _isJws(serverVerificationData)) {
      final legacy = await _appStoreReceipt();
      if (legacy != null) return legacy;
    }
    return serverVerificationData;
  }
}
