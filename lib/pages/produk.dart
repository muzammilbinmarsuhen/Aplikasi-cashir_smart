import 'package:flutter/material.dart';
import 'transaksi.dart';

// Model Produk
class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int sold;
  final int price;
  final int? discount;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.sold,
    required this.price,
    this.discount,
  });
}

// Data dummy produk cafe
final List<Product> dummyProducts = [
  Product(
    id: '1',
    name: 'Espresso',
    imageUrl: 'espresso.jpg',
    rating: 4.9,
    sold: 1250,
    price: 25000,
    discount: 10,
  ),
  Product(
    id: '2',
    name: 'Cappuccino',
    imageUrl: 'cappuccino.jpg',
    rating: 4.8,
    sold: 980,
    price: 35000,
  ),
  Product(
    id: '3',
    name: 'Nasi Goreng Special',
    imageUrl: 'nasi_goreng.jpg',
    rating: 4.7,
    sold: 750,
    price: 45000,
    discount: 15,
  ),
  Product(
    id: '4',
    name: 'Ayam Bakar Madu',
    imageUrl: 'ayam_bakar.jpg',
    rating: 4.8,
    sold: 620,
    price: 55000,
  ),
  Product(
    id: '5',
    name: 'Teh Tarik',
    imageUrl: 'teh_tarik.jpg',
    rating: 4.6,
    sold: 890,
    price: 18000,
    discount: 5,
  ),
  Product(
    id: '6',
    name: 'Mie Ayam Special',
    imageUrl: 'mie_ayam.jpg',
    rating: 4.7,
    sold: 540,
    price: 38000,
  ),
  Product(
    id: '7',
    name: 'Sate Ayam',
    imageUrl: 'sate_ayam.jpg',
    rating: 4.9,
    sold: 420,
    price: 42000,
    discount: 20,
  ),
  Product(
    id: '8',
    name: 'Jus Jeruk Fresh',
    imageUrl: 'jus_jeruk.jpg',
    rating: 4.5,
    sold: 380,
    price: 22000,
  ),
];

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  List<Product> cartItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    setState(() {
      cartItems.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToCart() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang masih kosong'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransaksiPage(cartItems: cartItems),
      ),
    ).then((_) {
      // Clear cart when returning
      setState(() {
        cartItems.clear();
      });
    });
  }

  String _formatPrice(int price) {
    return 'Rp${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String _formatSoldCount(int sold) {
    if (sold >= 1000) {
      return '${(sold / 1000).toStringAsFixed(0)}RB+';
    }
    return '$sold+';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Produk',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          // Cart icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.black),
                onPressed: _navigateToCart,
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Products Grid
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: dummyProducts.length,
                itemBuilder: (context, index) {
                  final product = dummyProducts[index];
                  return GestureDetector(
                    onTap: () => _addToCart(product),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.grey[50]!,
                          ],
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                          const BoxShadow(
                            color: Color.fromRGBO(33, 150, 243, 0.05),
                            blurRadius: 12,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: Image.asset(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.restaurant_menu,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Favorite icon
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white70,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Product Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Name
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 4),

                                  // Promo Chip
                                  if (product.discount != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Colors.red, Colors.orange],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          const BoxShadow(
                                            color: Color.fromRGBO(244, 67, 54, 0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_offer,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${product.discount}% OFF',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  const SizedBox(height: 4),

                                  // Rating and Sold
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(255, 193, 7, 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${product.rating}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 1,
                                          height: 12,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.shopping_cart,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          _formatSoldCount(product.sold),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Spacer(),

                                  // Price
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(33, 150, 243, 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _formatPrice(product.price),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Bottom row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(76, 175, 80, 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Tersedia',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(158, 158, 158, 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_shopping_cart,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

    );
  }
}