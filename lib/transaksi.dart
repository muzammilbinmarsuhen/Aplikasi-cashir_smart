import 'produk.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

// ====================== TRANSACTION PAGE ======================

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
      final items = cart.map((e) => {'product_id': e.product.id, 'qty': e.qty}).toList();
      final data = await api.checkout(items, paidAmount);
      final trx = Transaction.fromJson(data);
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