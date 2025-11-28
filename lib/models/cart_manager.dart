// Global cart manager for shared state across screens
class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _selectedItems = [];
  final List<CartItem> _aiRecommendations = [
    const CartItem(id: 'rec1', name: 'Produk Terbaru 1', quantity: 1, price: 15000, isRecommendation: true),
    const CartItem(id: 'rec2', name: 'Produk Terlaris 1', quantity: 1, price: 20000, isRecommendation: true),
    const CartItem(id: 'rec3', name: 'Produk Populer 1', quantity: 1, price: 18000, isRecommendation: true),
  ];

  List<CartItem> get selectedItems => List.unmodifiable(_selectedItems);
  List<CartItem> get aiRecommendations => List.unmodifiable(_aiRecommendations);

  void addToCart(CartItem item) {
    final existingIndex = _selectedItems.indexWhere((cartItem) => cartItem.id == item.id);
    if (existingIndex >= 0) {
      _selectedItems[existingIndex] = CartItem(
        id: item.id,
        name: item.name,
        quantity: _selectedItems[existingIndex].quantity + 1,
        price: item.price,
      );
    } else {
      _selectedItems.add(item);
    }
  }

  void removeFromCart(String itemId) {
    _selectedItems.removeWhere((item) => item.id == itemId);
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final index = _selectedItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _selectedItems[index] = CartItem(
        id: _selectedItems[index].id,
        name: _selectedItems[index].name,
        quantity: quantity,
        price: _selectedItems[index].price,
      );
    }
  }

  void clearCart() {
    _selectedItems.clear();
  }

  int get totalItems => _selectedItems.length;
  int get totalPrice => _selectedItems.fold(0, (sum, item) => sum + item.subtotal);
}

// Updated CartItem model
class CartItem {
  final String id;
  final String name;
  final int quantity;
  final int price;
  final bool isRecommendation;

  const CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.isRecommendation = false,
  });

  int get subtotal => quantity * price;

  CartItem copyWith({
    String? id,
    String? name,
    int? quantity,
    int? price,
    bool? isRecommendation,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isRecommendation: isRecommendation ?? this.isRecommendation,
    );
  }
}