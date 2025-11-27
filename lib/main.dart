import 'dart:convert' as json;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const SmartCashierApp());
}

class SmartCashierApp extends StatelessWidget {
  const SmartCashierApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cashier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      ),
      home: const LoginPage(),
    );
  }
}

// ====================== API SERVICE ======================

class ApiService {
  // ganti sesuai backend-mu
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  String? _token;

  String? get token => _token;

  Map<String, String> _headers({bool withAuth = false}) {
    final h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final res = await http.post(
      url,
      headers: _headers(),
      body: json.jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      _token = data['token'];
    } else {
      throw Exception('Login gagal: ${res.body}');
    }
  }

  Future<List<Product>> getProducts({String? query}) async {
    final url = Uri.parse('$baseUrl/products');
    final res = await http.get(url, headers: _headers(withAuth: true));

    if (res.statusCode == 200) {
      final List list = json.jsonDecode(res.body)['data'] ?? json.jsonDecode(res.body);
      return list.map((e) => Product.fromJson(e)).toList().where((p) {
        if (query == null || query.isEmpty) return true;
        final q = query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q);
      }).toList();
    } else {
      throw Exception('Gagal mengambil produk');
    }
  }

  Future<Product> createProduct(Product p) async {
    final url = Uri.parse('$baseUrl/products');
    final res = await http.post(
      url,
      headers: _headers(withAuth: true),
      body: json.jsonEncode(p.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      return Product.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Gagal menambah produk');
    }
  }

  Future<void> deleteProduct(int id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final res = await http.delete(url, headers: _headers(withAuth: true));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Gagal menghapus produk');
    }
  }

  Future<List<Product>> getRecommendations() async {
    final url = Uri.parse('$baseUrl/products/recommendations');
    final res = await http.get(url, headers: _headers(withAuth: true));
    if (res.statusCode == 200) {
      final List list = json.jsonDecode(res.body)['data'] ?? json.jsonDecode(res.body);
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil rekomendasi produk');
    }
  }

  Future<Transaction> checkout(
    List<CartItem> cartItems,
    int paidAmount,
  ) async {
    final url = Uri.parse('$baseUrl/transactions');
    final items = cartItems
        .map((e) => {
              'product_id': e.product.id,
              'qty': e.qty,
            })
        .toList();

    final res = await http.post(
      url,
      headers: _headers(withAuth: true),
      body: json.jsonEncode({
        'items': items,
        'paid_amount': paidAmount,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = json.jsonDecode(res.body)['data'] ?? json.jsonDecode(res.body);
      return Transaction.fromJson(data);
    } else {
      throw Exception('Gagal checkout: ${res.body}');
    }
  }

  Future<List<Transaction>> getTransactions({DateTime? date}) async {
    // bisa pakai endpoint /reports/daily atau /transactions sesuai backend-mu
    Uri url;
    if (date != null) {
      final d = DateFormat('yyyy-MM-dd').format(date);
      url = Uri.parse('$baseUrl/reports/daily?date=$d');
    } else {
      url = Uri.parse('$baseUrl/transactions');
    }

    final res = await http.get(url, headers: _headers(withAuth: true));
    if (res.statusCode == 200) {
      final body = json.jsonDecode(res.body);
      final List list = body['data'] is List ? body['data'] : (body as List);
      return list.map((e) => Transaction.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil transaksi');
    }
  }
}

final api = ApiService();

// ====================== MODEL ======================

class Product {
  final int? id;
  final String name;
  final String code;
  final int price;
  final int stock;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.stock,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      price: (json['price'] is int)
          ? json['price']
          : int.tryParse(json['price'].toString()) ?? 0,
      stock: json['stock'] ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'price': price,
      'stock': stock,
      'is_active': isActive,
    };
  }
}

class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  int get subtotal => product.price * qty;
}

class Transaction {
  final int id;
  final String invoiceNumber;
  final int totalAmount;
  final int paidAmount;
  final int changeAmount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      totalAmount: json['total_amount'] ?? 0,
      paidAmount: json['paid_amount'] ?? 0,
      changeAmount: json['change_amount'] ?? 0,
      createdAt: DateTime.tryParse(
            json['transaction_date'] ?? json['created_at'] ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

// ====================== LOGIN PAGE ======================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await api.login(_emailC.text.trim(), _passC.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.point_of_sale,
                        size: 48, color: cs.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Cashier',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailC,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passC,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: cs.error),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _handleLogin,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====================== HOME + BOTTOM NAV ======================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    ProductsPage(),
    TransactionPage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Cashier'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

// ====================== PRODUK PAGE ======================

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _search = '';
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.getProducts();
  }

  void _reload() {
    setState(() {
      _future = api.getProducts(query: _search);
    });
  }

