import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/box_model.dart';
import '../../services/box_storage_service.dart';
import '../../widgets/table_components.dart' as TableComponents;
import '../../services/customer_index_service.dart';
import '../../services/supplier_index_service.dart';
import '../../widgets/suggestions_banner.dart';
import '../../widgets/exit_button.dart';
import '../../services/app_settings_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../services/sales_storage_service.dart';
import '../../services/purchase_storage_service.dart';

List<SuggestionItem> _customerSuggestionItems = [];
List<SuggestionItem> _supplierSuggestionItems = [];

class BoxScreen extends StatefulWidget {
  final String sellerName;
  final String selectedDate;
  final String storeName;

  const BoxScreen({
    Key? key,
    required this.sellerName,
    required this.selectedDate,
    required this.storeName,
  }) : super(key: key);

  @override
  _BoxScreenState createState() => _BoxScreenState();
}

class _BoxScreenState extends State<BoxScreen> {
  // خدمة التخزين
  final BoxStorageService _storageService = BoxStorageService();

  //  خدمة فهرس الزبائن
  final CustomerIndexService _customerIndexService = CustomerIndexService();
  // خدمة فهرس الموردين
  final SupplierIndexService _supplierIndexService = SupplierIndexService();

  List<String> _customerSuggestions = [];
  int? _activeCustomerRowIndex;
  final ScrollController _customerSuggestionsScrollController =
      ScrollController();

  // بيانات الحقول
  String dayName = '';

  // قائمة لتخزين صفوف الجدول
  List<List<TextEditingController>> rowControllers = [];
  List<List<FocusNode>> rowFocusNodes = [];
  List<String> accountTypeValues = [];
  List<String> sellerNames = []; // <-- تخزين اسم البائع لكل صف

  // متحكمات المجموع
  late TextEditingController totalReceivedController;
  late TextEditingController totalPaidController;

  // قوائم الخيارات
  final List<String> accountTypeOptions = ['مصروف', 'مورد', 'زبون'];

  // متحكمات للتمرير
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final _scrollController = ScrollController();

  // حالة الحفظ
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // التواريخ المتاحة
  List<Map<String, String>> _availableDates = [];
  bool _isLoadingDates = false;

  String serialNumber = '';
  // ignore: unused_field
  String? _currentJournalNumber;

  List<String> _supplierSuggestions = [];

  int? _activeSupplierRowIndex;

  bool _showFullScreenSuggestions = false;
  String _currentSuggestionType = '';
  late ScrollController
      _horizontalSuggestionsController; // في initState قم بتعريفه: _horizontalSuggestionsController = ScrollController();

  // ============ تحديث أرصدة الموردين والزبائن ============
  Map<String, double> customerBalanceChanges = {};
  Map<String, double> supplierBalanceChanges = {};

  // متغير لتأخير حساب المجاميع (debouncing)
  Timer? _calculateTotalsDebouncer;
  bool _isCalculating = false;
  bool _isAdmin = false;
  double? _lastFetchedBalance;
  double? _calculatedRemaining;
  String _lastAccountName = '';
  double _grandTotalReceived = 0.0;
  double _grandTotalPaid = 0.0;
// قائمة لتخزين نوع الصف: 'box' أو 'sales' أو 'purchase' (للتمييز عن السجلات المستوردة)
  List<String> rowSourceTypes = [];

  FocusNode? _addButtonFocusNode;
  int _currentFocusRow = -1;
  int _currentFocusCol = -1;

