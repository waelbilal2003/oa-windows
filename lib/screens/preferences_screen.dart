import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_preferences_screen.dart';
import 'supplier_preferences_screen.dart';
import '../services/customer_index_service.dart';
import '../services/supplier_index_service.dart';
import 'settings_screen.dart';
import 'opening_balances_screen.dart';
import 'account_summary_screen.dart';
import 'backup_screen_state.dart';
import '../widgets/exit_button.dart';

class PreferencesScreen extends StatefulWidget {
  final String selectedDate;
  const PreferencesScreen({super.key, required this.selectedDate});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final CustomerIndexService _customerIndexService = CustomerIndexService();
  final SupplierIndexService _supplierIndexService = SupplierIndexService();
  String _storeName = 'اسم المتجر';

  late List<FocusNode> _focusNodes;
  int _focusedIndex = 0;
  bool _isSmallScreen = false;
  final FocusNode _globalFocusNode = FocusNode();

  final List<Map<String, dynamic>> _buttons = [
    {
      'icon': Icons.account_balance,
      'label': 'تفصيلات\nالحساب',
      'color': Colors.indigo
    },
    {'icon': Icons.people, 'label': 'تفصيلات\nالزبائن', 'color': Colors.teal},
    {'icon': Icons.store, 'label': 'تفصيلات\nالموردين', 'color': Colors.brown},
    {
      'icon': Icons.attach_money,
      'label': 'أرصدة\nالبداية',
      'color': Colors.deepOrange
    },
    {
      'icon': Icons.backup,
      'label': 'النسخ\nالاحتياطي',
      'color': const Color(0xFF0F4C5C)
    },
    {'icon': Icons.settings, 'label': 'إعدادات\nأخرى', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
    // طلب التركيز بعد بناء الواجهة مباشرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
        _focusedIndex = 0;
        setState(() {});
      }
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountSummaryScreen(
              selectedDate: widget.selectedDate,
            ),
          ),
        );
        break;
      case 1:
        _customerIndexService.getAllCustomersWithData().then((customers) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerPreferencesListScreen(
                selectedDate: widget.selectedDate,
                customers: customers,
              ),
            ),
          );
        });
        break;
      case 2:
        _supplierIndexService.getAllSuppliersWithData().then((suppliers) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupplierPreferencesListScreen(
                selectedDate: widget.selectedDate,
                suppliers: suppliers,
              ),
            ),
          );
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpeningBalancesScreen(
              selectedDate: widget.selectedDate,
            ),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BackupScreen(),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsScreen(
              selectedDate: widget.selectedDate,
              storeName: _storeName,
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
                onTap: () {
                  _setFocus(index);
                  _executeCurrentFocus();
                },
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
          backgroundColor: Colors.blueGrey[600],
          foregroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Focus(
                canRequestFocus: false,
                skipTraversal: true,
                descendantsAreFocusable: false,
                child: ExitButton(
                  onPressed: _handleBackButton,
                ),
              ),
              const Text(
                'التفصيلات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
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
                        for (int i = 0; i < _buttons.length; i++)
                          Column(
                            children: [
                              _buildMenuButton(
                                icon: _buttons[i]['icon'] as IconData,
                                label: _buttons[i]['label'] as String,
                                color: (_buttons[i]['color'] is MaterialColor)
                                    ? (_buttons[i]['color']
                                        as MaterialColor)[700]!
                                    : _buttons[i]['color'] as Color,
                                index: i,
                              ),
                              if (i < _buttons.length - 1)
                                const SizedBox(height: 16),
                            ],
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
                              icon: _buttons[0]['icon'] as IconData,
                              label: _buttons[0]['label'] as String,
                              color:
                                  (_buttons[0]['color'] as MaterialColor)[700]!,
                              index: 0,
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: _buttons[1]['icon'] as IconData,
                              label: _buttons[1]['label'] as String,
                              color:
                                  (_buttons[1]['color'] as MaterialColor)[600]!,
                              index: 1,
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: _buttons[2]['icon'] as IconData,
                              label: _buttons[2]['label'] as String,
                              color:
                                  (_buttons[2]['color'] as MaterialColor)[600]!,
                              index: 2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMenuButton(
                              icon: _buttons[3]['icon'] as IconData,
                              label: _buttons[3]['label'] as String,
                              color:
                                  (_buttons[3]['color'] as MaterialColor)[700]!,
                              index: 3,
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: _buttons[4]['icon'] as IconData,
                              label: _buttons[4]['label'] as String,
                              color: const Color(0xFF0F4C5C),
                              index: 4,
                            ),
                            const SizedBox(width: 80),
                            _buildMenuButton(
                              icon: _buttons[5]['icon'] as IconData,
                              label: _buttons[5]['label'] as String,
                              color: Colors.grey[700]!,
                              index: 5,
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

// ── بطاقة رصيد زبون ──
class _CustomerBalanceCard extends StatefulWidget {
  final CustomerData customer;
  final Future<void> Function(double balance, String startDate) onSave;

  const _CustomerBalanceCard({required this.customer, required this.onSave});

  @override
  State<_CustomerBalanceCard> createState() => _CustomerBalanceCardState();
}

class _CustomerBalanceCardState extends State<_CustomerBalanceCard> {
  late TextEditingController _balanceController;
  late TextEditingController _startDateController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
        text: widget.customer.balance == 0
            ? ''
            : widget.customer.balance.toStringAsFixed(2));
    _startDateController =
        TextEditingController(text: widget.customer.startDate);
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.teal[700], size: 20),
                const SizedBox(width: 8),
                Text(widget.customer.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (widget.customer.isBalanceLocked) ...[
                  const Spacer(),
                  Icon(Icons.lock, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 4),
                  Text('مقفول',
                      style:
                          TextStyle(color: Colors.orange[700], fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _balanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    enabled: !widget.customer.isBalanceLocked,
                    decoration: InputDecoration(
                      labelText: 'الرصيد الابتدائي',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: widget.customer.isBalanceLocked,
                      fillColor: widget.customer.isBalanceLocked
                          ? Colors.grey[100]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'تاريخ البدء',
                      hintText: 'مثال: 2024/1/1',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final balance =
                              double.tryParse(_balanceController.text) ?? 0;
                          await widget.onSave(
                              balance, _startDateController.text.trim());
                          setState(() => _saving = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── بطاقة رصيد مورد ──
class _SupplierBalanceCard extends StatefulWidget {
  final SupplierData supplier;
  final Future<void> Function(double balance, String startDate) onSave;

  const _SupplierBalanceCard({required this.supplier, required this.onSave});

  @override
  State<_SupplierBalanceCard> createState() => _SupplierBalanceCardState();
}

class _SupplierBalanceCardState extends State<_SupplierBalanceCard> {
  late TextEditingController _balanceController;
  late TextEditingController _startDateController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
        text: widget.supplier.balance == 0
            ? ''
            : widget.supplier.balance.toStringAsFixed(2));
    _startDateController =
        TextEditingController(text: widget.supplier.startDate);
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.brown[700], size: 20),
                const SizedBox(width: 8),
                Text(widget.supplier.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (widget.supplier.isBalanceLocked) ...[
                  const Spacer(),
                  Icon(Icons.lock, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 4),
                  Text('مقفول',
                      style:
                          TextStyle(color: Colors.orange[700], fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _balanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    enabled: !widget.supplier.isBalanceLocked,
                    decoration: InputDecoration(
                      labelText: 'الرصيد الابتدائي',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: widget.supplier.isBalanceLocked,
                      fillColor: widget.supplier.isBalanceLocked
                          ? Colors.grey[100]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'تاريخ البدء',
                      hintText: 'مثال: 2024/1/1',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final balance =
                              double.tryParse(_balanceController.text) ?? 0;
                          await widget.onSave(
                              balance, _startDateController.text.trim());
                          setState(() => _saving = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- قائمة اختيار الزبون ----
class CustomerPreferencesListScreen extends StatelessWidget {
  final String selectedDate;
  final Map<int, CustomerData> customers;

  const CustomerPreferencesListScreen(
      {super.key, required this.selectedDate, required this.customers});

  @override
  Widget build(BuildContext context) {
    final list = customers.values.toList();
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
              'تفضيلات الزبائن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(width: 140),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: list.isEmpty
            ? const Center(
                child: Text('لا يوجد زبائن مسجلين.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)))
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final customer = list[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerPreferencesScreen(
                              customer: customer,
                              selectedDate: selectedDate,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        customer.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// ---- قائمة اختيار المورد ----
class SupplierPreferencesListScreen extends StatelessWidget {
  final String selectedDate;
  final Map<int, SupplierData> suppliers;

  const SupplierPreferencesListScreen(
      {super.key, required this.selectedDate, required this.suppliers});

  @override
  Widget build(BuildContext context) {
    final list = suppliers.values.toList();
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
              'تفضيلات الموردين',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(width: 140),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: list.isEmpty
            ? const Center(
                child: Text('لا يوجد موردين مسجلين.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)))
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final supplier = list[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupplierPreferencesScreen(
                              supplier: supplier,
                              selectedDate: selectedDate,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        supplier.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
