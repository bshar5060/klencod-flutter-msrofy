import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MasroofiApp());
}

class MasroofiApp extends StatelessWidget {
  const MasroofiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مصروفي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F8C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final bool isIncome;
  final DateTime date;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.date,
  });

  // تحويل المعاملة إلى نص قابل للحفظ
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
      };

  // إعادة بناء المعاملة من النص المحفوظ
  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      isIncome: json['isIncome'] as bool,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _storageKey = 'masroofi_transactions_v1';

  final List<TransactionItem> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // تحميل المعاملات المحفوظة عند فتح التطبيق
  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = <TransactionItem>[];

        for (final entry in decoded) {
          try {
            loaded.add(
              TransactionItem.fromJson(entry as Map<String, dynamic>),
            );
          } catch (_) {
            // تجاهل أي سجل تالف بدل إيقاف التطبيق كله
          }
        }

        transactions
          ..clear()
          ..addAll(loaded);
      }
    } catch (_) {
      // إذا كانت البيانات تالفة يبدأ التطبيق بقائمة فارغة
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  // حفظ المعاملات الحالية على الجهاز
  Future<void> _saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        transactions.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر حفظ البيانات على الجهاز'),
        ),
      );
    }
  }

  double get income => transactions
      .where((item) => item.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get expenses => transactions
      .where((item) => !item.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get balance => income - expenses;

  String money(double value) => value.toStringAsFixed(2);

  Future<void> addTransaction() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    String category = 'طعام';
    bool isIncome = false;

    final result = await showDialog<TransactionItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'معاملة جديدة',
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'وصف المعاملة',
                        hintText: 'مثال: شراء كتاب',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        suffixText: 'جنيه',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'طعام',
                          child: Text('طعام'),
                        ),
                        DropdownMenuItem(
                          value: 'مواصلات',
                          child: Text('مواصلات'),
                        ),
                        DropdownMenuItem(
                          value: 'دراسة',
                          child: Text('دراسة'),
                        ),
                        DropdownMenuItem(
                          value: 'تسوق',
                          child: Text('تسوق'),
                        ),
                        DropdownMenuItem(
                          value: 'راتب',
                          child: Text('راتب'),
                        ),
                        DropdownMenuItem(
                          value: 'أخرى',
                          child: Text('أخرى'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('إيراد'),
                      subtitle: Text(
                        isIncome ? 'إضافة أموال' : 'تسجيل مصروف',
                      ),
                      value: isIncome,
                      onChanged: (value) {
                        setDialogState(() {
                          isIncome = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (title.isEmpty ||
                        amount == null ||
                        !amount.isFinite ||
                        amount <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'أدخل وصفًا ومبلغًا صحيحًا أكبر من صفر',
                          ),
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now();

                    Navigator.pop(
                      dialogContext,
                      TransactionItem(
                        id: now.microsecondsSinceEpoch.toString(),
                        title: title,
                        amount: amount,
                        category: category,
                        isIncome: isIncome,
                        date: now,
                      ),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();

    if (!mounted || result == null) return;

    setState(() {
      transactions.insert(0, result);
    });
    _saveTransactions();
  }

  void deleteTransaction(TransactionItem item) {
    setState(() {
      transactions.removeWhere((t) => t.id == item.id);
    });
    _saveTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مصروفي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF087F8C),
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'مرحبًا بك في تطبيق مصروفي',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF087F8C),
                    Color(0xFF064E64),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رصيدك الحالي',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${money(balance)} جنيه',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'إدارة أموالك أصبحت أسهل',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'الإيرادات',
                    amount: income,
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'المصروفات',
                    amount: expenses,
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                // نعطّل الزر حتى ينتهي تحميل البيانات المحفوظة
                onPressed: isLoading ? null : addTransaction,
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة معاملة جديدة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087F8C),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'آخر المعاملات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد معاملات حتى الآن',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ابدأ بإضافة أول معاملة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...transactions.map((item) {
                return Card(
                  key: ValueKey(item.id),
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isIncome
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Icon(
                        item.isIncome
                            ? Icons.south_west
                            : Icons.north_east,
                        color: item.isIncome
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${item.category} • '
                      '${item.date.day}/${item.date.month}/${item.date.year}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.isIncome ? '+' : '-'}'
                          '${money(item.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.isIncome
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            tooltip: 'حذف المعاملة',
                            onPressed: () => deleteTransaction(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${money(amount)} ج.م',
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}