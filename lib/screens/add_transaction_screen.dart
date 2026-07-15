import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/google_sheets_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final GoogleSheetsProvider provider;

  const AddTransactionScreen({super.key, required this.provider});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  String? _selectedAccount;
  String? _selectedToAccount;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Default selections
    if (widget.provider.categories.isNotEmpty) {
      _selectedCategory = widget.provider.categories.first.name;
    }
    if (widget.provider.accounts.isNotEmpty) {
      _selectedAccount = widget.provider.accounts.first.name;
      if (widget.provider.accounts.length > 1) {
        _selectedToAccount = widget.provider.accounts[1].name;
      } else {
        _selectedToAccount = widget.provider.accounts.first.name;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E2230),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF12141C),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount greater than 0"), backgroundColor: Colors.amber),
      );
      return;
    }

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp local ID
      date: _selectedDate,
      type: _selectedType,
      amount: amount,
      category: _selectedType == TransactionType.transfer ? "Transfer" : (_selectedCategory ?? "Other"),
      account: _selectedAccount ?? "Cash",
      toAccount: _selectedType == TransactionType.transfer ? (_selectedToAccount ?? "") : "",
      notes: _notesController.text.trim(),
    );

    // Navigate back immediately for optimistic response
    Navigator.pop(context);

    final success = await widget.provider.addTransaction(newTx);
    
    // Notify in scaffolding context of dashboard
    final rootContext = Navigator.of(context).context;
    if (success) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text("Transaction synced with Google Sheets"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text("Saved locally. Failed to sync with Google Sheets."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final isTransfer = _selectedType == TransactionType.transfer;

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NEW TRANSACTION",
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Transaction Type Selector (Choice Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeChip(TransactionType.expense, const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _buildTypeChip(TransactionType.income, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildTypeChip(TransactionType.transfer, const Color(0xFF8B5CF6)),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
                decoration: InputDecoration(
                  prefixText: NumberFormat.simpleCurrency().currencySymbol,
                  prefixStyle: const TextStyle(color: Colors.grey, fontSize: 20),
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdowns & Date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Row for Category / Account Selection
                  if (!isTransfer) ...[
                    _buildDropdown(
                      label: "Category",
                      value: _selectedCategory,
                      items: provider.categories.map((c) => c.name).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const Divider(color: Colors.white10, height: 16),
                  ],

                  // Account Selector
                  _buildDropdown(
                    label: isTransfer ? "From Account" : "Account",
                    value: _selectedAccount,
                    items: provider.accounts.map((a) => a.name).toList(),
                    onChanged: (val) => setState(() => _selectedAccount = val),
                  ),

                  // Destination Account (for Transfers only)
                  if (isTransfer) ...[
                    const Divider(color: Colors.white10, height: 16),
                    _buildDropdown(
                      label: "To Account",
                      value: _selectedToAccount,
                      items: provider.accounts.map((a) => a.name).toList(),
                      onChanged: (val) => setState(() => _selectedToAccount = val),
                    ),
                  ],

                  const Divider(color: Colors.white10, height: 16),

                  // Date Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Date", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6366F1)),
                        label: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: const Color(0xFF12141C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Notes Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "Add notes (optional)...",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Transaction Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Save Transaction",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(TransactionType type, Color activeColor) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(
        type.name,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
      selectedColor: activeColor,
      backgroundColor: const Color(0xFF1E2230),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(width: 24),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: const Color(0xFF1E2230),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                alignment: Alignment.centerRight,
                onChanged: onChanged,
                items: items.map<DropdownMenuItem<String>>((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
