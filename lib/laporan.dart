import 'produk.dart';
import 'transaksi.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ====================== REPORTS / LAPORAN PAGE ======================

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime selectedDate = DateTime.now();
  late Future<List<Map<String, dynamic>>> _future;

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
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                final rawTxs = snapshot.data ?? [];
                final txs = rawTxs.map((e) => Transaction.fromJson(e)).toList();
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Penjualan Hari Ini',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Jumlah transaksi: ${txs.length}'),
                                ],
                              ),
                            ),
                            Text(
                              'Rp $total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ],
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
                            child: ExpansionTile(
                              title: Text('Invoice: ${t.invoiceNumber}'),
                              subtitle: Text(
                                  'Total: Rp ${t.totalAmount} • Bayar: Rp ${t.paidAmount} • Kembali: Rp ${t.changeAmount}'),
                              leading: const Icon(Icons.receipt_long),
                              trailing: Text(
                                DateFormat('HH:mm').format(t.createdAt),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Detail Transaksi',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      // Note: To show product details, need backend to include items in transaction response
                                      const Text('Produk: (Detail produk perlu endpoint tambahan dari backend)'),
                                      const Text('Kasir: (Belum diimplementasi)'),
                                      const Text('Pelanggan: (Belum diimplementasi)'),
                                    ],
                                  ),
                                ),
                              ],
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