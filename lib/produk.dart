import 'dart:convert' as json;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'transaksi.dart';

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

// ====================== API SERVICE ======================

class ApiService {
  // ganti sesuai backend-mu
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _user = json.jsonDecode(userJson);
    }
  }

  Future<void> _saveToken(String token, [Map<String, dynamic>? userData]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _token = token;
    if (userData != null) {
      await prefs.setString(_userKey, json.jsonEncode(userData));
      _user = userData;
    }
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _user = null;
  }

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

  Future<void> init() async {
    await _loadToken();
  }

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
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
      final token = data['token'] ?? data['access_token'];
      if (token != null) {
        await _saveToken(token, data['user']);
      } else {
        throw Exception('Token tidak ditemukan dalam response');
      }
    } else {
      final errorData = json.jsonDecode(res.body);
      throw Exception(errorData['message'] ?? 'Login gagal');
    }
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/api/logout');
      await http.post(url, headers: _headers(withAuth: true));
    } catch (_) {
      // Ignore logout errors
    }
    await _clearToken();
  }

  Future<Map<String, dynamic>?> getMe() async {
    final url = Uri.parse('$baseUrl/api/me');
    final res = await http.get(url, headers: _headers(withAuth: true));

    if (res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      return data['user'] ?? data;
    } else if (res.statusCode == 401) {
      await _clearToken(); // Token invalid
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception('Gagal mengambil data user');
    }
  }

  Future<List<Product>> getProducts({String? query}) async {
    final url = Uri.parse('$baseUrl/api/products');
    final res = await http.get(url, headers: _headers(withAuth: true));

    if (res.statusCode == 200) {
      final List list = json.jsonDecode(res.body)['data'] ?? json.jsonDecode(res.body);
      return list.map((e) => Product.fromJson(e)).toList().where((p) {
        if (query == null || query.isEmpty) return true;
        final q = query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q);
      }).toList();
    } else if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception('Gagal mengambil produk');
    }
  }

  Future<Product> createProduct(Product p) async {
    final url = Uri.parse('$baseUrl/api/products');
    final res = await http.post(
      url,
      headers: _headers(withAuth: true),
      body: json.jsonEncode(p.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      return Product.fromJson(data['data'] ?? data);
    } else if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception('Gagal menambah produk');
    }
  }

  Future<Product> updateProduct(int id, Product p) async {
    final url = Uri.parse('$baseUrl/api/products/$id');
    final res = await http.put(
      url,
      headers: _headers(withAuth: true),
      body: json.jsonEncode(p.toJson()),
    );
    if (res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      return Product.fromJson(data['data'] ?? data);
    } else if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception('Gagal mengupdate produk');
    }
  }

  Future<void> deleteProduct(int id) async {
    final url = Uri.parse('$baseUrl/api/products/$id');
    final res = await http.delete(url, headers: _headers(withAuth: true));
    if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Gagal menghapus produk');
    }
  }

  Future<List<Product>> getRecommendations() async {
    final url = Uri.parse('$baseUrl/api/products/recommendations');
    final res = await http.get(url, headers: _headers(withAuth: true));
    if (res.statusCode == 200) {
      final List list = json.jsonDecode(res.body)['data'] ?? json.jsonDecode(res.body);
      return list.map((e) => Product.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception('Gagal mengambil rekomendasi produk');
    }
  }

  Future<Map<String, dynamic>> checkout(
    List<Map<String, dynamic>> cartItems,
    int paidAmount,
  ) async {
    final url = Uri.parse('$baseUrl/api/transactions');
    final res = await http.post(
      url,
      headers: _headers(withAuth: true),
      body: json.jsonEncode({
        'items': cartItems,
        'paid_amount': paidAmount,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = json.jsonDecode(res.body)['data'] ?? json.jsonDecode(res.body);
      return data;
    } else if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      final errorData = json.jsonDecode(res.body);
      throw Exception(errorData['message'] ?? 'Gagal checkout');
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions({DateTime? date}) async {
    // bisa pakai endpoint /reports/daily atau /transactions sesuai backend-mu
    Uri url;
    if (date != null) {
      final d = DateFormat('yyyy-MM-dd').format(date);
      url = Uri.parse('$baseUrl/api/reports/daily?date=$d');
    } else {
      url = Uri.parse('$baseUrl/api/transactions');
    }

    final res = await http.get(url, headers: _headers(withAuth: true));
    if (res.statusCode == 200) {
      final body = json.jsonDecode(res.body);
      final List list = body['data'] is List ? body['data'] : (body as List);
      return list.cast<Map<String, dynamic>>();
    } else if (res.statusCode == 401) {
      await _clearToken();
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception('Gagal mengambil transaksi');
    }
  }
}

final api = ApiService();

// ====================== PRODUK PAGE ======================

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _search = '';
  late Future<List<Product>> _future;
  final Map<int, int> _selectedProducts = {}; // product_id -> quantity

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

  void _addToCart(Product product) {
    setState(() {
      final productId = product.id!;
      _selectedProducts[productId] = (_selectedProducts[productId] ?? 0) + 1;
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      final productId = product.id!;
      if (_selectedProducts.containsKey(productId)) {
        _selectedProducts[productId] = _selectedProducts[productId]! - 1;
        if (_selectedProducts[productId]! <= 0) {
          _selectedProducts.remove(productId);
        }
      }
    });
  }

  int _getSelectedQuantity(Product product) {
    return _selectedProducts[product.id] ?? 0;
  }

  int get _totalItems => _selectedProducts.values.fold(0, (sum, qty) => sum + qty);

  Future<void> _proceedToCheckout() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }

    // Navigate to TransactionPage with selected products
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionPage(selectedProducts: _selectedProducts),
      ),
    ).then((_) {
      // Clear selection when returning
      setState(() {
        _selectedProducts.clear();
      });
    });
  }

  Future<void> _showProductDialog([Product? product]) async {
    final isEdit = product != null;
    final nameC = TextEditingController(text: isEdit ? product.name : '');
    final codeC = TextEditingController(text: isEdit ? product.code : '');
    final priceC = TextEditingController(text: isEdit ? product.price.toString() : '');
    final stockC = TextEditingController(text: isEdit ? product.stock.toString() : '0');
    bool isActive = isEdit ? product.isActive : true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Produk' : 'Produk Baru'),
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
              child: Text(isEdit ? 'Update' : 'Simpan'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final p = Product(
          id: product?.id,
          name: nameC.text.trim(),
          code: codeC.text.trim(),
          price: int.tryParse(priceC.text.trim()) ?? 0,
          stock: int.tryParse(stockC.text.trim()) ?? 0,
          isActive: isActive,
        );
        if (isEdit) {
          await api.updateProduct(product.id as int, p);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk berhasil diupdate')),
            );
          }
        } else {
          await api.createProduct(p);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk berhasil ditambahkan')),
            );
          }
        }
        _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search bar
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
            // Cart summary
            if (_totalItems > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$_totalItems item dipilih',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _proceedToCheckout,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Products grid
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    if (error.contains('Sesi berakhir') || error.contains('401')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      });
                      return const Center(child: Text('Sesi berakhir, mengarahkan ke login...'));
                    }
                    return Center(child: Text('Error: $error'));
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(child: Text('Belum ada produk'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final p = products[i];
                      final selectedQty = _getSelectedQuantity(p);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image placeholder
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kode: ${p.code}',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${p.price}',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Stok: ${p.stock}',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (selectedQty > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$selectedQty',
                                            style: TextStyle(
                                              color: cs.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => _addToCart(p),
                                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                                          label: const Text('Tambah'),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      if (selectedQty > 0) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () => _removeFromCart(p),
                                          icon: const Icon(Icons.remove_circle),
                                          color: cs.error,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Produk Baru'),
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