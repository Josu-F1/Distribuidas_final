import 'package:flutter/material.dart';
import '../models/app_models.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.precio * item.quantity));
  double get iva => subtotal * 0.15;
  double get total => subtotal + iva;

  void addToCart(Product product, {int quantity = 1}) {
    if (product.stock <= 0) return; // No permitir agregar productos sin stock
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) {
      final finalQty = quantity > product.stock ? product.stock : quantity;
      if (finalQty > 0) {
        _items.add(CartItem(product: product, quantity: finalQty));
        notifyListeners();
      }
    } else {
      if (_items[index].quantity + quantity <= _items[index].product.stock) {
        _items[index].quantity += quantity;
      } else {
        _items[index].quantity = _items[index].product.stock;
      }
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity < _items[index].product.stock) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        _items.removeAt(index);
        notifyListeners();
      }
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}
