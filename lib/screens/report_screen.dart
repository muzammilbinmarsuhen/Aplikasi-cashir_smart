import 'package:flutter/material.dart';
import '../widgets/transaction_card.dart';
import '../models/cart_manager.dart';

// Model untuk Transaction
class Transaction {
  final String id;
  final String date;
  final String cashier;
  final int total;
  final List<CartItem> items;

  const Transaction({
    required this.id,
    required this.date,
    required this.cashier,
    required this.total,
    required this.items,
  });
}

// Data dummy transaksi
final List<Transaction> dummyTransactions = [
  Transaction(
    id: 'TRX-0001',
    date: '21 Nov 2024, 10:23',
    cashier: 'Andi',
    total: 75000,
    items: [
      const CartItem(id: '1', name: 'Nasi Goreng Special', quantity: 2, price: 25000),
      const CartItem(id: '2', name: 'Es Teh Manis', quantity: 1, price: 25000),
    ],
  ),
  Transaction(
    id: 'TRX-0002',
    date: '21 Nov 2024, 11:15',
    cashier: 'Budi',
    total: 45000,
    items: [
      const CartItem(id: '3', name: 'Ayam Bakar Madu', quantity: 1, price: 45000),
    ],
  ),
];

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  CartManager get cartManager => CartManager();

  // Check if there's a completed order
  bool get hasCompletedOrder => cartManager.selectedItems.isNotEmpty;

  // Hitung total penjualan dari dummy data
  int get totalSales => dummyTransactions.fold(0, (sum, transaction) => sum + transaction.total);
  int get transactionCount => dummyTransactions.length;

  // Current order details
  int get currentOrderTotal => cartManager.totalPrice;
  List<CartItem> get currentOrderItems => cartManager.selectedItems;

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: hasCompletedOrder ? _buildOrderResult() : _buildTransactionHistory(),
    );
  }

  Widget _buildOrderResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order completed header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pesanan Berhasil!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Total: Rp ${currentOrderTotal.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Order details
          const Text(
            'Detail Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Order items
          ...currentOrderItems.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    'Rp ${item.subtotal.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}',
                  ),
                ],
              ),
            ),
          )),

          const SizedBox(height: 16),

          // Back to products button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                cartManager.clearCart();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Kembali ke Produk'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      children: [
        // Date filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Dari Tanggal
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectStartDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Dari Tanggal',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sampai Tanggal
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectEndDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Sampai Tanggal',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Ringkasan penjualan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Total Penjualan: Rp ${totalSales.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jumlah Transaksi: $transactionCount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Daftar transaksi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dummyTransactions.length,
            itemBuilder: (context, index) {
              final transaction = dummyTransactions[index];
              return TransactionCard(transaction: transaction);
            },
          ),
        ),
      ],
    );
  }
}