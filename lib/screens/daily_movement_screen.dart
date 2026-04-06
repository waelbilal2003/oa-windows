// daily_movement_screen.dart - كامل وجاهز للنسخ

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
  late List<FocusNode> _focusNodes;
  int _focusedIndex = 0;
  bool _isSmallScreen = false;
  final FocusNode _globalFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadStoreName();
    _focusNodes = List.generate(6, (_) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      _focusedIndex = 0;
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    _globalFocusNode.dispose();
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
    Navigator.of(context).pop();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveFocusRight();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _moveFocusLeft();
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocusUp();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocusDown();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _executeCurrentFocus();
    } else if (key == LogicalKeyboardKey.escape) {
      _handleBackButton();
    }
  }

  void _moveFocusRight() {
    if (_isSmallScreen) return;
    int newIndex = _focusedIndex + 1;
    if (newIndex < 6 && newIndex % 3 != 0) {
      _setFocus(newIndex);
    }
  }

  void _moveFocusLeft() {
    if (_isSmallScreen) return;
    int newIndex = _focusedIndex - 1;
    if (newIndex >= 0 && (_focusedIndex % 3) != 0) {
      _setFocus(newIndex);
    }
  }

  void _moveFocusUp() {
    int newIndex = _isSmallScreen ? _focusedIndex - 1 : _focusedIndex - 3;
    if (newIndex >= 0) {
      _setFocus(newIndex);
    }
  }

  void _moveFocusDown() {
    int newIndex = _isSmallScreen ? _focusedIndex + 1 : _focusedIndex + 3;
    if (newIndex < 6) {
      _setFocus(newIndex);
    }
  }

  void _setFocus(int index) {
    setState(() {
      _focusedIndex = index;
      _focusNodes[index].requestFocus();
    });
  }

  void _executeCurrentFocus() {
    switch (_focusedIndex) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SalesScreen(
              sellerName: widget.sellerName,
              selectedDate: widget.selectedDate,
              storeName: _storeName,
            ),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PurchasesScreen(
              sellerName: widget.sellerName,
              selectedDate: widget.selectedDate,
              storeName: _storeName,
            ),
          ),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InvoiceTypeSelectionScreen(
              selectedDate: widget.selectedDate,
              storeName: _storeName,
            ),
          ),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreferencesScreen(
              selectedDate: widget.selectedDate,
            ),
          ),
        );
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BoxScreen(
              sellerName: widget.sellerName,
              selectedDate: widget.selectedDate,
              storeName: _storeName,
            ),
          ),
        );
        break;
      case 5:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BaitScreen(
              selectedDate: widget.selectedDate,
            ),
          ),
        );
        break;
    }
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    return Focus(
      focusNode: _focusNodes[index],
      child: Builder(
        builder: (context) {
          final hasFocus = _focusNodes[index].hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(hasFocus ? 1.05 : 1.0),
            child: Material(
              elevation: hasFocus ? 20 : 8,
              borderRadius: BorderRadius.circular(20),
              shadowColor: hasFocus ? Colors.amber : color.withOpacity(0.5),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 350,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasFocus
                          ? [Colors.amber.shade600, Colors.orange.shade800]
                          : [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: hasFocus
                        ? Border.all(color: Colors.white, width: 4)
                        : Border.all(color: Colors.transparent, width: 4),
                    boxShadow: hasFocus
                        ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.6),
                              blurRadius: 25,
                              spreadRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : [
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
                        size: hasFocus ? 52 : 42,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: hasFocus ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: hasFocus
                              ? [
                                  const Shadow(
                                      color: Colors.black26, blurRadius: 4)
                                ]
                              : null,
                        ),
                      ),
                      if (hasFocus)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: 40,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _globalFocusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          toolbarHeight: 70,
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 140,
                height: 80,
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  descendantsAreFocusable: false,
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              _isSmallScreen = constraints.maxWidth < 500;

              if (_isSmallScreen) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMenuButton(
                          icon: Icons.point_of_sale,
                          label: 'المبيعات',
                          color: Colors.orange[700]!,
                          index: 0,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SalesScreen(
                                  sellerName: widget.sellerName,
                                  selectedDate: widget.selectedDate,
                                  storeName: _storeName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          icon: Icons.shopping_cart,
                          label: 'المشتريات',
                          color: Colors.red[700]!,
                          index: 1,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PurchasesScreen(
                                  sellerName: widget.sellerName,
                                  selectedDate: widget.selectedDate,
                                  storeName: _storeName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          icon: Icons.receipt_long,
                          label: 'الفواتير',
                          color: Colors.blueGrey[600]!,
                          index: 2,
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
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          icon: Icons.analytics,
                          label: 'التفصيلات',
                          color: Colors.blueGrey[700]!,
                          index: 3,
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
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          icon: Icons.account_balance,
                          label: 'الصندوق',
                          color: Colors.indigo[700]!,
                          index: 4,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BoxScreen(
                                  sellerName: widget.sellerName,
                                  selectedDate: widget.selectedDate,
                                  storeName: _storeName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuButton(
                          icon: Icons.inventory_2,
                          label: 'البايت',
                          color: Colors.teal[700]!,
                          index: 5,
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
                              icon: Icons.point_of_sale,
                              label: 'المبيعات',
                              color: Colors.orange[700]!,
                              index: 0,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SalesScreen(
                                      sellerName: widget.sellerName,
                                      selectedDate: widget.selectedDate,
                                      storeName: _storeName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: Icons.shopping_cart,
                              label: 'المشتريات',
                              color: Colors.red[700]!,
                              index: 1,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PurchasesScreen(
                                      sellerName: widget.sellerName,
                                      selectedDate: widget.selectedDate,
                                      storeName: _storeName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: Icons.receipt_long,
                              label: 'الفواتير',
                              color: Colors.blueGrey[600]!,
                              index: 2,
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMenuButton(
                              icon: Icons.analytics,
                              label: 'التفصيلات',
                              color: Colors.blueGrey[700]!,
                              index: 3,
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
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: Icons.account_balance,
                              label: 'الصندوق',
                              color: Colors.indigo[700]!,
                              index: 4,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BoxScreen(
                                      sellerName: widget.sellerName,
                                      selectedDate: widget.selectedDate,
                                      storeName: _storeName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: Icons.inventory_2,
                              label: 'البايت',
                              color: Colors.teal[700]!,
                              index: 5,
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
    );
  }
}