  Future<void> _showAddProductDialog() async {
    final nameC = TextEditingController();
    final codeC = TextEditingController();
    final priceC = TextEditingController();
    final stockC = TextEditingController(text: '0');
    bool isActive = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                ),
                TextField(
                  controller: codeC,
                  decoration: const InputDecoration(labelText: 'Kode / Barcode'),
                ),
                TextField(
                  controller: priceC,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockC,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) {
                    isActive = v;
                  },
                  title: const Text('Aktif'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            FilledButton(
              child: const Text('Simpan'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final p = Product(
          name: nameC.text.trim(),
          code: codeC.text.trim(),
          price: int.tryParse(priceC.text.trim()) ?? 0,
          stock: int.tryParse(stockC.text.trim()) ?? 0,
          isActive: isActive,
        );
        await api.createProduct(p);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil ditambahkan')),
          );
          _reload();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${p.name}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          FilledButton(
            child: const Text('Hapus'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await api.deleteProduct(p.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk dihapus')),
        );
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
            ),
            onChanged: (v) {
              _search = v;
              _reload();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(child: Text('Belum ada produk'));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                            'Kode: ${p.code}\nStok: ${p.stock} | Harga: Rp ${p.price}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: p.id == null
                              ? null
                              : () => _confirmDelete(p),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add),
              label: const Text('Produk'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ====================== TRANSACTION / KASIR PAGE ======================

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<CartItem> cart = [];
  List<Product> recommendations = [];
  bool _loadingRecom = true;
  int paidAmount = 0;
  final paidC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final list = await api.getRecommendations();
      if (mounted) {
        setState(() {
          recommendations = list;
          _loadingRecom = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingRecom = false;
        });
      }
    }
  }

  int get total =>
      cart.fold(0, (prev, item) => prev + item.subtotal);

  void _addToCart(Product p) {
    final idx = cart.indexWhere((e) => e.product.id == p.id);
    setState(() {
      if (idx >= 0) {
        cart[idx].qty += 1;
      } else {
        cart.add(CartItem(product: p, qty: 1));
      }
    });
  }

  Future<void> _selectProduct() async {
    final selected = await showDialog<Product>(
      context: context,
      builder: (ctx) => const ProductPickerDialog(),
    );
    if (selected != null) {
      _addToCart(selected);
    }
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }

    paidAmount = int.tryParse(paidC.text.trim()) ?? 0;
    if (paidAmount < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang bayar kurang')),
      );
      return;
    }

    try {
      final trx = await api.checkout(cart, paidAmount);
      if (!mounted) return;
      final change = paidAmount - total;
      setState(() {
        cart.clear();
        paidC.clear();
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Transaksi Berhasil'),
          content: Text(
              'No: ${trx.invoiceNumber}\nTotal: Rp $total\nBayar: Rp $paidAmount\nKembali: Rp $change'),
          actions: [
            FilledButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal checkout: $e')),
      );
    }
  }

  @override
  void dispose() {
    paidC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Rekomendasi AI
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rekomendasi Produk',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: _loadingRecom
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : recommendations.isEmpty
                    ? const Center(
                        child: Text('Belum ada rekomendasi'),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final p = recommendations[i];
                          return GestureDetector(
                            onTap: () => _addToCart(p),
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: cs.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Rp ${p.price}',
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Keranjang',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: _selectProduct,
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = cart[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(item.product.name),
                          subtitle: Text(
                              'Harga: Rp ${item.product.price}  •  Subtotal: Rp ${item.subtotal}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () {
                                  setState(() {
                                    if (item.qty > 1) {
                                      item.qty--;
                                    } else {
                                      cart.removeAt(i);
                                    }
                                  });
                                },
                              ),
                              Text('${item.qty}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () {
                                  setState(() {
                                    item.qty++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      'Rp $total',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: paidC,
                  decoration: const InputDecoration(
                    labelText: 'Uang bayar',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checkout,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Checkout'),
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

// ====================== PRODUCT PICKER DIALOG ======================

class ProductPickerDialog extends StatefulWidget {
  const ProductPickerDialog({super.key});

  @override
  State<ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<ProductPickerDialog> {
  String _search = '';
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.getProducts();
  }

  void _reload() {
    setState(() {
      _future = api.getProducts(query: _search);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Produk'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _search = v;
                _reload();
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(child: Text('Tidak ada produk'));
                  }
                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('Rp ${p.price} • Stok ${p.stock}'),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Tutup'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

// ====================== REPORT / LAPORAN PAGE ======================

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime selectedDate = DateTime.now();
  late Future<List<Transaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.getTransactions(date: selectedDate);
  }

  void _reload() {
    setState(() {
      _future = api.getTransactions(date: selectedDate);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: selectedDate,
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Tanggal: $dateStr'),
                        const Spacer(),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final txs = snapshot.data ?? [];
                if (txs.isEmpty) {
                  return const Center(child: Text('Belum ada transaksi'));
                }
                final total = txs.fold<int>(
                    0, (prev, t) => prev + t.totalAmount);
                return Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Total Penjualan Hari Ini',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Jumlah transaksi: ${txs.length}'),
                        trailing: Text(
                          'Rp $total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: txs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = txs[i];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text('Invoice: ${t.invoiceNumber}'),
                              subtitle: Text(
                                  'Total: Rp ${t.totalAmount}\nBayar: Rp ${t.paidAmount} • Kembali: Rp ${t.changeAmount}'),
                              isThreeLine: true,
                              leading: const Icon(Icons.receipt_long),
                              trailing: Text(
                                DateFormat('HH:mm').format(t.createdAt),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
