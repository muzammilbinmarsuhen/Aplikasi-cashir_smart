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

// Data dummy produk
final List<Product> dummyProducts = [
  Product(
    id: '1',
    name: 'Buku Coding Algoritma',
    imageUrl: 'https://picsum.photos/200/200?random=1',
    rating: 4.9,
    sold: 4000,
    price: 30500,
    discount: 24,
  ),
  Product(
    id: '2',
    name: 'Sarung Tangan Nitril',
    imageUrl: 'https://picsum.photos/200/200?random=2',
    rating: 4.8,
    sold: 1000,
    price: 43700,
    discount: 56,
  ),
  Product(
    id: '3',
    name: 'Smart Tasbih Digital',
    imageUrl: 'https://picsum.photos/200/200?random=3',
    rating: 4.7,
    sold: 250,
    price: 87474,
    discount: 72,
  ),
  Product(
    id: '4',
    name: 'Headphone Gaming RGB',
    imageUrl: 'https://picsum.photos/200/200?random=4',
    rating: 4.6,
    sold: 850,
    price: 125000,
    discount: 35,
  ),
  Product(
    id: '5',
    name: 'Power Bank 20000mAh',
    imageUrl: 'https://picsum.photos/200/200?random=5',
    rating: 4.8,
    sold: 3200,
    price: 89000,
    discount: 15,
  ),
  Product(
    id: '6',
    name: 'Mouse Gaming Wireless',
    imageUrl: 'https://picsum.photos/200/200?random=6',
    rating: 4.5,
    sold: 675,
    price: 156000,
    discount: 28,
  ),
  Product(
    id: '7',
    name: 'Keyboard Mechanical RGB',
    imageUrl: 'https://picsum.photos/200/200?random=7',
    rating: 4.9,
    sold: 1200,
    price: 234000,
    discount: 42,
  ),
  Product(
    id: '8',
    name: 'Webcam HD 1080p',
    imageUrl: 'https://picsum.photos/200/200?random=8',
    rating: 4.4,
    sold: 450,
    price: 187000,
    discount: 20,
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
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${product.discount}% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 4),

                                  // Rating and Sold
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber,
                                      ),
                                      Text(
                                        '${product.rating}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatSoldCount(product.sold),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // Price
                                  Text(
                                    _formatPrice(product.price),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Bottom row
                                  Row(
                                    children: [
                                      const Text(
                                        'Cicilan 0%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          // More options (placeholder)
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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