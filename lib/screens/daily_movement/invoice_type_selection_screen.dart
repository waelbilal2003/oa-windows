import 'package:flutter/material.dart';
import './customer_selection_screen.dart';
import './supplier_selection_screen.dart';
import '../../widgets/exit_button.dart';

class InvoiceTypeSelectionScreen extends StatelessWidget {
  final String selectedDate;
  final String storeName;

  const InvoiceTypeSelectionScreen({
    Key? key,
    required this.selectedDate,
    required this.storeName,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ExitButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              'نوع التقرير',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(width: 140),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.person, size: 40),
                  label: const Text(
                    'فاتورة زبون',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerSelectionScreen(
                          selectedDate: selectedDate,
                          storeName: storeName,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout, size: 40),
                  label: const Text(
                    'مشتريات من مورد',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupplierSelectionScreen(
                          selectedDate: selectedDate,
                          storeName: storeName,
                          reportType: 'purchases',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
