import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

/// 内购产品定义
class Product {
  final String id;
  final String title;
  final String description;
  final double price;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });
}

/// 内购服务 — 封装 RevenueCat
class PurchaseService {
  PurchaseService._();
  static final PurchaseService _instance = PurchaseService._();
  static PurchaseService get I => _instance;

  bool _initialized = false;
  final Set<String> _purchasedIds = {};
  bool get isInitialized => _initialized;

  // 替换为 RevenueCat 控制台中的 API Key
  static const String _apiKeyAndroid = 'goog_XXXXXXXXXXXXXXXXXXXX';
  static const String _apiKeyIOS = 'appl_XXXXXXXXXXXXXXXXXXXX';

  String _userId = '';
  String get userId => _userId;

  List<Product> _products = [];
  List<Product> get products => _products;

  /// 初始化 RevenueCat
  Future<bool> initialize({String? userId}) async {
    if (_initialized) return true;
    try {
      _userId = userId ?? '';
      await Purchases.setup(
        Platform.isIOS ? _apiKeyIOS : _apiKeyAndroid,
        appUserId: _userId.isEmpty ? null : _userId,
      );
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 加载商品列表
  Future<List<Product>> loadProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];

      _products = current.availablePackages.map((pkg) => Product(
        id: pkg.identifier,
        title: pkg.storeProduct.title,
        description: pkg.storeProduct.description,
        price: pkg.storeProduct.price,
      )).toList();
      return _products;
    } catch (_) {
      return [];
    }
  }

  /// 购买商品
  Future<bool> purchase(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;

      final pkg = current.availablePackages.where(
        (p) => p.identifier == productId,
      ).firstOrNull;
      if (pkg == null) return false;

      final result = await Purchases.purchasePackage(pkg);
      final success = result.customerInfo.entitlements.active.isNotEmpty;
      if (success) _purchasedIds.add(productId);
      return success;
    } catch (_) {
      return false;
    }
  }

  /// 检查产品是否已购买（简化版：用本地缓存标记）
  bool isPurchased(String productId) => _purchasedIds.contains(productId);

  /// 恢复购买
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _initialized = false;
    _products = [];
  }
}
