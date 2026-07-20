import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api/cart_dto.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;
}

class CartState extends ChangeNotifier {
  static const _prefsKey = 'local_cart_v1';

  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);
  int get itemCount => _lines.fold(0, (sum, l) => sum + l.quantity);
  bool get isEmpty => _lines.isEmpty;
  double get subtotal =>
      _lines.fold(0.0, (sum, l) => sum + l.subtotal);
  double get shipping => isEmpty ? 0 : (subtotal >= 50 ? 0 : 4.99);
  double get total => subtotal + shipping;

  void add(Product product, {int qty = 1}) {
    final i = _lines.indexWhere((l) => l.product.id == product.id);
    if (i >= 0) {
      _lines[i].quantity += qty;
    } else {
      _lines.add(CartLine(product: product, quantity: qty));
    }
    notifyListeners();
    _persist();
    _syncToServer();
  }

  void increment(String productId) {
    final i = _lines.indexWhere((l) => l.product.id == productId);
    if (i >= 0) {
      _lines[i].quantity += 1;
      notifyListeners();
      _persist();
      _syncToServer();
    }
  }

  void decrement(String productId) {
    final i = _lines.indexWhere((l) => l.product.id == productId);
    if (i < 0) return;
    if (_lines[i].quantity <= 1) {
      _lines.removeAt(i);
    } else {
      _lines[i].quantity -= 1;
    }
    notifyListeners();
    _persist();
    _syncToServer();
  }

  void remove(String productId) {
    _lines.removeWhere((l) => l.product.id == productId);
    notifyListeners();
    _persist();
    _syncToServer();
  }

  /// Local-only clear. Used on logout and after checkout — the server cart is
  /// intentionally left untouched (logout keeps it for next login; checkout
  /// already clears it server-side), so this must NOT push to the server.
  void clear() {
    _lines.clear();
    notifyListeners();
    _persist();
  }

  /// Clears the cart everywhere (local + server). Used by the "Xóa hết" button
  /// so an emptied cart stays empty across re-login.
  void clearAll() {
    _lines.clear();
    notifyListeners();
    _persist();
    _syncToServer();
  }

  bool _syncing = false;
  bool _dirty = false;

  /// Mirrors the current local cart onto the server (`DELETE /cart/clear` then
  /// re-adds each line) so it survives logout/login and follows the user
  /// across devices — not just at checkout. Fire-and-forget: the UI updates
  /// from local state immediately and the server catches up in the background.
  ///
  /// Serialized so rapid +/- taps can't race: while a sync is in flight,
  /// further changes just mark it dirty and one trailing sync runs with the
  /// latest state.
  Future<void> _syncToServer() async {
    _dirty = true;
    if (_syncing) return;
    _syncing = true;
    try {
      while (_dirty) {
        _dirty = false;
        final snapshot = _lines
            .map((l) =>
                CartItemRequest(productId: l.product.id, quantity: l.quantity))
            .toList();
        final cleared = await CartService.clearCart();
        if (!cleared.isSuccess) continue;
        for (final item in snapshot) {
          await CartService.addToCart(item);
        }
      }
    } catch (_) {
      // Best-effort: the local + on-disk cart stay the source of truth.
    } finally {
      _syncing = false;
    }
  }

  /// Saves the cart to disk so it survives the app process being killed
  /// (backgrounded + reclaimed, crash, etc.) before the user reaches
  /// checkout — the only point it's otherwise synced to the server.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_lines
        .map((l) => {
              'productId': l.product.id,
              'name': l.product.name,
              'price': l.product.price,
              'imageUrl': l.product.imageUrl,
              'quantity': l.quantity,
            })
        .toList());
    await prefs.setString(_prefsKey, raw);
  }

  /// Restores the cart saved by [_persist] on a previous run. Called once at
  /// app startup, before login, so a cart the user built up doesn't vanish
  /// just because the process was killed before they checked out.
  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _lines
        ..clear()
        ..addAll(list.map((m) {
          final map = m as Map<String, dynamic>;
          return CartLine(
            product: Product(
              id: map['productId'] as String,
              name: map['name'] as String,
              subtitle: '',
              categoryId: '',
              petType: PetType.dog,
              price: (map['price'] as num).toDouble(),
              imageUrl: map['imageUrl'] as String? ?? '',
              images: const [],
              rating: 0,
              reviewCount: 0,
              brand: '',
              weightGrams: 0,
              stock: 0,
            ),
            quantity: map['quantity'] as int,
          );
        }));
      notifyListeners();
    } catch (_) {
      // Corrupt or outdated cache format — ignore and start fresh.
    }
  }

  /// Replaces the in-memory cart with the user's server-side cart
  /// (`GET /api/v1/cart`). Called after login so the cart survives
  /// re-logins instead of always starting empty.
  ///
  /// Skips the overwrite if [loadFromLocal] already restored a non-empty
  /// cart — that means the process was killed before the last session's
  /// changes were synced (checkout syncs local -> server), so the local
  /// copy is the freshest intent and shouldn't be clobbered by the older
  /// server snapshot.
  ///
  /// The server cart only carries a thin product projection, so each line
  /// is rebuilt as a minimal [Product] — enough for the cart / checkout UI.
  Future<void> loadFromServer() async {
    if (_lines.isNotEmpty) return;
    final result = await CartService.getCart();
    if (!result.isSuccess || result.data == null) return;
    _lines
      ..clear()
      ..addAll(result.data!.items.map(
        (item) => CartLine(
          product: Product(
            id: item.productId,
            name: item.productName,
            subtitle: '',
            categoryId: '',
            petType: PetType.dog,
            price: item.price,
            imageUrl: item.primaryImageUrl ?? '',
            images: const [],
            rating: 0,
            reviewCount: 0,
            brand: '',
            weightGrams: 0,
            stock: 0,
          ),
          quantity: item.quantity,
        ),
      ));
    notifyListeners();
  }
}