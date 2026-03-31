import 'package:flutter/material.dart';

class DateRangeFilterIcon extends StatefulWidget {
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onClear;
  final Color color;

  const DateRangeFilterIcon({
    Key? key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onClear,
    this.color = Colors.indigo,
  }) : super(key: key);

  @override
  _DateRangeFilterIconState createState() => _DateRangeFilterIconState();
}

class _DateRangeFilterIconState extends State<DateRangeFilterIcon> {
  bool get _isActive => widget.from != null || widget.to != null;

  void _showDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _DateRangeDialog(
        initialFrom: widget.from,
        initialTo: widget.to,
        onApply: (from, to) {
          widget.onFromChanged(from);
          widget.onToChanged(to);
        },
        onClear: () {
          widget.onClear();
        },
        color: widget.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على مقياس التكبير من MediaQuery
    final textScaler = MediaQuery.of(context).textScaler;
    final iconScale = textScaler.scale(1.0);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.date_range,
            color: widget.color,
            size: 24 * iconScale, // مضروب بمقياس الأيقونات
          ),
          if (_isActive)
            Positioned(
              top: -4 * iconScale,
              right: -4 * iconScale,
              child: Container(
                width: 12 * iconScale,
                height: 12 * iconScale,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'فلترة بالتاريخ',
      onPressed: _showDialog,
    );
  }
}

class _DateRangeDialog extends StatefulWidget {
  final DateTime? initialFrom;
  final DateTime? initialTo;
  final Function(DateTime? from, DateTime? to) onApply;
  final VoidCallback onClear;
  final Color color;

  const _DateRangeDialog({
    Key? key,
    this.initialFrom,
    this.initialTo,
    required this.onApply,
    required this.onClear,
    required this.color,
  }) : super(key: key);

  @override
  __DateRangeDialogState createState() => __DateRangeDialogState();
}

class __DateRangeDialogState extends State<_DateRangeDialog> {
  late DateTime tempFrom;
  late DateTime tempTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    tempFrom = widget.initialFrom ?? now;
    tempTo = widget.initialTo ?? now;
  }

  DateTime _clampDay(int y, int m, int d) {
    final max = DateUtils.getDaysInMonth(y, m);
    return DateTime(y, m, d > max ? max : d);
  }

  // دالة مساعدة للحصول على المقياس
  double get _scale => MediaQuery.of(context).textScaler.scale(1.0);

  @override
  Widget build(BuildContext context) {
    final scale = _scale;

    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    Widget miniPicker({
      required String label,
      required String display,
      required VoidCallback onUp,
      required VoidCallback onDown,
      required Color color,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 3),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: Colors.grey[300]!, width: 1.5 * scale),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 42 * scale,
                  width: 42 * scale,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_drop_up,
                        size: 33 * scale, color: Colors.green[600]),
                    onPressed: onUp,
                  ),
                ),
                SizedBox(
                  height: 39 * scale,
                  child: Center(
                    child: Text(display,
                        style: TextStyle(
                            fontSize: 18 * scale, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(
                  height: 42 * scale,
                  width: 42 * scale,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_drop_down,
                        size: 33 * scale, color: Colors.red[600]),
                    onPressed: onDown,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget datePicker({
      required String sectionLabel,
      required DateTime date,
      required Color color,
      required void Function(DateTime) onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 19.5 * scale, color: color),
              const SizedBox(width: 6),
              Text(sectionLabel,
                  style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 12),
              Text(
                '${date.year}/${date.month}/${date.day}',
                style: TextStyle(
                    fontSize: 18 * scale,
                    color: color,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              miniPicker(
                label: 'اليوم',
                display: date.day.toString(),
                color: color,
                onUp: () =>
                    onChanged(_clampDay(date.year, date.month, date.day + 1)),
                onDown: () =>
                    onChanged(_clampDay(date.year, date.month, date.day - 1)),
              ),
              miniPicker(
                label: 'الشهر',
                display: months[date.month - 1],
                color: color,
                onUp: () {
                  final m = date.month < 12 ? date.month + 1 : 1;
                  onChanged(_clampDay(date.year, m, date.day));
                },
                onDown: () {
                  final m = date.month > 1 ? date.month - 1 : 12;
                  onChanged(_clampDay(date.year, m, date.day));
                },
              ),
              miniPicker(
                label: 'السنة',
                display: date.year.toString(),
                color: color,
                onUp: () =>
                    onChanged(_clampDay(date.year + 1, date.month, date.day)),
                onDown: () =>
                    onChanged(_clampDay(date.year - 1, date.month, date.day)),
              ),
            ],
          ),
        ],
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24 * scale)),
        titlePadding:
            EdgeInsets.fromLTRB(24 * scale, 24 * scale, 24 * scale, 12 * scale),
        contentPadding:
            EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 12 * scale),
        title: Row(
          children: [
            Icon(Icons.date_range, color: Colors.black, size: 27 * scale),
            const SizedBox(width: 12),
            Text('فلترة بالتاريخ',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 22.5 * scale)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: datePicker(
                    sectionLabel: 'من تاريخ',
                    date: tempFrom,
                    color: Colors.black,
                    onChanged: (d) => setState(() => tempFrom = d),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: datePicker(
                    sectionLabel: 'إلى تاريخ',
                    date: tempTo,
                    color: Colors.black,
                    onChanged: (d) => setState(() => tempTo = d),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              textStyle: TextStyle(fontSize: 16.5 * scale),
            ),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              widget.onClear();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              textStyle: TextStyle(fontSize: 16.5 * scale),
            ),
            child:
                const Text('مسح الفلتر', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              textStyle: TextStyle(fontSize: 16.5 * scale),
              padding: EdgeInsets.symmetric(
                  horizontal: 24 * scale, vertical: 12 * scale),
            ),
            onPressed: () {
              if (tempFrom.isAfter(tempTo)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تاريخ البداية يجب أن يكون قبل النهاية'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              widget.onApply(tempFrom, tempTo);
              Navigator.pop(context);
            },
            child: const Text('تطبيق',
                style: TextStyle(color: Color.fromARGB(255, 231, 9, 9))),
          ),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onClear;
  final Color color;

  const FilterChipWidget({
    Key? key,
    required this.from,
    required this.to,
    required this.onClear,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).textScaler.scale(1.0);

    if (from == null && to == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 9 * scale),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1.5 * scale),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt, color: color, size: 24 * scale),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'الفلتر: '
                '${from != null ? '${from!.year}/${from!.month}/${from!.day}' : '—'}'
                ' ← '
                '${to != null ? '${to!.year}/${to!.month}/${to!.day}' : '—'}',
                style: TextStyle(color: Colors.black, fontSize: 18 * scale),
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close, color: color, size: 24 * scale),
            ),
          ],
        ),
      ),
    );
  }
}
