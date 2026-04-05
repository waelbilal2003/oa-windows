import 'package:flutter/material.dart';
import '../widgets/exit_button.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollController.animateTo(
                (_scrollController.offset + 150)
                    .clamp(0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeInOut,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollController.animateTo(
                (_scrollController.offset - 150)
                    .clamp(0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            toolbarHeight: 70,
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 140),
                const Text(
                  'دليل الاستخدام',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                ExitButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── رأس الصفحة ──
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 64, color: Colors.green[700]),
                      const SizedBox(height: 8),
                      Text(
                        'بسم الله الرحمن الرحيم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'هذه النسخة مخصصة للسيد أبو إسلام',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── الأقسام ──
                _HelpSection(
                  icon: Icons.play_circle_outline,
                  color: Colors.blue[700]!,
                  title: 'البداية مع التطبيق',
                  steps: const [
                    'إن كنت تستخدم التطبيق لأول مرة ولديك أرصدة زبائن وموردين وصندوق وتريد أن تبدأ بها، اتبع الخطوات التالية:',
                    'أدخل كلمة السر.',
                    'بعد الدخول، ادخل إلى شاشة التفصيلات.',
                    'ثم ادخل إلى شاشة أرصدة البداية حيث يتم إدخال الأرصدة من خلالها:\nالصندوق  •  الزبائن  •  الموردون  •  رأس المال',
                  ],
                ),

                _HelpSection(
                  icon: Icons.edit_note,
                  color: Colors.orange[700]!,
                  title: 'إدخال الأرصدة',
                  steps: const [
                    'ضع المؤشر على الحساب المراد استخدامه واضغط.',
                    'بالنسبة لحسابات الزبائن والموردين: اضغط زر "إضافة"، اكتب الاسم واضغط Enter، ضع المؤشر على السطر المقابل للاسم واكتب رقم الرصيد ثم اضغط Enter، ثم أضف رقم الموبايل.',
                    'بالنسبة لحساب الصندوق ورأس المال: ضع المؤشر فوق الأصفار واكتب الرقم المطلوب.',
                  ],
                ),

                _HelpSection(
                  icon: Icons.settings,
                  color: Colors.purple[700]!,
                  title: 'شاشة الإعدادات',
                  steps: const [
                    'أخرج من شاشة الأرصدة وادخل إلى شاشة الإعدادات.',
                    'أدخل أسماء المواد التي تتعامل بها عبر "فهرس المواد".',
                    'أدخل أنواع العبوات التي تستخدمها عبر "فهرس العبوات".',
                    'يمكن تغيير كلمة المرور، وإضافة اسم المحل، وتكبير حجم الخط أو الأيقونة.',
                    'بعد الانتهاء، أخرج من التطبيق وأعد الدخول مجدداً.',
                  ],
                ),

                _HelpSection(
                  icon: Icons.receipt_long,
                  color: Colors.teal[700]!,
                  title: 'الفواتير والكشوف',
                  steps: const [
                    'ابدأ العمل من أي شاشة: المبيعات، المشتريات، أو الصندوق.',
                    'يمكن الحصول على فواتير وكشوف للزبائن والموردين من شاشة الفواتير.',
                    'يمكن إرسالها عبر وسائل التواصل (واتساب، تيليغرام، مسنجر، بلوتوث...) بالضغط على زر PDF في الزاوية العليا اليمينية.',
                    'الكشوف بين تاريخين تُستخرج من الزر المجاور لزر PDF في الزاوية العليا اليمينية.',
                    'يمكن إرسال كشف يوم أو أكثر يتضمن كل العمليات الحسابية دون ذكر الكميات، من خلال تفصيلات المورد أو الزبائن في شاشة التفصيلات.',
                  ],
                ),

                _HelpSection(
                  icon: Icons.inventory_2_outlined,
                  color: Colors.brown[600]!,
                  title: 'مخزون المواد',
                  steps: const [
                    'يمكن معرفة ما تبقى لديك من مواد بعد عمليات البيع والشراء عبر شاشة "البايت".',
                  ],
                ),

                _HelpSection(
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.indigo[700]!,
                  title: 'الموقف المالي',
                  steps: const [
                    'يمكنك معرفة موقفك المالي من ربح أو خسارة عبر "تفصيلات الحساب" في شاشة التفصيلات.',
                  ],
                ),

                _HelpSection(
                  icon: Icons.backup,
                  color: Colors.red[700]!,
                  title: 'النسخ الاحتياطي',
                  steps: const [
                    'ننصح بإجراء نسخ احتياطي على الأقل مرة كل يوم حرصاً على سلامة بياناتك من التلف أو الضياع لأي سبب كان.',
                    'نؤكد على عدم مسؤوليتنا عن فقدان البيانات نتيجة أي خلل في الجهاز أو سوء استخدام للتطبيق.',
                    'تنحصر مسؤوليتنا في تسليم التطبيق وهو كامل من حيث معالجة العمليات محاسبياً.',
                  ],
                ),

                // ── معلومات التواصل ──
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade900],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.contact_phone,
                          color: Colors.white, size: 32),
                      const SizedBox(height: 10),
                      const Text(
                        'للاستفسار والتواصل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ContactRow(
                        name: 'المحاسب أبو فراس الحجي',
                        phone: '0944367326',
                      ),
                      const SizedBox(height: 8),
                      _ContactRow(
                        name: 'المبرمج وائل بلال',
                        phone: '0935702074',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ويدجت القسم ──
class _HelpSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> steps;

  const _HelpSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(right: BorderSide(color: color, width: 4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // الخطوات
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 8),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ويدجت بيانات التواصل ──
class _ContactRow extends StatelessWidget {
  final String name;
  final String phone;

  const _ContactRow({required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            phone,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
