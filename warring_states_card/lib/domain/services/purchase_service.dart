import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

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
      if (!_initialized) return false;
      _sub = _iap.purchaseStream.listen((events) {
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
            final receipt = e.verificationData.serverVerificationData;
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
      _products
        ..clear()
        ..addAll(resp.productDetails);
      return resp.productDetails;
    } catch (_) {
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
      sub = _iap.purchaseStream.listen((events) {
        for (final e in events) {
          if (e.productID == productId) {
            if (e.status == PurchaseStatus.purchased || e.status == PurchaseStatus.restored) {
              final receipt = e.verificationData.serverVerificationData;
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
}
