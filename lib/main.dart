import 'package:flutter/material.dart';

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
      theme: ThemeData( // กำหนดธีมของแอปพลิเคชัน
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}
  ///ที่ใช้เก็บข้อมูลของแต่ละรายการธุรกรรม
class Transaction { 
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;

  Transaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });
}

enum TransactionType { income, expense }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Transaction> _transactions = [];

  // ------ Logic for calculating totals and balance ------

  double get _totalIncome { 
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalExpense { 
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _balance => _totalIncome - _totalExpense;

  //---------------------------------------------

  // ------ Logic for adding transactions ------

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.insert(0, transaction);
    });
  }

  void _showAddTransactionDialog() {
      showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(onAdd: _addTransaction),
    );
  }

  //--------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการธุรกรรม'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          BalanceSummary(
            balance: _balance,
            income: _totalIncome,
            expense: _totalExpense,
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีรายการธุรกรรม'),
                  )
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return TransactionTile(transaction: transaction);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class BalanceSummary extends StatelessWidget { // Widget ที่แสดงสรุปยอดเงินคงเหลือ รายรับ และรายจ่าย
  final double balance;
  final double income;
  final double expense;

  const BalanceSummary({
    Key? key,
    required this.balance,
    required this.income,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // ฟังก์ชันที่สร้างและแสดง UI โดยจะแสดงยอดเงินคงเหลือ รายรับ และรายจ่าย 
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ยอดเงินคงเหลือ',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '\฿${balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                label: 'รายรับ',
                amount: income,
                color: Colors.green,
              ),
              _SummaryItem(
                label: 'รายจ่าย',
                amount: expense,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) { // ฟังก์ชันที่สร้างและแสดง UI และ ป้ายชื่อและจำนวนเงิน ตรงด้านล่าง Expense Tracker
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          '\฿${amount.toStringAsFixed(2)}', // แสดงจำนวนเงิน รายรับ-รายจ่าย ทั้งหมด ในรูปแบบที่มีสัญลักษณ์เงินและทศนิยม 2 ตำแหน่ง
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class TransactionTile extends StatelessWidget { // ใช้แสดงข้อมูลของแต่ละรายการธุรกรรมในแต่ละงวด
  final Transaction transaction;

  const TransactionTile({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income; 
    final amountColor = isIncome ? Colors.green : Colors.red;
    final amountSign = isIncome ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.2), // กำหนดสีพื้นหลังของเครื่องหมายรายรับ-รายจ่าย
        child: Icon(
          isIncome ? Icons.add : Icons.remove, // กำหนดไอคอนที่แสดงเครื่องหมายบวกสำหรับรายรับ และเครื่องหมายลบสำหรับรายจ่าย
          color: amountColor,
        ),
      ),
      title: Text(transaction.title),
      subtitle: Text(
        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}', // แสดงวันที่ของรายการธุรกรรมในรูปแบบ วัน/เดือน/ปี
      ),
      trailing: Text(
        '$amountSign ฿${transaction.amount.toStringAsFixed(2)}', // แสดง รายรับ-รายจ่าย แต่ละงวด
        style: TextStyle(
          color: amountColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class AddTransactionDialog extends StatefulWidget { // Dialog ที่ใช้สำหรับเพิ่มรายการธุรกรรมใหม่ โดยมีฟอร์มให้กรอกข้อมูลและปุ่มสำหรับยืนยันการเพิ่มรายการ
  final Function(Transaction) onAdd;

  const AddTransactionDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> { // class ที่ทำหน้าที่เพิ่มรายการธุรกรรมใหม่ โดยมีการจัดการกับสถานะของฟอร์มและข้อมูลที่ผู้ใช้กรอกเข้ามา
  final _titleController = TextEditingController();
  final _amountController = TextEditingController(); 
  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() { // ล้างข้อมูลและทรัพยากรที่ใช้ในตัวควบคุมข้อความเมื่อไม่ใช้งานแล้ว
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) { // ตรวจสอบว่าผู้ใช้กรอกข้อมูลครบถ้วนหรือไม่ หากไม่ครบจะแสดงข้อความ Please fill all fields
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปดกรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if(amount == null){ // ตรวจสอบว่าจำนวนเงินที่ผู้ใช้กรอกเข้ามาเป็นตัวเลขที่ถูกต้องหรือไม่ หากไม่ถูกต้องจะแสดงข้อความ Amount must be a valid number
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปดกรอกจำนวนเงินให้ถูกต้อง')),
      );
      return;
    }
    if (amount <= 0) { // ตรวจสอบว่าจำนวนเงินที่ผู้ใช้กรอกเข้ามามากกว่า 0 หรือไม่ หากไม่มากกว่า 0 จะแสดงข้อความ Amount must be greater than 0
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('จำนวนเงินต้องมากกว่า 0')),
      );
      return;
    }

    widget.onAdd( // ส่งข้อมูลรายการธุรกรรมใหม่ที่ผู้ใช้กรอกเข้ามาไปยังฟังก์ชัน onAdd ที่ถูกส่งมาจาก HomeScreen เพื่อเพิ่มรายการธุรกรรมใหม่ลงในรายการทั้งหมด
      Transaction(
        title: _titleController.text,
        amount: amount,
        type: _type,
        date: _selectedDate,
      ),
    );

    Navigator.of(context).pop(); // ปิดหน้าต่างกรอกข้อมูลหลังจากส่งเสร็จ
  }

  Future<void> _pickDate() async { // การแสดงปฏิทินให้ผู้ใช้เลือกวันที่ของรายการธุรกรรม
    final picked = await showDatePicker( 
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) { // หากผู้ใช้เลือกวันที่แล้ว จะอัปเดตสถานะของ _selectedDate ให้เป็นวันที่ที่ผู้ใช้เลือก
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) { // ฟังก์ชันที่สร้างและแสดง UI สำหรับเพิ่มรายการธุรกรรมใหม่
    return AlertDialog(
      title: const Text('เพิ่มรายการธุรกรรม'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // กำหนดให้คอลัมน์มีขนาดตามเนื้อหาภายใน
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'ชื่อรายการ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'จำนวนเงิน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('รายรับ'),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('รายจ่าย'), 
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() => _type = value.first); // อัปเดตสถานะของ _type ให้เป็นประเภทที่ผู้ใช้เลือกเมื่อมีการเปลี่ยนแปลงการเลือก                  
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row( // แสดงวันที่ที่ผู้ใช้เลือกและปุ่มสำหรับเปิดปฏิทินเพื่อเลือกวันที่ใหม่
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('เลือกวันที่'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _submit, 
          child: const Text('เพิ่ม'),
        ),
      ],
    );
  }
}
