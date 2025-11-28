import 'package:flutter/material.dart';
import '../widgets/cart_item_card.dart';

// Model untuk CartItem
class CartItem {
  final String id;
  final String name;
  final int quantity;
  final int price;

  const CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  int get subtotal => quantity * price;
}

// Model untuk Recommended Product
class RecommendedProduct {
  final String id;
  final String name;

  const RecommendedProduct({
    required this.id,
    required this.name,
  });
}

// Data dummy
final List<RecommendedProduct> dummyRecommendations = [
  const RecommendedProduct(id: '1', name: 'Nasi Goreng'),
  const RecommendedProduct(id: '2', name: 'Ayam Bakar'),
  const RecommendedProduct(id: '3', name: 'Es Teh'),
  const RecommendedProduct(id: '4', name: 'Bakso'),
];

final List<CartItem> dummyCartItems = [
  const CartItem(id: '1', name: 'Nasi Goreng Special', quantity: 2, price: 25000),
  const CartItem(id: '2', name: 'Es Teh Manis', quantity: 1, price: 5000),
  const CartItem(id: '3', name: 'Ayam Bakar Madu', quantity: 1, price: 35000),
];

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  List<CartItem> cartItems = List.from(dummyCartItems);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _receivedAmountController = TextEditingController();

  int get subtotal => cartItems.fold(0, (sum, item) => sum + item.subtotal);
  int get total => subtotal; // Untuk sekarang sama dengan subtotal
  int get receivedAmount => int.tryParse(_receivedAmountController.text) ?? 0;
  int get change => receivedAmount - total;

  void _addToCart(RecommendedProduct product) {
    setState(() {
      // Cek apakah item sudah ada di cart
      final existingIndex = cartItems.indexWhere((item) => item.name == product.name);
      if (existingIndex >= 0) {
        // Jika sudah ada, tambah quantity
        final existingItem = cartItems[existingIndex];
        cartItems[existingIndex] = CartItem(
          id: existingItem.id,
          name: existingItem.name,
          quantity: existingItem.quantity + 1,
          price: existingItem.price,
        );
      } else {
        // Jika belum ada, tambah item baru dengan harga dummy
        cartItems.add(CartItem(
          id: product.id,
          name: product.name,
          quantity: 1,
          price: 20000, // Harga dummy
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
    );
  }

  void _updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) return;

    setState(() {
      final index = cartItems.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        final item = cartItems[index];
        cartItems[index] = CartItem(
          id: item.id,
          name: item.name,
          quantity: newQuantity,
          price: item.price,
        );
      }
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      cartItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _completeTransaction() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }

    if (receivedAmount < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang yang diterima kurang')),
      );
      return;
    }

    // TODO: Implement transaction completion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil!')),
    );

    // Clear cart
    setState(() {
      cartItems.clear();
      _receivedAmountController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _receivedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // TODO: Implement back navigation
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari produk (nama/kode)',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // Rekomendasi Produk
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekomendasi Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Navigate to full recommendations
                  },
                ),
              ],
            ),
          ),

          // Horizontal list rekomendasi
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dummyRecommendations.length,
              itemBuilder: (context, index) {
                final product = dummyRecommendations[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () => _addToCart(product),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Tambah'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Keranjang
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text('Keranjang kosong'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return CartItemCard(
                          item: item,
                          onQuantityChanged: (newQuantity) => _updateQuantity(item.id, newQuantity),
                          onRemove: () => _removeFromCart(item.id),
                        );
                      },
                    ),
            ),
          ),

          // Ringkasan dan checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('Rp ${subtotal.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}'),
                  ],
                ),

                const SizedBox(height: 8),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${total.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Uang diterima
                TextField(
                  controller: _receivedAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Uang Diterima',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild untuk update kembalian
                  },
                ),

                const SizedBox(height: 8),

                // Kembalian
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kembalian:'),
                    Text(
                      'Rp ${change.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}',
                      style: TextStyle(
                        color: change >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tombol checkout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SELESAIKAN TRANSAKSI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}