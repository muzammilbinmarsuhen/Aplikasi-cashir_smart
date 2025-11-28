import 'package:flutter/material.dart';
import '../screens/report_screen.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          transaction.id,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${transaction.date}\nKasir: ${transaction.cashier}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        trailing: Text(
          'Rp ${transaction.total.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          // TODO: Navigate to transaction detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detail transaksi ${transaction.id}')),
          );
        },
      ),
    );
  }
}