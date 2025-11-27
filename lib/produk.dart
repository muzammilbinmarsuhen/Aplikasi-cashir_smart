import 'dart:convert' as json;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  static const String baseUrl = 'http://localhost:8000/api';

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
    print('DEBUG: Attempting login to $url with email: $email');
    final res = await http.post(
      url,
      headers: _headers(),
      body: json.jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    print('DEBUG: Response status: ${res.statusCode}');
    print('DEBUG: Response body: ${res.body}');
    print('DEBUG: Response headers: ${res.headers}');

    if (res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      _token = data['token'];
      print('DEBUG: Login successful, token received');
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

  Future<Product> updateProduct(int id, Product p) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final res = await http.put(
      url,
      headers: _headers(withAuth: true),
      body: json.jsonEncode(p.toJson()),
    );
    if (res.statusCode == 200) {
      final data = json.jsonDecode(res.body);
      return Product.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Gagal mengupdate produk');
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

  Future<Map<String, dynamic>> checkout(
    List<Map<String, dynamic>> cartItems,
    int paidAmount,
  ) async {
    final url = Uri.parse('$baseUrl/transactions');
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
    } else {
      throw Exception('Gagal checkout: ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions({DateTime? date}) async {
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
      return list.cast<Map<String, dynamic>>();
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
          await api.updateProduct(product!.id!, p);
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: p.id == null
                                  ? null
                                  : () => _showProductDialog(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: p.id == null
                                  ? null
                                  : () => _confirmDelete(p),
                            ),
                          ],
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
              onPressed: _showProductDialog,
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