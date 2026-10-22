import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xfff7f9fc),
      ),
      home: const HomeScreen(),
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
    );
  }
}

enum TransactionType { income, expense }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _storageKey = 'transactions';

  final List<Transaction> _transactions = [];
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList();
        _transactions
          ..clear()
          ..addAll(list);
      } catch (_) {
        // Ignore corrupted data and start fresh.
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get _balance => _totalIncome - _totalExpense;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _dailyTotal(TransactionType type, DateTime day) {
    return _transactions
        .where((t) => t.type == type && _sameDay(t.date, day))
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<Transaction> get _selectedDayTransactions => _transactions
      .where((t) => _sameDay(t.date, _selectedDay))
      .toList();

  void _addTransaction(Transaction transaction) {
    setState(() => _transactions.insert(0, transaction));
    _saveTransactions();
  }

  void _updateTransaction(Transaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;
    setState(() => _transactions[index] = updated);
    _saveTransactions();
  }

  void _deleteTransaction(Transaction transaction) {
    setState(() => _transactions.removeWhere((t) => t.id == transaction.id));
    _saveTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ลบรายการแล้ว')),
    );
  }

  Future<void> _showTransactionDialog({Transaction? transaction}) async {
    final result = await showDialog<Transaction>(
      context: context,
      builder: (_) => TransactionDialog(transaction: transaction),
    );

    if (result == null) return;
    if (transaction == null) {
      _addTransaction(result);
    } else {
      _updateTransaction(result);
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  String _money(double value) => '฿${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final dailyIncome = _dailyTotal(TransactionType.income, _selectedDay);
    final dailyExpense = _dailyTotal(TransactionType.expense, _selectedDay);
    final dailyBalance = dailyIncome - dailyExpense;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการธุรกรรม'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            _BalanceCard(
              balance: _balance,
              income: _totalIncome,
              expense: _totalExpense,
              money: _money,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'สรุปรายวัน',
              trailing: TextButton.icon(
                onPressed: _pickDay,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(
                  '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DailyStat(
                      label: 'รายรับ',
                      amount: dailyIncome,
                      color: Colors.green,
                      money: _money,
                    ),
                  ),
                  Expanded(
                    child: _DailyStat(
                      label: 'รายจ่าย',
                      amount: dailyExpense,
                      color: Colors.red,
                      money: _money,
                    ),
                  ),
                  Expanded(
                    child: _DailyStat(
                      label: 'คงเหลือ',
                      amount: dailyBalance,
                      color: Colors.blue,
                      money: _money,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'รายรับ - รายจ่าย 7 วันล่าสุด',
              child: DailyBarChart(
                transactions: _transactions,
                money: _money,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการของวันที่เลือก',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text('${_selectedDayTransactions.length} รายการ'),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedDayTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: Text('ยังไม่มีรายการในวันนี้')),
              )
            else
              ..._selectedDayTransactions.map(
                (transaction) => TransactionTile(
                  transaction: transaction,
                  onEdit: () => _showTransactionDialog(transaction: transaction),
                  onDelete: () => _confirmDelete(transaction),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการ'),
      ),
    );
  }

  Future<void> _confirmDelete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายการ?'),
        content: Text('ต้องการลบ "${transaction.title}" ใช่หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteTransaction(transaction);
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final String Function(double) money;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ยอดเงินคงเหลือ', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 5),
            Text(
              money(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _MiniTotal('รายรับทั้งหมด', income, Colors.green, money)),
                Expanded(child: _MiniTotal('รายจ่ายทั้งหมด', expense, Colors.red, money)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTotal extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String Function(double) money;

  const _MiniTotal(this.label, this.amount, this.color, this.money);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(Icons.circle, size: 9, color: color),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              money(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DailyStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String Function(double) money;

  const _DailyStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          money(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final sign = isIncome ? '+' : '-';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(isIncome ? Icons.add : Icons.remove, color: color),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$sign ฿${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                PopupMenuItem(value: 'delete', child: Text('ลบ')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionDialog extends StatefulWidget {
  final Transaction? transaction;

  const TransactionDialog({super.key, this.transaction});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late TransactionType _type;
  late DateTime _selectedDate;

  bool get _editing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _titleController = TextEditingController(text: t?.title ?? '');
    _amountController = TextEditingController(
      text: t == null ? '' : t.amount.toString(),
    );
    _type = t?.type ?? TransactionType.expense;
    _selectedDate = t?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อรายการและจำนวนเงินให้ถูกต้อง')),
      );
      return;
    }

    Navigator.pop(
      context,
      Transaction(
        id: widget.transaction?.id,
        title: title,
        amount: amount,
        type: _type,
        date: _selectedDate,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'แก้ไขรายการ' : 'เพิ่มรายการธุรกรรม'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อรายการ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('รายรับ'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('รายจ่าย'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) => setState(() => _type = value.first),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                const Spacer(),
                TextButton(onPressed: _pickDate, child: const Text('เลือกวันที่')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'บันทึก' : 'เพิ่ม'),
        ),
      ],
    );
  }
}

class DailyBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String Function(double) money;

  const DailyBarChart({
    super.key,
    required this.transactions,
    required this.money,
  });

  double _total(TransactionType type, DateTime day) {
    return transactions
        .where((t) =>
            t.type == type &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .fold(0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - 6 + i));
    final values = [
      for (final day in days) (_total(TransactionType.income, day), _total(TransactionType.expense, day)),
    ];
    final maxValue = values.fold<double>(0, (max, pair) => math.max(max, math.max(pair.$1, pair.$2)));

    return SizedBox(
      height: 230,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _BarChartPainter(values: values, maxValue: maxValue),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Text(
                    '${day.day}/${day.month}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Legend(color: Colors.green, label: 'รายรับ'),
              SizedBox(width: 20),
              _Legend(color: Colors.red, label: 'รายจ่าย'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<(double, double)> values;
  final double maxValue;

  _BarChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: .16)
      ..strokeWidth = 1;
    final incomePaint = Paint()..color = Colors.green;
    final expensePaint = Paint()..color = Colors.red;

    for (int i = 1; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final groupWidth = size.width / values.length;
    final barWidth = math.min(13.0, groupWidth * .22);
    final scale = maxValue <= 0 ? 0.0 : size.height / maxValue;

    for (int i = 0; i < values.length; i++) {
      final centerX = groupWidth * i + groupWidth / 2;
      final incomeHeight = values[i].$1 * scale;
      final expenseHeight = values[i].$2 * scale;
      final incomeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth - 2, size.height - incomeHeight, barWidth, incomeHeight),
        const Radius.circular(4),
      );
      final expenseRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, size.height - expenseHeight, barWidth, expenseHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(incomeRect, incomePaint);
      canvas.drawRRect(expenseRect, expensePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}