  @override
  void initState() {
    super.initState();
    dayName = _extractDayName(widget.selectedDate);

    totalReceivedController = TextEditingController();
    totalPaidController = TextEditingController();
    _resetTotalValues();

    _horizontalSuggestionsController = ScrollController();

    _verticalScrollController.addListener(() {
      _hideAllSuggestionsImmediately();
    });

    _horizontalScrollController.addListener(() {
      _hideAllSuggestionsImmediately();
    });

    _addButtonFocusNode = FocusNode(); // <-- إضافة

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus().then((_) {
        _loadOrCreateJournal();
      });
      _loadAvailableDates();
      _loadJournalNumber();
    });
  }

  @override
  void dispose() {
    _saveCurrentRecord(silent: true);
    for (var row in rowControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in rowFocusNodes) {
      for (var node in row) {
        node.dispose();
      }
    }
    totalReceivedController.dispose();
    totalPaidController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _scrollController.dispose();
    _customerSuggestionsScrollController.dispose();
    _horizontalSuggestionsController.dispose();
    _addButtonFocusNode?.dispose(); // <-- إضافة
    _calculateTotalsDebouncer?.cancel();
    super.dispose();
  }

  void _attachFocusListeners(int rowIndex) {
    for (int col = 0; col < rowFocusNodes[rowIndex].length; col++) {
      rowFocusNodes[rowIndex][col].removeListener(() {});
      rowFocusNodes[rowIndex][col].addListener(() {
        if (rowFocusNodes[rowIndex][col].hasFocus) {
          _currentFocusRow = rowIndex;
          _currentFocusCol = col;
          // اختياري: تمرير الخلية إلى المنطقة المرئية عند التركيز
          _scrollToField(rowIndex, col);
        }
      });
    }
  }

  void _moveFocus(int deltaRow, int deltaCol) {
    if (_currentFocusRow == -1 || _currentFocusCol == -1) {
      if (rowFocusNodes.isNotEmpty && rowFocusNodes[0].isNotEmpty) {
        _currentFocusRow = 0;
        _currentFocusCol = 0;
        FocusScope.of(context).requestFocus(rowFocusNodes[0][0]);
        _scrollToField(0, 0);
        _adjustScrollPosition(0);
      }
      return;
    }

    int newRow = _currentFocusRow + deltaRow;
    int newCol = _currentFocusCol + deltaCol;

    // حدود الصفوف
    if (newRow < 0) newRow = 0;
    if (newRow >= rowFocusNodes.length) newRow = rowFocusNodes.length - 1;

    // حدود الأعمدة: المقبوض(0) والمدفوع(1) فقط
    const int minCol = 0;
    const int maxCol = 1;
    if (newCol < minCol) newCol = minCol;
    if (newCol > maxCol) newCol = maxCol;

    FocusScope.of(context).requestFocus(rowFocusNodes[newRow][newCol]);
    _currentFocusRow = newRow;
    _currentFocusCol = newCol;

    _scrollToField(newRow, newCol);
    _adjustScrollPosition(newRow);
  }

  String _extractDayName(String dateString) {
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    final now = DateTime.now();
    return days[now.weekday % 7];
  }

  // تحميل التواريخ المتاحة
  Future<void> _loadAvailableDates() async {
    if (_isLoadingDates) return;

    setState(() {
      _isLoadingDates = true;
    });

    try {
      final dates = await _storageService.getAvailableDatesWithNumbers();
      setState(() {
        _availableDates = dates;
        _isLoadingDates = false;
      });
      _loadGrandTotal();
    } catch (e) {
      setState(() {
        _availableDates = [];
        _isLoadingDates = false;
      });
    }
  }

  Future<void> _loadGrandTotal() async {
    double totalRec = 0.0, totalPaid = 0.0;

    // 1. جمع أرصدة يوميات الصندوق (من المعاملات مباشرة وليس من الإجمالي المحفوظ)
    final boxDates = await _storageService.getAvailableDatesWithNumbers();
    for (var dateInfo in boxDates) {
      final doc =
          await _storageService.loadBoxDocumentForDate(dateInfo['date']!);
      if (doc != null) {
        // *** التعديل الرئيسي هنا: المرور على المعاملات لضمان الدقة ***
        for (var transaction in doc.transactions) {
          totalRec += double.tryParse(transaction.received) ?? 0;
          totalPaid += double.tryParse(transaction.paid) ?? 0;
        }
      }
    }

    // 2. جمع المبيعات النقدية من جميع التواريخ المتاحة
    final salesService = SalesStorageService();
    final salesDates = await salesService.getAllAvailableDates();
    for (var date in salesDates) {
      final salesDoc = await salesService.loadSalesDocument(date);
      if (salesDoc != null) {
        for (var sale in salesDoc.sales) {
          if (sale.cashOrDebt == 'نقدي') {
            totalRec += double.tryParse(sale.total) ?? 0;
          }
        }
      }
    }

    // 3. جمع المشتريات النقدية من جميع التواريخ المتاحة
    final purchaseService = PurchaseStorageService();
    final purchaseDates = await purchaseService.getAllAvailableDates();
    for (var date in purchaseDates) {
      final purchaseDoc = await purchaseService.loadPurchaseDocument(date);
      if (purchaseDoc != null) {
        for (var purchase in purchaseDoc.purchases) {
          if (purchase.cashOrDebt == 'نقدي') {
            totalPaid += double.tryParse(purchase.total) ?? 0;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _grandTotalReceived = totalRec;
        _grandTotalPaid = totalPaid;
      });
    }
  }

  // تحميل اليومية إذا كانت موجودة، أو إنشاء جديدة
  Future<void> _loadOrCreateJournal() async {
    final document =
        await _storageService.loadBoxDocumentForDate(widget.selectedDate);

    if (document != null && document.transactions.isNotEmpty) {
      _loadJournal(document);
    } else {
      _createNewJournal();
    }

    // بعد التحميل أو الإنشاء، نجلب السجلات النقدية من المبيعات والمشتريات
    await _loadCashTransactionsFromOtherJournals();
  }

  void _resetTotalValues() {
    totalReceivedController.text = '0.00';
    totalPaidController.text = '0.00';
  }

  void _createNewJournal() {
    setState(() {
      rowControllers.clear();
      rowFocusNodes.clear();
      accountTypeValues.clear();
      sellerNames.clear();
      rowSourceTypes.clear();
      _resetTotalValues();
      _hasUnsavedChanges = false;
      _addNewRow();
    });

    // طلب التركيز على زر الإضافة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addButtonFocusNode?.requestFocus(); // <-- إضافة
    });
  }

  void _addNewRow() {
    setState(() {
      List<TextEditingController> newControllers =
          List.generate(4, (index) => TextEditingController());
      List<FocusNode> newFocusNodes = List.generate(4, (index) => FocusNode());
      newFocusNodes[2].addListener(() {
        if (!newFocusNodes[2].hasFocus) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _supplierSuggestions = [];
                _activeSupplierRowIndex = null;
                _customerSuggestions = [];
                _activeCustomerRowIndex = null;
                _showFullScreenSuggestions = false;
                _currentSuggestionType = '';
              });
            }
          });
        }
      });

      _addChangeListenersToControllers(newControllers, rowControllers.length);
      sellerNames.add(widget.sellerName);
      rowControllers.add(newControllers);
      rowFocusNodes.add(newFocusNodes);
      accountTypeValues.add('');
      rowSourceTypes.add('box');
    });
    _attachFocusListeners(rowControllers.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newRowIndex = rowFocusNodes.length - 1;
      _currentFocusRow = newRowIndex;
      _currentFocusCol = 0;
      FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][0]);
      _scrollToField(newRowIndex, 0);
      _adjustScrollPosition(newRowIndex);
    });
  }

  // دالة مساعدة لإخفاء جميع الاقتراحات فوراً
  void _hideAllSuggestionsImmediately() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _customerSuggestions = [];
          _supplierSuggestions = [];
          _activeCustomerRowIndex = null;
          _activeSupplierRowIndex = null;
        });
      }
    });
  }

  // دالة مساعدة لإضافة المستمعات
  void _addChangeListenersToControllers(
      List<TextEditingController> controllers, int rowIndex) {
    // حقل المقبوض (index 0)
    controllers[0].addListener(() {
      _hasUnsavedChanges = true;
      if (controllers[0].text.isNotEmpty) {
        controllers[1].text = '';
      }
      _calculateAllTotals();
      _fetchAndCalculateBalance(rowIndex);
    });

    // حقل المدفوع (index 1)
    controllers[1].addListener(() {
      _hasUnsavedChanges = true;
      if (controllers[1].text.isNotEmpty) {
        controllers[0].text = '';
      }
      _calculateAllTotals();
      _fetchAndCalculateBalance(rowIndex);
    });

    // حقل اسم الحساب (index 2)
    controllers[2].addListener(() {
      _hasUnsavedChanges = true;

      if (accountTypeValues[rowIndex] == 'زبون') {
        _updateCustomerSuggestions(rowIndex);
      } else if (accountTypeValues[rowIndex] == 'مورد') {
        _updateSupplierSuggestions(rowIndex);
      }
    });

    // حقل الملاحظات (index 3)
    controllers[3].addListener(() => _hasUnsavedChanges = true);

    // إضافة مستمع FocusNode لحقل اسم الحساب
    if (rowIndex < rowFocusNodes.length && rowFocusNodes[rowIndex].length > 2) {
      rowFocusNodes[rowIndex][2].addListener(() {
        if (!rowFocusNodes[rowIndex][2].hasFocus) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _customerSuggestions = [];
                _supplierSuggestions = [];
                _activeCustomerRowIndex = null;
                _activeSupplierRowIndex = null;
                _showFullScreenSuggestions = false;
                _currentSuggestionType = '';
              });
            }
          });
        }
      });
    }
  }

  void _calculateAllTotals() {
    _calculateTotalsDebouncer?.cancel();

    _calculateTotalsDebouncer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted || _isCalculating) return;

      _isCalculating = true;

      double totalReceived = 0;
      double totalPaid = 0;

      for (var controllers in rowControllers) {
        try {
          totalReceived +=
              double.tryParse(controllers[0].text) ?? 0; // [0] مقبوض
          totalPaid += double.tryParse(controllers[1].text) ?? 0; // [1] مدفوع
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          totalReceivedController.text = totalReceived.toStringAsFixed(2);
          totalPaidController.text = totalPaid.toStringAsFixed(2);
        });
      }

      _isCalculating = false;
    });
  }

  // تعديل _loadJournal لاستخدام الدالة المساعدة
  void _loadJournal(BoxDocument document) {
    setState(() {
      for (var row in rowControllers) {
        for (var controller in row) {
          controller.dispose();
        }
      }
      for (var row in rowFocusNodes) {
        for (var node in row) {
          node.dispose();
        }
      }

      rowControllers.clear();
      rowFocusNodes.clear();
      accountTypeValues.clear();
      sellerNames.clear();
      rowSourceTypes.clear();

      for (int i = 0; i < document.transactions.length; i++) {
        var transaction = document.transactions[i];

        List<TextEditingController> newControllers = [
          TextEditingController(text: transaction.received),
          TextEditingController(text: transaction.paid),
          TextEditingController(text: transaction.accountName),
          TextEditingController(text: transaction.notes),
        ];

        List<FocusNode> newFocusNodes =
            List.generate(4, (index) => FocusNode());

        sellerNames.add(transaction.sellerName);
        rowSourceTypes.add('box');

        final bool isOwnedByCurrentSeller =
            transaction.sellerName == widget.sellerName;

        if (isOwnedByCurrentSeller) {
          _addChangeListenersToControllers(newControllers, i);
        }

        rowControllers.add(newControllers);
        rowFocusNodes.add(newFocusNodes);
        accountTypeValues.add(transaction.accountType);
      }

      // ربط مستمعات التركيز لكل الصفوف المحملة
      for (int i = 0; i < rowFocusNodes.length; i++) {
        _attachFocusListeners(i); // <-- إضافة
      }

      if (document.totals.isNotEmpty) {
        totalReceivedController.text =
            document.totals['totalReceived'] ?? '0.00';
        totalPaidController.text = document.totals['totalPaid'] ?? '0.00';
      }

      _hasUnsavedChanges = false;
    });
  }

  void _scrollToField(int rowIndex, int colIndex) {
    const double headerHeight = 32.0;
    const double rowHeight = 25.0;
    final double verticalPosition = (rowIndex * rowHeight);
    final double verticalTarget = (verticalPosition + headerHeight)
        .clamp(0, _verticalScrollController.position.maxScrollExtent);

    const double columnWidth =
        80.0; // في BoxScreen استخدم 80.0، في PurchasesScreen 80.0، في SalesScreen 60.0
    final double horizontalPosition = colIndex * columnWidth;
    final double horizontalTarget = horizontalPosition.clamp(
        0, _horizontalScrollController.position.maxScrollExtent);

    _verticalScrollController.animateTo(
      verticalTarget,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );

    _horizontalScrollController.animateTo(
      horizontalTarget,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTableHeader() {
    return Table(
      columnWidths: {
        0: FlexColumnWidth(0.2), // مقبوض
        1: FlexColumnWidth(0.2), // مدفوع
        2: FlexColumnWidth(0.4), // الحساب
        3: FlexColumnWidth(0.2), // ملاحظات
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            TableComponents.buildTableHeaderCell('مقبوض'),
            TableComponents.buildTableHeaderCell('مدفوع'),
            TableComponents.buildTableHeaderCell('الحساب'),
            TableComponents.buildTableHeaderCell('ملاحظات'),
          ],
        ),
      ],
    );
  }

  Widget _buildTableContent() {
    List<TableRow> contentRows = [];

    for (int i = 0; i < rowControllers.length; i++) {
      final bool isOwnedByCurrentSeller = sellerNames[i] == widget.sellerName;
      final String sourceType =
          (i < rowSourceTypes.length) ? rowSourceTypes[i] : 'box';
      final bool isReadOnly = sourceType == 'sales' || sourceType == 'purchase';

      Color? rowColor;
      if (sourceType == 'sales') {
        rowColor = Colors.green[50];
      } else if (sourceType == 'purchase') {
        rowColor = Colors.orange[50];
      }

      contentRows.add(
        TableRow(
          decoration: rowColor != null ? BoxDecoration(color: rowColor) : null,
          children: [
            _buildReceivedCell(rowControllers[i][0], rowFocusNodes[i][0], i, 0,
                !isReadOnly && isOwnedByCurrentSeller),
            _buildPaidCell(rowControllers[i][1], rowFocusNodes[i][1], i, 1,
                !isReadOnly && isOwnedByCurrentSeller),
            _buildAccountCell(i, 2, !isReadOnly && isOwnedByCurrentSeller),
            _buildNotesCell(rowControllers[i][3], rowFocusNodes[i][3], i, 3,
                !isReadOnly && isOwnedByCurrentSeller),
          ],
        ),
      );
    }

    if (rowControllers.length >= 1) {
      contentRows.add(
        TableRow(
          decoration: BoxDecoration(color: Colors.yellow[50]),
          children: [
            TableComponents.buildTotalCell(totalReceivedController),
            TableComponents.buildTotalCell(totalPaidController),
            TableComponents.buildTotalLabelCell(''), // الحساب (فارغ)
            TableComponents.buildTotalLabelCell(''), // ملاحظات (فارغ)
          ],
        ),
      );
    }

    return Table(
      columnWidths: {
        0: FlexColumnWidth(0.2), // مقبوض
        1: FlexColumnWidth(0.2), // مدفوع
        2: FlexColumnWidth(0.4), // الحساب
        3: FlexColumnWidth(0.2), // ملاحظات
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: contentRows,
    );
  }

  Widget _buildReceivedCell(
      TextEditingController controller,
      FocusNode focusNode,
      int rowIndex,
      int colIndex,
      bool isOwnedByCurrentSeller) {
    Widget cell = Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // يُعطَّل فقط إذا كان حقل المدفوع [1] ممتلئاً
        enabled:
            isOwnedByCurrentSeller && rowControllers[rowIndex][1].text.isEmpty,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '0.00',
        ),
        inputFormatters: [
          TableComponents.PositiveDecimalInputFormatter(),
          FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
        ],
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _showAccountTypeDialog(rowIndex);
          } else {
            FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
          }
        },
        onChanged: (value) {
          _hasUnsavedChanges = true;
          if (value.isNotEmpty && mounted) {
            setState(() {
              rowControllers[rowIndex][1].text = ''; // يمسح المدفوع [1]
            });
          }
          _calculateAllTotals();
        },
      ),
    );

    if (!isOwnedByCurrentSeller) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7,
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[100]),
            child: cell,
          ),
        ),
      );
    }

    return cell;
  }

  Widget _buildPaidCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex, bool isOwnedByCurrentSeller) {
    Widget cell = Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // يُعطَّل فقط إذا كان حقل المقبوض [0] ممتلئاً
        enabled:
            isOwnedByCurrentSeller && rowControllers[rowIndex][0].text.isEmpty,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '0.00',
        ),
        inputFormatters: [
          TableComponents.PositiveDecimalInputFormatter(),
          FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
        ],
        onSubmitted: (value) {
          _showAccountTypeDialog(rowIndex);
        },
        onChanged: (value) {
          _hasUnsavedChanges = true;
          if (value.isNotEmpty && mounted) {
            setState(() {
              rowControllers[rowIndex][0].text = ''; // يمسح المقبوض [0]
            });
          }
          _calculateAllTotals();
        },
      ),
    );

    if (!isOwnedByCurrentSeller) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7,
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[100]),
            child: cell,
          ),
        ),
      );
    }

    return cell;
  }

  // تحديث خلية الحساب لدعم كلا النوعين
  Widget _buildAccountCell(
      int rowIndex, int colIndex, bool isOwnedByCurrentSeller) {
    final bool canEdit = _canEditRow(rowIndex);
    final String accountType = accountTypeValues[rowIndex];
    final TextEditingController accountNameController =
        rowControllers[rowIndex][2]; // index 2
    final FocusNode accountNameFocusNode = rowFocusNodes[rowIndex][2];

    Widget cellContent;

    if (accountType.isNotEmpty) {
      cellContent = Container(
        padding: const EdgeInsets.all(1),
        constraints: const BoxConstraints(minHeight: 25),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: canEdit ? () => _showAccountTypeDialog(rowIndex) : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _getAccountTypeColor(accountType),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    color: _getAccountTypeColor(accountType).withOpacity(0.1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Center(
                    child: Text(
                      accountType,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getAccountTypeColor(accountType),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 5,
              child: TextField(
                controller: accountNameController,
                focusNode: accountNameFocusNode,
                textAlign: TextAlign.right,
                enabled: canEdit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  hintText: _getAccountHintText(accountType),
                  hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                  isDense: true,
                ),
                onSubmitted: (value) =>
                    _handleFieldSubmitted(value, rowIndex, colIndex),
                onChanged: (value) {
                  _hasUnsavedChanges = true;
                  if (accountType == 'زبون') {
                    _updateCustomerSuggestions(rowIndex);
                  } else if (accountType == 'مورد') {
                    _updateSupplierSuggestions(rowIndex);
                  }
                },
              ),
            ),
          ],
        ),
      );
    } else {
      cellContent = Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(3),
          color: Colors.grey[50],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canEdit ? () => _showAccountTypeDialog(rowIndex) : null,
            borderRadius: BorderRadius.circular(3),
            child: Container(
              constraints: const BoxConstraints(minHeight: 25),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('اختر النوع',
                      style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                  Icon(Icons.arrow_drop_down, size: 16, color: Colors.blueGrey),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!canEdit) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: Container(
            color: Colors.grey[100],
            child: cellContent,
          ),
        ),
      );
    }

    return cellContent;
  }

  Widget _buildNotesCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex, bool isOwnedByCurrentSeller) {
    Widget cell = Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        enabled: isOwnedByCurrentSeller,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '...',
        ),
        onSubmitted: (value) {
          if (isOwnedByCurrentSeller) {
            // إضافة صف جديد بنفس آلية زر الإضافة
            _addNewRow();
            // بعد إضافة الصف، ننتظر اكتمال بناء الواجهة ثم ننقل التركيز إلى حقل المقبوض (index 0)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && rowFocusNodes.isNotEmpty) {
                final newRowIndex = rowFocusNodes.length - 1;
                _currentFocusRow = newRowIndex;
                _currentFocusCol = 0;
                FocusScope.of(context)
                    .requestFocus(rowFocusNodes[newRowIndex][0]);
                _scrollToField(newRowIndex, 0);
                _adjustScrollPosition(newRowIndex);
              }
            });
          }
        },
        onChanged: (value) {
          if (isOwnedByCurrentSeller) {
            _hasUnsavedChanges = true;
          }
        },
      ),
    );

    if (!isOwnedByCurrentSeller) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            child: cell,
          ),
        ),
      );
    }

    return cell;
  }

  Color _getAccountTypeColor(String accountType) {
    switch (accountType) {
      case 'زبون':
        return Colors.green;
      case 'مورد':
        return Colors.blue;
      case 'مصروف':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAccountHintText(String accountType) {
    switch (accountType) {
      case 'زبون':
        return 'اسم الزبون';
      case 'مورد':
        return 'اسم المورد';
      case 'مصروف':
        return 'نوع المصروف';
      default:
        return '...';
    }
  }

  void _handleFieldSubmitted(String value, int rowIndex, int colIndex) {
    if (!_canEditRow(rowIndex)) {
      return;
    }

    if (colIndex == 0) {
      // مقبوض
      if (value.isNotEmpty) {
        _showAccountTypeDialog(rowIndex);
      } else {
        _currentFocusRow = rowIndex;
        _currentFocusCol = 1;
        FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
      }
    } else if (colIndex == 1) {
      // مدفوع
      _showAccountTypeDialog(rowIndex);
    } else if (colIndex == 2) {
      // الحساب
      if (accountTypeValues[rowIndex] == 'زبون' &&
          _customerSuggestions.isNotEmpty) {
        _selectCustomerSuggestion(_customerSuggestions[0], rowIndex);
        _saveCurrentRecord(silent: true, reloadAfterSave: false);
        return;
      }

      if (accountTypeValues[rowIndex] == 'مورد' &&
          _supplierSuggestions.isNotEmpty) {
        _selectSupplierSuggestion(_supplierSuggestions[0], rowIndex);
        _saveCurrentRecord(silent: true, reloadAfterSave: false);
        return;
      }

      _saveCurrentRecord(silent: true, reloadAfterSave: false).then((_) {
        if (mounted) {
          _fetchAndCalculateBalance(rowIndex);
        }
      });

      if (value.trim().isNotEmpty && value.trim().length > 1) {
        if (accountTypeValues[rowIndex] == 'زبون') {
          _saveCustomerToIndex(value);
        } else if (accountTypeValues[rowIndex] == 'مورد') {
          _saveSupplierToIndex(value);
        }
      }
      _currentFocusRow = rowIndex;
      _currentFocusCol = 3;
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][3]);
    } else if (colIndex == 3) {
      // ملاحظات - إنشاء صف جديد والتركيز على حقل المقبوض (بنفس آلية زر الإضافة)
      _addNewRow();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && rowFocusNodes.isNotEmpty) {
          final newRowIndex = rowFocusNodes.length - 1;
          _currentFocusRow = newRowIndex;
          _currentFocusCol = 0;
          FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][0]);
          _scrollToField(newRowIndex, 0);
          _adjustScrollPosition(newRowIndex);
        }
      });
    }
  }

  void _showAccountTypeDialog(int rowIndex) {
    if (!_canEditRow(rowIndex)) {
      return;
    }

    int selectedIndex = accountTypeOptions.indexOf(accountTypeValues[rowIndex]);
    if (selectedIndex == -1) selectedIndex = 0;

    final FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return RawKeyboardListener(
              focusNode: focusNode,
              autofocus: true,
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  // في الواجهة العربية: السهم الأيمن يتحرك لليسار بصرياً (للخلف في القائمة)
                  // والسهم الأيسر يتحرك لليمين بصرياً (للأمام في القائمة)
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    setState(() {
                      selectedIndex =
                          (selectedIndex - 1 + accountTypeOptions.length) %
                              accountTypeOptions.length;
                    });
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    setState(() {
                      selectedIndex =
                          (selectedIndex + 1) % accountTypeOptions.length;
                    });
                  } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                    Navigator.of(context).pop();
                    _onAccountTypeSelected(
                        accountTypeOptions[selectedIndex], rowIndex);
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop();
                    _onAccountTypeCancelled(rowIndex);
                  }
                }
              },
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  child: Container(
                    width: 400,
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // العنوان باللون الأزرق ومحاذاة لليمين
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 14, 82, 184),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'اختر نوع الحساب',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.account_balance_wallet,
                                    color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                        ),
                        // الخيارات (ChoiceChip) - ترتيب معكوس ليتناسب مع العربية
                        // الخيارات (ChoiceChip) مع التصحيح
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12.0,
                            runSpacing: 12.0,
                            textDirection:
                                TextDirection.rtl, // ✅ هذا السطر هو الحل
                            children: List.generate(accountTypeOptions.length,
                                (index) {
                              final isSelected = selectedIndex == index;
                              final option = accountTypeOptions[index];
                              Color chipColor;
                              switch (option) {
                                case 'زبون':
                                  chipColor = Colors.green;
                                  break;
                                case 'مورد':
                                  chipColor = Colors.blue;
                                  break;
                                case 'مصروف':
                                  chipColor = Colors.red;
                                  break;
                                default:
                                  chipColor = Colors.grey;
                              }
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _onAccountTypeSelected(option, rowIndex);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      border: isSelected
                                          ? Border.all(
                                              color: chipColor, width: 2)
                                          : null,
                                    ),
                                    child: ChoiceChip(
                                      label: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : chipColor,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: chipColor,
                                      backgroundColor:
                                          chipColor.withOpacity(0.1),
                                      elevation: 2,
                                      pressElevation: 4,
                                      onSelected: (bool selected) {
                                        if (selected) {
                                          Navigator.of(context).pop();
                                          _onAccountTypeSelected(
                                              option, rowIndex);
                                        }
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
                                        side: BorderSide(
                                            color: chipColor, width: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // الأزرار
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      focusNode.dispose();
    });
  }

  void _onAccountTypeSelected(String value, int rowIndex) {
    setState(() {
      accountTypeValues[rowIndex] = value;
      _hasUnsavedChanges = true;

      // إخفاء الاقتراحات عند تغيير نوع الحساب
      _customerSuggestions = [];
      _supplierSuggestions = [];
      _activeCustomerRowIndex = null;
      _activeSupplierRowIndex = null;

      if (value.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][2]);
            _scrollToField(rowIndex, 2);
          }
        });
      }
    });
  }

  void _onAccountTypeCancelled(int rowIndex) {
    if (rowControllers[rowIndex][1].text.isNotEmpty) {
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
    } else if (rowControllers[rowIndex][2].text.isNotEmpty) {
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][2]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 82, 184),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ExitButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Focus(
                  focusNode: _addButtonFocusNode,
                  child: SizedBox(
                    width: 140,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () {
                        _addNewRow();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (rowFocusNodes.isNotEmpty) {
                            final newRowIndex = rowFocusNodes.length - 1;
                            FocusScope.of(context)
                                .requestFocus(rowFocusNodes[newRowIndex][0]);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 14, 82, 184),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'إضافة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showFullScreenSuggestions &&
                _getSuggestionsByType().isNotEmpty)
              Expanded(
                child: SuggestionsBanner(
                  suggestions: _getSuggestionsByType(),
                  type: _currentSuggestionType,
                  currentRowIndex: _getCurrentRowIndexByType(),
                  scrollController: _horizontalSuggestionsController,
                  onSelect: (val, idx) {
                    if (_currentSuggestionType == 'customer')
                      _selectCustomerSuggestion(val, idx);
                    if (_currentSuggestionType == 'supplier')
                      _selectSupplierSuggestion(val, idx);
                  },
                  onClose: () =>
                      _toggleFullScreenSuggestions(type: '', show: false),
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'الصندوق - ${widget.selectedDate}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('الرصيد الكلي: ',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70)),
                          Text(
                            (_grandTotalReceived - _grandTotalPaid)
                                .toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  (_grandTotalReceived - _grandTotalPaid) >= 0
                                      ? Colors.lightGreenAccent
                                      : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 60),
                  tooltip: 'تصدير PDF',
                  onPressed: () => _generateAndSharePdf(),
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.calendar_month, size: 60),
                  tooltip: 'فتح يومية سابقة',
                  padding: const EdgeInsets.all(8),
                  onSelected: (selectedDate) async {
                    if (selectedDate != widget.selectedDate) {
                      if (_hasUnsavedChanges) {
                        final shouldSave = await _showUnsavedChangesDialog();
                        if (shouldSave) {
                          await _saveCurrentRecord(silent: true);
                        }
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoxScreen(
                            sellerName: widget.sellerName,
                            selectedDate: selectedDate,
                            storeName: widget.storeName,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> items = [];
                    if (_isLoadingDates) {
                      items.add(const PopupMenuItem<String>(
                        value: '',
                        enabled: false,
                        child: Text('جاري التحميل...'),
                      ));
                    } else if (_availableDates.isEmpty) {
                      items.add(const PopupMenuItem<String>(
                        value: '',
                        enabled: false,
                        child: Text('لا توجد يوميات سابقة'),
                      ));
                    } else {
                      items.add(const PopupMenuItem<String>(
                        value: '',
                        enabled: false,
                        child: Text(
                          'اليوميات المتاحة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ));
                      items.add(const PopupMenuDivider());
                      for (var dateInfo in _availableDates) {
                        final date = dateInfo['date']!;
                        items.add(PopupMenuItem<String>(
                          value: date,
                          child: Text(
                            'يومية تاريخ $date',
                            style: TextStyle(
                              fontWeight: date == widget.selectedDate
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: date == widget.selectedDate
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ));
                      }
                    }
                    return items;
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              final focusedNode = FocusScope.of(context).focusedChild;
              if (focusedNode == null || focusedNode == _addButtonFocusNode) {
                _addNewRow();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (rowFocusNodes.isNotEmpty) {
                    final newRowIndex = rowFocusNodes.length - 1;
                    FocusScope.of(context)
                        .requestFocus(rowFocusNodes[newRowIndex][0]);
                  }
                });
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _moveFocus(0, -1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _moveFocus(0, 1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _moveFocus(1, 0);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _moveFocus(-1, 0);
            }
          }
        },
        child: _buildMainContent(),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildTableWithStickyHeader() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        controller: _verticalScrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _StickyTableHeaderDelegate(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                ),
                child: _buildTableHeader(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: _buildTableContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentRecord(
      {bool silent = false, bool reloadAfterSave = true}) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final List<BoxTransaction> allTransFromUI = [];
    for (int i = 0; i < rowControllers.length; i++) {
      if (i < rowSourceTypes.length &&
          (rowSourceTypes[i] == 'sales' || rowSourceTypes[i] == 'purchase')) {
        continue;
      }

      final controllers = rowControllers[i];
      if (controllers[0].text.isNotEmpty ||
          controllers[1].text.isNotEmpty ||
          controllers[2].text.isNotEmpty) {
        final t = BoxTransaction(
          serialNumber: (allTransFromUI.length + 1).toString(),
          received: controllers[0].text,
          paid: controllers[1].text,
          accountType: accountTypeValues[i],
          accountName: controllers[2].text.trim(),
          notes: controllers[3].text,
          sellerName: sellerNames[i],
        );
        allTransFromUI.add(t);
      }
    }

    // 2. منطق تحديث الأرصدة الجديد (الإلغاء ثم التطبيق)
    Map<String, double> customerBalanceChanges = {};
    Map<String, double> supplierBalanceChanges = {};
    final existingDoc =
        await _storageService.loadBoxDocumentForDate(widget.selectedDate);

    // الخطوة أ: إلغاء أثر جميع معاملات الصندوق القديمة لهذا البائع
    if (existingDoc != null) {
      for (var oldTrans in existingDoc.transactions) {
        if (oldTrans.sellerName == widget.sellerName &&
            oldTrans.accountName.isNotEmpty) {
          double oldReceived = double.tryParse(oldTrans.received) ?? 0;
          double oldPaid = double.tryParse(oldTrans.paid) ?? 0;

          if (oldTrans.accountType == 'زبون') {
            double effect = oldPaid - oldReceived;
            customerBalanceChanges[oldTrans.accountName] =
                (customerBalanceChanges[oldTrans.accountName] ?? 0) - effect;
          } else if (oldTrans.accountType == 'مورد') {
            double effect = oldReceived - oldPaid;
            supplierBalanceChanges[oldTrans.accountName] =
                (supplierBalanceChanges[oldTrans.accountName] ?? 0) - effect;
          }
        }
      }
    }

    // الخطوة ب: تطبيق أثر جميع معاملات الصندوق الجديدة من الواجهة
    for (var newTrans in allTransFromUI) {
      if (newTrans.sellerName == widget.sellerName &&
          newTrans.accountName.isNotEmpty) {
        double newReceived = double.tryParse(newTrans.received) ?? 0;
        double newPaid = double.tryParse(newTrans.paid) ?? 0;

        if (newTrans.accountType == 'زبون') {
          double effect = newPaid - newReceived;
          customerBalanceChanges[newTrans.accountName] =
              (customerBalanceChanges[newTrans.accountName] ?? 0) + effect;
        } else if (newTrans.accountType == 'مورد') {
          double effect = newReceived - newPaid;
          supplierBalanceChanges[newTrans.accountName] =
              (supplierBalanceChanges[newTrans.accountName] ?? 0) + effect;
        }
      }
    }

    // 3. بناء الوثيقة النهائية للحفظ
    double tReceived = allTransFromUI.fold(
        0, (sum, t) => sum + (double.tryParse(t.received) ?? 0));
    double tPaid = allTransFromUI.fold(
        0, (sum, t) => sum + (double.tryParse(t.paid) ?? 0));

    final documentToSave = BoxDocument(
      recordNumber: serialNumber,
      date: widget.selectedDate,
      sellerName: "Multiple Sellers",
      storeName: widget.storeName,
      dayName: dayName,
      transactions: allTransFromUI,
      totals: {
        'totalReceived': tReceived.toStringAsFixed(2),
        'totalPaid': tPaid.toStringAsFixed(2),
      },
    );

    // 4. الحفظ في الملف وتحديث الأرصدة
    final success = await _storageService.saveBoxDocument(documentToSave);

    if (success) {
      for (var entry in customerBalanceChanges.entries) {
        if (entry.value != 0) {
          await _customerIndexService.updateCustomerBalance(
              entry.key, entry.value);
        }
      }
      for (var entry in supplierBalanceChanges.entries) {
        if (entry.value != 0) {
          await _supplierIndexService.updateSupplierBalance(
              entry.key, entry.value);
        }
      }

      setState(() => _hasUnsavedChanges = false);
      if (reloadAfterSave) {
        await _loadOrCreateJournal();
      }
      await _loadAvailableDates();
    }

    setState(() => _isSaving = false);
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'تم الحفظ بنجاح' : 'فشل الحفظ'),
          backgroundColor: success ? Colors.green : Colors.red));
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تغييرات غير محفوظة'),
            content: const Text(
              'هناك تغييرات غير محفوظة. هل تريد حفظها قبل الانتقال؟',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تجاهل'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _loadJournalNumber() async {
    try {
      final journalNumber =
          await _storageService.getJournalNumberForDate(widget.selectedDate);
      setState(() {
        serialNumber = journalNumber;
        _currentJournalNumber = journalNumber;
      });
    } catch (e) {
      setState(() {
        serialNumber = '1';
        _currentJournalNumber = '1';
      });
    }
  }

  // تحديث اقتراحات الزبائن
  void _updateCustomerSuggestions(int rowIndex) async {
    final query = rowControllers[rowIndex][2].text;
    if (query.length >= 1 && accountTypeValues[rowIndex] == 'زبون') {
      final allWithNumbers =
          await _customerIndexService.getAllCustomersWithNumbers();
      final normalizedQuery = query.toLowerCase().trim();

      List<SuggestionItem> displaySuggestions = [];

      if (RegExp(r'^\d+$').hasMatch(query.trim())) {
        final int? queryNumber = int.tryParse(query.trim());
        if (queryNumber != null && allWithNumbers.containsKey(queryNumber)) {
          displaySuggestions = [
            SuggestionItem(
                number: queryNumber, name: allWithNumbers[queryNumber]!)
          ];
        }
      } else {
        displaySuggestions = allWithNumbers.entries
            .where((e) => e.value.toLowerCase().contains(normalizedQuery))
            .map((e) => SuggestionItem(number: e.key, name: e.value))
            .toList();
      }

      if (mounted) {
        setState(() {
          _customerSuggestionItems = displaySuggestions;
          _customerSuggestions =
              displaySuggestions.map((e) => e.displayName).toList();
          _activeCustomerRowIndex = rowIndex;
          _toggleFullScreenSuggestions(
              type: 'customer', show: displaySuggestions.isNotEmpty);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _customerSuggestions = [];
          _customerSuggestionItems = [];
          _activeCustomerRowIndex = null;
          _toggleFullScreenSuggestions(type: 'customer', show: false);
        });
      }
    }
  }

// تحديث اقتراحات الموردين
  void _updateSupplierSuggestions(int rowIndex) async {
    final query = rowControllers[rowIndex][2].text;
    if (query.length >= 1 && accountTypeValues[rowIndex] == 'مورد') {
      final allWithNumbers =
          await _supplierIndexService.getAllSuppliersWithNumbers();
      final normalizedQuery = query.toLowerCase().trim();

      List<SuggestionItem> displaySuggestions = [];

      if (RegExp(r'^\d+$').hasMatch(query.trim())) {
        final int? queryNumber = int.tryParse(query.trim());
        if (queryNumber != null && allWithNumbers.containsKey(queryNumber)) {
          displaySuggestions = [
            SuggestionItem(
                number: queryNumber, name: allWithNumbers[queryNumber]!)
          ];
        }
      } else {
        displaySuggestions = allWithNumbers.entries
            .where((e) => e.value.toLowerCase().contains(normalizedQuery))
            .map((e) => SuggestionItem(number: e.key, name: e.value))
            .toList();
      }

      if (mounted) {
        setState(() {
          _supplierSuggestionItems = displaySuggestions;
          _supplierSuggestions =
              displaySuggestions.map((e) => e.displayName).toList();
          _activeSupplierRowIndex = rowIndex;
          _toggleFullScreenSuggestions(
              type: 'supplier', show: displaySuggestions.isNotEmpty);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _supplierSuggestions = [];
          _supplierSuggestionItems = [];
          _activeSupplierRowIndex = null;
          _toggleFullScreenSuggestions(type: 'supplier', show: false);
        });
      }
    }
  }

  void _selectCustomerSuggestion(String suggestion, int rowIndex) {
    setState(() {
      _customerSuggestions = [];
      _customerSuggestionItems = [];
      _activeCustomerRowIndex = null;
      _showFullScreenSuggestions = false;
      _currentSuggestionType = '';
    });

    final actualName = _extractNameFromSuggestion(suggestion);
    rowControllers[rowIndex][2].text = actualName;
    _hasUnsavedChanges = true;

    if (actualName.trim().length > 1) {
      _customerIndexService.saveCustomer(
        actualName.trim(),
        startDate: widget.selectedDate,
      );
    }

    _fetchAndCalculateBalance(rowIndex);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][3]);
      }
    });
  }

  void _selectSupplierSuggestion(String suggestion, int rowIndex) {
    setState(() {
      _supplierSuggestions = [];
      _supplierSuggestionItems = [];
      _activeSupplierRowIndex = null;
      _showFullScreenSuggestions = false;
      _currentSuggestionType = '';
    });

    final actualName = _extractNameFromSuggestion(suggestion);
    rowControllers[rowIndex][2].text = actualName;
    _hasUnsavedChanges = true;

    if (actualName.trim().length > 1) {
      _supplierIndexService.saveSupplier(
        actualName.trim(),
        startDate: widget.selectedDate,
      );
    }

    _fetchAndCalculateBalance(rowIndex);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][3]);
      }
    });
  }

  void _saveCustomerToIndex(String customer) {
    final trimmedCustomer = customer.trim();
    if (trimmedCustomer.length > 1) {
      _customerIndexService.saveCustomer(
        trimmedCustomer,
        startDate: widget.selectedDate,
      );
    }
  }

  void _saveSupplierToIndex(String supplier) {
    final trimmedSupplier = supplier.trim();
    if (trimmedSupplier.length > 1) {
      _supplierIndexService.saveSupplier(
        trimmedSupplier,
        startDate: widget.selectedDate,
      );
    }
  }

  void _toggleFullScreenSuggestions(
      {required String type, required bool show}) {
    if (mounted) {
      setState(() {
        _showFullScreenSuggestions = show;
        _currentSuggestionType = show ? type : '';
      });
    }
  }

  List<SuggestionItem> _getSuggestionsByType() {
    switch (_currentSuggestionType) {
      case 'supplier':
        return _supplierSuggestionItems;
      case 'customer':
        return _customerSuggestionItems;
      default:
        return [];
    }
  }

  int _getCurrentRowIndexByType() {
    switch (_currentSuggestionType) {
      case 'supplier':
        return _activeSupplierRowIndex ?? -1;
      case 'customer':
        return _activeCustomerRowIndex ?? -1;
      default:
        return -1;
    }
  }

