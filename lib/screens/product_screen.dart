import 'package:flutter/material.dart';
import '../widgets/product_card.dart';
import '../models/cart_manager.dart';

// Model untuk Product
class Product {
  final String id;
  final String name;
  final String category;
  final String code;
  final bool isActive;
  final int price;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.code,
    required this.isActive,
    required this.price,
  });
}

// Data dummy produk
final List<Product> dummyProducts = [
  const Product(
    id: '1',
    name: 'Nasi Goreng Special',
    category: 'Makanan',
    code: 'PRC001',
    isActive: true,
    price: 25000,
  ),
  const Product(
    id: '2',
    name: 'Ayam Bakar Madu',
    category: 'Makanan',
    code: 'PRC002',
    isActive: true,
    price: 35000,
  ),
  const Product(
    id: '3',
    name: 'Es Teh Manis',
    category: 'Minuman',
    code: 'PRC003',
    isActive: true,
    price: 8000,
  ),
  const Product(
    id: '4',
    name: 'Bakso Special',
    category: 'Makanan',
    code: 'PRC004',
    isActive: true,
    price: 20000,
  ),
  const Product(
    id: '5',
    name: 'Jus Jeruk',
    category: 'Minuman',
    code: 'PRC005',
    isActive: false,
    price: 12000,
  ),
  const Product(
    id: '6',
    name: 'Sate Ayam',
    category: 'Makanan',
    code: 'PRC006',
    isActive: true,
    price: 30000,
  ),
];

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final Set<String> _selectedProductIds = {};

  List<Product> get _filteredProducts {
    return dummyProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           product.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onProductSelectionChanged(Product product, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedProductIds.add(product.id);
        CartManager().addToCart(CartItem(
          id: product.id,
          name: product.name,
          quantity: 1,
          price: product.price,
        ));
      } else {
        _selectedProductIds.remove(product.id);
        CartManager().removeFromCart(product.id);
      }
    });
  }

  void _checkoutSelectedProducts() {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }

    // Navigate to cashier screen
    Navigator.pushNamed(context, '/cashier');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CASHIR SMART'),
        centerTitle: true,
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari nama/kode produk',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // Section header dengan dropdown kategori
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Semua', child: Text('Semua')),
                    const PopupMenuItem(value: 'Makanan', child: Text('Makanan')),
                    const PopupMenuItem(value: 'Minuman', child: Text('Minuman')),
                  ],
                  child: Row(
                    children: [
                      Text(
                        _selectedCategory,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ProductCard(
                  product: product,
                  isSelected: _selectedProductIds.contains(product.id),
                  onSelectionChanged: (isSelected) => _onProductSelectionChanged(product, isSelected),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _checkoutSelectedProducts,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('${_selectedProductIds.length} item dipilih'),
            )
          : FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to add product screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tambah produk - fitur coming soon!')),
                );
              },
              backgroundColor: Colors.blue[800],
              child: const Icon(Icons.add),
            ),
    );
  }
}