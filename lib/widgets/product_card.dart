import 'package:flutter/material.dart';
import '../screens/product_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox untuk checkout
            Checkbox(
              value: widget.isSelected,
              onChanged: widget.product.isActive ? (value) {
                widget.onSelectionChanged(value ?? false);
              } : null,
              activeColor: Colors.blue,
            ),

            const SizedBox(width: 8),

            // Icon di kiri
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(33, 150, 243, 0.1),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.blue,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Konten tengah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama produk
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.product.isActive ? Colors.black : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Kategori dan kode
                  Text(
                    '${product.category}  •  Kode: ${product.code}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.product.isActive ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Stok (dummy)
                  Text(
                    'Stok: ${product.code}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.product.isActive ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            // Status chip di kanan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.product.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.product.isActive ? 'Aktif' : 'Tidak Aktif',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Product get product => widget.product;
}