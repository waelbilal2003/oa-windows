import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/store_db_service.dart';
import 'daily_movement/purchases_screen.dart';
import 'daily_movement/sales_screen.dart';
import 'daily_movement/box_screen.dart';
import 'bait_screen.dart';
import 'daily_movement/invoice_type_selection_screen.dart';
import 'preferences_screen.dart';

class DailyMovementScreen extends StatefulWidget {
  final String selectedDate;
  final String storeType;
  final String sellerName;

  const DailyMovementScreen({
    super.key,
    required this.selectedDate,
    required this.storeType,
    required this.sellerName,
  });

  @override
  State<DailyMovementScreen> createState() => _DailyMovementScreenState();
}

class _DailyMovementScreenState extends State<DailyMovementScreen> {
  String _storeName = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadStoreName();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadStoreName() async {
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();
    setState(() {
      _storeName = savedStoreName ?? widget.storeType;
    });
  }

  void _handleBackButton() {
    Navigator.of(context).pop(); // نفس سلوك زر Escape
  }

  // ignore: unused_element
  void _handleEscapeKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _handleBackButton();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _handleBackButton();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // إخفاء سهم الرجوع
          titleSpacing: 0,
          toolbarHeight: 70,
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 140,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleBackButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'خروج',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Text(
                'الحركة اليومية لتاريخ ${widget.selectedDate}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(width: 140),
            ],
          ),
          centerTitle: true,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3)
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7.0, vertical: 10.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 500;

                      if (isSmallScreen) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMenuButton(
                                  context,
                                  icon: Icons.point_of_sale,
                                  label: 'المبيعات',
                                  color: Colors.orange[700]!,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => SalesScreen(
                                            sellerName: widget.sellerName,
                                            selectedDate: widget.selectedDate,
                                            storeName: _storeName),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.shopping_cart,
                                  label: 'المشتريات',
                                  color: Colors.red[700]!,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PurchasesScreen(
                                            sellerName: widget.sellerName,
                                            selectedDate: widget.selectedDate,
                                            storeName: _storeName),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.receipt_long,
                                  label: 'الفواتير',
                                  color: Colors.blueGrey[600]!,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InvoiceTypeSelectionScreen(
                                          selectedDate: widget.selectedDate,
                                          storeName: _storeName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.analytics,
                                  label: 'التفصيلات',
                                  color: Colors.blueGrey[700]!,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PreferencesScreen(
                                          selectedDate: widget.selectedDate,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.account_balance,
                                  label: 'الصندوق',
                                  color: Colors.indigo[700]!,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => BoxScreen(
                                            sellerName: widget.sellerName,
                                            selectedDate: widget.selectedDate,
                                            storeName: _storeName),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.inventory_2,
                                  label: 'البايت',
                                  color: Colors.teal[700]!,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => BaitScreen(
                                          selectedDate: widget.selectedDate,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildMenuButton(
                                      context,
                                      icon: Icons.point_of_sale,
                                      label: 'المبيعات',
                                      color: Colors.orange[700]!,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => SalesScreen(
                                                sellerName: widget.sellerName,
                                                selectedDate:
                                                    widget.selectedDate,
                                                storeName: _storeName),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 80.0),
                                    _buildMenuButton(
                                      context,
                                      icon: Icons.shopping_cart,
                                      label: 'المشتريات',
                                      color: Colors.red[700]!,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PurchasesScreen(
                                                    sellerName:
                                                        widget.sellerName,
                                                    selectedDate:
                                                        widget.selectedDate,
                                                    storeName: _storeName),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 80.0),
                                    _buildMenuButton(
                                      context,
                                      icon: Icons.receipt_long,
                                      label: 'الفواتير',
                                      color: Colors.blueGrey[600]!,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                InvoiceTypeSelectionScreen(
                                              selectedDate: widget.selectedDate,
                                              storeName: _storeName,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildMenuButton(
                                      context,
                                      icon: Icons.analytics,
                                      label: 'التفصيلات',
                                      color: Colors.blueGrey[700]!,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PreferencesScreen(
                                              selectedDate: widget.selectedDate,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 80.0),
                                    _buildMenuButton(
                                      context,
                                      icon: Icons.account_balance,
                                      label: 'الصندوق',
                                      color: Colors.indigo[700]!,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => BoxScreen(
                                                sellerName: widget.sellerName,
                                                selectedDate:
                                                    widget.selectedDate,
                                                storeName: _storeName),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 80.0),
                                    _buildMenuButton(
                                      context,
                                      icon: Icons.inventory_2,
                                      label: 'البايت',
                                      color: Colors.teal[700]!,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => BaitScreen(
                                              selectedDate: widget.selectedDate,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onTap}) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      shadowColor: color.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 350,
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
