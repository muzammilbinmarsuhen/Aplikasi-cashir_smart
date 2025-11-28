import 'package:flutter/material.dart';
import '../widgets/transaction_card.dart';

// Model untuk Transaction
class Transaction {
  final String id;
  final String date;
  final String cashier;
  final int total;

  const Transaction({
    required this.id,
    required this.date,
    required this.cashier,
    required this.total,
  });
}

// Data dummy transaksi
final List<Transaction> dummyTransactions = [
  const Transaction(
    id: 'TRX-0001',
    date: '21 Nov 2024, 10:23',
    cashier: 'Andi',
    total: 75000,
  ),
  const Transaction(
    id: 'TRX-0002',
    date: '21 Nov 2024, 11:15',
    cashier: 'Budi',
    total: 45000,
  ),
  const Transaction(
    id: 'TRX-0003',
    date: '21 Nov 2024, 12:30',
    cashier: 'Citra',
    total: 92000,
  ),
  const Transaction(
    id: 'TRX-0004',
    date: '21 Nov 2024, 13:45',
    cashier: 'Andi',
    total: 38000,
  ),
  const Transaction(
    id: 'TRX-0005',
    date: '21 Nov 2024, 14:20',
    cashier: 'Budi',
    total: 125000,
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

  // Hitung total penjualan dari dummy data
  int get totalSales => dummyTransactions.fold(0, (sum, transaction) => sum + transaction.total);
  int get transactionCount => dummyTransactions.length;

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
      body: Column(
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
      ),
    );
  }
}