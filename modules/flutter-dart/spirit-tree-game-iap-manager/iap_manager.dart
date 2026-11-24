import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/platform_utils.dart';
import '../providers.dart';

const productIdRemoveAds = 'remove_ads_permanent';
const productIdDewdrops100 = 'dewdrops_100';
const productIdDewdrops550 = 'dewdrops_550';
const productIdDewdrops1200 = 'dewdrops_1200';
const productIdDewdrops3000 = 'dewdrops_3000';

class IAPManager {
  IAPManager(this.ref);

  final Ref ref;
  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _isInitializing = false;
  final Map<String, ProductDetails> _productCache = {};
  final Set<String> _handledPurchaseIds = {};

  Future<void> initialize() async {
    if (_isInitializing) return;
    if (!PlatformUtils.supportsInAppPurchase) {
      if (kDebugMode) {
        debugPrint('IAP: Platform does not support IAP');
      }
      _isAvailable = false;
      return;
    }

    try {
      _iap ??= InAppPurchase.instance;
      if (kDebugMode) {
        debugPrint('IAP: Instance created');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('IAP not supported on this platform: $error');
      }
      _isAvailable = false;
      return;
    }

    _isInitializing = true;
    _isAvailable = await _iap!.isAvailable();
    
    if (kDebugMode) {
      debugPrint('IAP: Available = $_isAvailable');
    }

    if (!_isAvailable) {
      if (kDebugMode) {
        debugPrint('IAP: Service not available. Make sure app is uploaded to Play Store or using test account.');
      }
      _isInitializing = false;
      return;
    }

    await _queryProducts();
    _subscription ??=
        _iap!.purchaseStream.listen(_onPurchaseUpdate, onError: (Object error) {
      if (kDebugMode) {
        debugPrint('IAP purchaseStream error: $error');
      }
    });
    try {
      await _iap!.restorePurchases();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('IAP restore failed: $error');
      }
    }
    _isInitializing = false;
    
    if (kDebugMode) {
      debugPrint('IAP: Initialization complete. Products cached: ${_productCache.length}');
    }
  }

  bool get isAvailable => _isAvailable;

  ProductDetails? getProduct(String productId) => _productCache[productId];

  Future<void> refreshProducts() async => _queryProducts();

  Future<void> buyProduct(ProductDetails product) async {
    if (!_isAvailable || _iap == null) {
      if (kDebugMode) {
        debugPrint('IAP: Cannot buy product - IAP not available');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('IAP: Attempting to buy product: ${product.id}');
    }
    
    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      if (product.id == productIdRemoveAds) {
        await _iap!.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap!
            .buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
      }
      if (kDebugMode) {
        debugPrint('IAP: Purchase initiated for ${product.id}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('IAP: Purchase failed: $error');
      }
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable || _iap == null) return;
    await _iap!.restorePurchases();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _queryProducts() async {
    final ids = {
      productIdRemoveAds,
      productIdDewdrops100,
      productIdDewdrops550,
      productIdDewdrops1200,
      productIdDewdrops3000,
    };
    if (_iap == null) return;
    final response = await _iap!.queryProductDetails(ids);
    if (response.error != null) {
      if (kDebugMode) {
        debugPrint('IAP query error: ${response.error}');
        debugPrint('IAP error code: ${response.error!.code}');
        debugPrint('IAP error message: ${response.error!.message}');
        debugPrint('IAP error details: ${response.error!.details}');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint('IAP: Found ${response.productDetails.length} products');
      for (final product in response.productDetails) {
        debugPrint('IAP: Product ${product.id} - ${product.title} - ${product.price}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: Not found products: ${response.notFoundIDs}');
      }
    }
    for (final product in response.productDetails) {
      _productCache[product.id] = product;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      var canComplete = true;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          canComplete = await _deliverProduct(purchase);
          break;
        case PurchaseStatus.error:
          if (kDebugMode) {
            debugPrint('Purchase error: ${purchase.error}');
          }
          break;
        case PurchaseStatus.pending:
          canComplete = false;
          break;
        case PurchaseStatus.canceled:
          break;
      }

      if (canComplete && purchase.pendingCompletePurchase && _iap != null) {
        await _iap!.completePurchase(purchase);
      }
    }
  }

  Future<bool> _deliverProduct(PurchaseDetails details) async {
    final isConsumable = details.productID != productIdRemoveAds;
    if (isConsumable && details.status != PurchaseStatus.purchased) {
      return true;
    }
    final key = _purchaseKey(details);
    final notifier = ref.read(gameProvider.notifier);
    if (key.isNotEmpty &&
        (notifier.hasPurchase(key) || !_handledPurchaseIds.add(key))) {
      return true;
    }

    final before = ref.read(gameProvider);
    if (key.isNotEmpty) notifier.rememberPurchase(key);
    switch (details.productID) {
      case productIdRemoveAds:
        notifier.purchaseRemoveAds();
        break;
      case productIdDewdrops100:
        notifier.purchaseDewdrops(100);
        break;
      case productIdDewdrops550:
        notifier.purchaseDewdrops(550);
        break;
      case productIdDewdrops1200:
        notifier.purchaseDewdrops(1200);
        break;
      case productIdDewdrops3000:
        notifier.purchaseDewdrops(3000);
        break;
      default:
        if (kDebugMode) {
          debugPrint('Unhandled product id: ${details.productID}');
        }
        if (key.isNotEmpty) _handledPurchaseIds.remove(key);
        notifier.setGameState(before);
        return false;
    }
    final saved = await ref.read(saveManagerProvider).flushLocal();
    if (!saved) {
      notifier.setGameState(before);
      if (key.isNotEmpty) _handledPurchaseIds.remove(key);
      return false;
    }
    unawaited(ref.read(saveManagerProvider).saveGame());
    return true;
  }

  String _purchaseKey(PurchaseDetails details) {
    final id = details.purchaseID;
    if (id != null && id.isNotEmpty) return id;
    final token = details.verificationData.serverVerificationData;
    if (token.isNotEmpty) return '${details.productID}:$token';
    return '';
  }
}