// 1. دالة التحقق من حالة الأدمن (تُستدعى في initState)
  Future<void> _checkAdminStatus() async {
    final settings = AppSettingsService();
    final adminSeller = await settings.getString('admin_seller');
    if (mounted) {
      setState(() {
        _isAdmin = (widget.sellerName == adminSeller);
      });
    }
  }

  bool _canEditRow(int rowIndex) {
    if (rowIndex >= sellerNames.length) {
      return true; // صف جديد لم يحفظ بعد
    }
    if (_isAdmin) {
      return true; // الأدمن يمكنه تعديل أي شيء
    }
    // البائع العادي يعدل سجلاته فقط
    return sellerNames[rowIndex] == widget.sellerName;
  }

  Future<void> _fetchAndCalculateBalance(int rowIndex) async {
    final String type = accountTypeValues[rowIndex];
    final String name = rowControllers[rowIndex][2].text.trim();

    // القيم الحالية للصف الذي نعمل عليه (آخر عملية إدخال)
    final double currentReceived =
        double.tryParse(rowControllers[rowIndex][0].text) ?? 0; // مقبوض
    final double currentPaid =
        double.tryParse(rowControllers[rowIndex][1].text) ?? 0; // مدفوع

    if (name.isEmpty) {
      if (mounted) {
        setState(() {
          _lastFetchedBalance = null;
          _calculatedRemaining = null;
          _lastAccountName = '';
        });
      }
      return;
    }

    try {
      // جلب الرصيد الحقيقي مباشرة من الفهرس - بدون أي حسابات تراكمية
      double realBalance = 0;

      if (type == 'زبون') {
        final customers = await _customerIndexService.getAllCustomersWithData();
        final customerData = customers.values.firstWhere(
          (c) => c.name.toLowerCase() == name.toLowerCase(),
          orElse: () => CustomerData(name: name, balance: 0.0, startDate: ''),
        );
        realBalance = customerData.balance;
      } else if (type == 'مورد') {
        final supplierData = await _supplierIndexService.getSupplierData(name);
        realBalance = supplierData?.balance ?? 0.0;
      } else {
        // نوع الحساب "مصروف" - لا نعرض رصيداً
        return;
      }

      // حساب الباقي بناءً على آخر عملية إدخال فقط + الرصيد الحقيقي
      double remaining = 0;

      if (type == 'زبون') {
        // معادلة الزبون: الرصيد الحقيقي - مقبوض (سدد) + مدفوع (دين جديد)
        remaining = realBalance - currentReceived + currentPaid;
      } else if (type == 'مورد') {
        // معادلة المورد: الرصيد الحقيقي + مقبوض (دين علينا) - مدفوع (سداد منا)
        remaining = realBalance + currentReceived - currentPaid;
      }

      if (mounted) {
        setState(() {
          _lastFetchedBalance = realBalance; // الرصيد الحقيقي من الفهرس
          _calculatedRemaining =
              remaining; // الباقي = آخر عملية + الرصيد الحقيقي
          _lastAccountName = name;
        });
      }
    } catch (e) {
      debugPrint("Error calculating balance: $e");
    }
  }

  Widget _buildBalanceBar() {
    if (_lastFetchedBalance == null || _lastAccountName.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // اسم الحساب
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'الحساب',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  _lastAccountName.length > 14
                      ? '${_lastAccountName.substring(0, 14)}...'
                      : _lastAccountName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
            Container(width: 1, height: 30, color: Colors.white24),
            // الرصيد الحالي
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الرصيد',
                    style: TextStyle(fontSize: 16, color: Colors.white70)),
                Text(
                  _lastFetchedBalance?.toStringAsFixed(2) ?? '0.00',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
            Container(width: 1, height: 30, color: Colors.white24),
            // الباقي المتوقع
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الباقي',
                    style: TextStyle(fontSize: 16, color: Colors.white70)),
                Text(
                  _calculatedRemaining?.toStringAsFixed(2) ?? '0.00',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: (_calculatedRemaining ?? 0) >= 0
                        ? Colors.lightGreenAccent
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        Column(
          children: [
            _buildBalanceBar(),
            Expanded(
              child: _buildTableWithStickyHeader(),
            ),
            const SizedBox(height: 90),
          ],
        ),
        if (rowControllers.length >= 1)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 14, 82, 184),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 14, 82, 184)
                          .withOpacity(0.45),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // مقبوض
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'مقبوض',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: totalReceivedController,
                            builder: (context, value, child) {
                              return Text(
                                value.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.lightGreenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    // مدفوع
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'مدفوع',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: totalPaidController,
                            builder: (context, value, child) {
                              return Text(
                                value.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    // الصافي
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'الصافي',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: totalReceivedController,
                            builder: (context, recValue, child) {
                              return ValueListenableBuilder<TextEditingValue>(
                                valueListenable: totalPaidController,
                                builder: (context, paidValue, child) {
                                  final net = (double.tryParse(recValue.text) ??
                                          0) -
                                      (double.tryParse(paidValue.text) ?? 0);
                                  return Text(
                                    net.toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: net >= 0
                                          ? Colors.lightBlueAccent
                                          : Colors.orangeAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    // المجموع — كلمة فقط تملأ الحقل
                    Expanded(
                      child: Center(
                        child: const Text(
                          'المجموع',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- دالة توليد PDF والمشاركة (BoxScreen) ---
  Future<void> _generateAndSharePdf() async {
    try {
      final pdf = pw.Document();

      var arabicFont;
      try {
        final fontData =
            await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
        arabicFont = pw.Font.ttf(fontData);
      } catch (e) {
        arabicFont = pw.Font.courier();
      }

      final PdfColor headerColor = PdfColor.fromInt(0xFFF3A30D);
      final PdfColor headerTextColor = PdfColors.white;
      final PdfColor rowEvenColor = PdfColors.white;
      final PdfColor rowOddColor = PdfColor.fromInt(0xFFFFF3E0);
      final PdfColor borderColor = PdfColor.fromInt(0xFFE0E0E0);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
          build: (pw.Context context) {
            return [
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  children: [
                    pw.Center(
                        child: pw.Text('يومية صندوق رقم /$serialNumber/',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold))),
                    pw.Center(
                        child: pw.Text(
                            'تاريخ ${widget.selectedDate} - البائع ${widget.sellerName}',
                            style: const pw.TextStyle(
                                fontSize: 16, color: PdfColors.grey700))),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border:
                          pw.TableBorder.all(color: borderColor, width: 0.5),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3), // ملاحظات
                        1: const pw.FlexColumnWidth(4), // الحساب
                        2: const pw.FlexColumnWidth(2), // مدفوع
                        3: const pw.FlexColumnWidth(2), // مقبوض
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: headerColor),
                          children: [
                            _buildPdfHeaderCell('ملاحظات', headerTextColor),
                            _buildPdfHeaderCell('الحساب', headerTextColor),
                            _buildPdfHeaderCell('مدفوع', headerTextColor),
                            _buildPdfHeaderCell('مقبوض', headerTextColor),
                          ],
                        ),
                        ...rowControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controllers = entry.value;
                          if (controllers[0].text.isEmpty &&
                              controllers[1].text.isEmpty &&
                              controllers[2].text.isEmpty) {
                            return pw.TableRow(
                                children: List.filled(4, pw.SizedBox()));
                          }
                          final color =
                              index % 2 == 0 ? rowEvenColor : rowOddColor;
                          String accountInfo = controllers[2].text;
                          if (accountTypeValues[index].isNotEmpty) {
                            accountInfo =
                                "(${accountTypeValues[index]}) " + accountInfo;
                          }
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(color: color),
                            children: [
                              _buildPdfCell(controllers[3].text),
                              _buildPdfCell(accountInfo),
                              _buildPdfCell(controllers[1].text),
                              _buildPdfCell(controllers[0].text),
                            ],
                          );
                        }).toList(),
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFF90CAF9)),
                          children: [
                            _buildPdfCell(''),
                            _buildPdfCell('المجموع', isBold: true),
                            _buildPdfCell(totalPaidController.text,
                                isBold: true),
                            _buildPdfCell(totalReceivedController.text,
                                isBold: true),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final safeDate = widget.selectedDate.replaceAll('/', '-');
      final file = File("${output.path}/يومية_صندوق_$safeDate.pdf");

      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)],
          text: 'يومية صندوق ${widget.selectedDate}');
    } catch (e) {
      debugPrint("PDF Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('حدث خطأ أثناء تصدير PDF: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  pw.Widget _buildPdfHeaderCell(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              color: color, fontSize: 16, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildPdfCell(String text, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              fontSize: 16,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  /// جلب السجلات النقدية من يوميات المبيعات والمشتريات وعرضها في الصندوق للقراءة فقط
  Future<void> _loadCashTransactionsFromOtherJournals() async {
    final salesService = SalesStorageService();
    final purchaseService = PurchaseStorageService();

    final salesDoc = await salesService.loadSalesDocument(widget.selectedDate);
    final purchaseDoc =
        await purchaseService.loadPurchaseDocument(widget.selectedDate);

    if (!mounted) return;

    setState(() {
      // إزالة الصفوف المستوردة السابقة لتجنب التكرار
      for (int i = rowControllers.length - 1; i >= 0; i--) {
        if (i < rowSourceTypes.length &&
            (rowSourceTypes[i] == 'sales' || rowSourceTypes[i] == 'purchase')) {
          for (var c in rowControllers[i]) c.dispose();
          for (var n in rowFocusNodes[i]) n.dispose();
          rowControllers.removeAt(i);
          rowFocusNodes.removeAt(i);
          accountTypeValues.removeAt(i);
          sellerNames.removeAt(i);
          rowSourceTypes.removeAt(i);
        }
      }

      // ── المبيعات النقدية ──
      if (salesDoc != null) {
        for (var sale in salesDoc.sales) {
          if (sale.cashOrDebt == 'نقدي') {
            // في النقدي: customerName يكون null دائماً
            // نستخدم affiliation (الانتماء/الزبون) كاسم الحساب
            final String accountName = (sale.affiliation.trim().isNotEmpty)
                ? sale.affiliation.trim()
                : 'مبيعات نقدية';

            // [0]=مقبوض، [1]=مدفوع، [2]=الحساب، [3]=ملاحظات
            final controllers = [
              TextEditingController(text: sale.total), // [0] مقبوض
              TextEditingController(text: ''), // [1] مدفوع
              TextEditingController(text: accountName), // [2] الحساب
              TextEditingController(text: 'مبيعات نقدية'), // [3] ملاحظات
            ];
            final focusNodes = List.generate(4, (_) => FocusNode());
            rowControllers.add(controllers);
            rowFocusNodes.add(focusNodes);
            accountTypeValues.add('زبون');
            sellerNames.add(sale.sellerName);
            rowSourceTypes.add('sales');
          }
        }
      }

      // ── المشتريات النقدية ──
      if (purchaseDoc != null) {
        for (var purchase in purchaseDoc.purchases) {
          if (purchase.cashOrDebt == 'نقدي') {
            // اسم المورد مخزن في حقل affiliation وليس sellerName
            // sellerName = اسم الموظف/البائع، affiliation = اسم المورد
            final String accountName = purchase.affiliation.trim().isNotEmpty
                ? purchase.affiliation.trim()
                : 'مشتريات نقدية';

            // [0]=مقبوض، [1]=مدفوع، [2]=الحساب، [3]=ملاحظات
            final controllers = [
              TextEditingController(text: ''), // [0] مقبوض
              TextEditingController(text: purchase.total), // [1] مدفوع
              TextEditingController(text: accountName), // [2] الحساب
              TextEditingController(text: 'مشتريات نقدية'), // [3] ملاحظات
            ];
            final focusNodes = List.generate(4, (_) => FocusNode());
            rowControllers.add(controllers);
            rowFocusNodes.add(focusNodes);
            accountTypeValues.add('مورد');
            sellerNames.add(purchase.sellerName);
            rowSourceTypes.add('purchase');
          }
        }
      }

      _calculateAllTotals();
    });
  }

  void _adjustScrollPosition(int currentRowIndex) {
    final int totalRows = rowFocusNodes.length;
    if (totalRows == 0) return;

    if (currentRowIndex <= 2) {
      _verticalScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else if (totalRows - currentRowIndex <= 3) {
      _verticalScrollController.animateTo(
        _verticalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  String _extractNameFromSuggestion(String suggestion) {
    final dotIndex = suggestion.indexOf('. ');
    if (dotIndex != -1 && dotIndex + 2 < suggestion.length) {
      return suggestion.substring(dotIndex + 2).trim();
    }
    return suggestion.trim();
  }
}

class _StickyTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTableHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 32.0;

  @override
  double get minExtent => 32.0;

  @override
  bool shouldRebuild(_StickyTableHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
