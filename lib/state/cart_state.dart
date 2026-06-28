import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;
}

class CartState extends ChangeNotifier {
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
  }

  void increment(String productId) {
    final i = _lines.indexWhere((l) => l.product.id == productId);
    if (i >= 0) {
      _lines[i].quantity += 1;
      notifyListeners();
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
  }

  void remove(String productId) {
    _lines.removeWhere((l) => l.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}