import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/google_sheets_service.dart';

class HistoryScreen extends StatefulWidget {
  final GoogleSheetsProvider provider;

  const HistoryScreen({super.key, required this.provider});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = "";
  String _selectedTypeFilter = "All"; // "All" | "Expense" | "Income" | "Transfer"
  bool _showAnalytics = false;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B); // Amber
      case 'rent':
        return const Color(0xFF3B82F6); // Blue
      case 'utilities':
        return const Color(0xFF06B6D4); // Cyan
      case 'transport':
        return const Color(0xFF10B981); // Emerald
      case 'entertainment':
        return const Color(0xFFEC4899); // Pink
      case 'salary':
        return const Color(0xFF8B5CF6); // Purple
      case 'gift':
        return const Color(0xFFF43F5E); // Rose
      case 'transfer':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF10B981); // Default Green
    }
  }

  void _confirmDelete(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: const Text("Delete Transaction?", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete this transaction of ${NumberFormat.simpleCurrency(decimalDigits: 2).format(tx.amount)}?",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await widget.provider.deleteTransaction(tx.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? "Deleted successfully" : "Deleted locally, sync failed"),
                      backgroundColor: success ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final provider = widget.provider;

    // Filter transactions based on type and query
    final filteredTxs = provider.transactions.where((tx) {
      final matchesType = _selectedTypeFilter == "All" || tx.type.name == _selectedTypeFilter;
      final query = _searchQuery.toLowerCase();
      final matchesQuery = tx.category.toLowerCase().contains(query) ||
          tx.account.toLowerCase().contains(query) ||
          tx.toAccount.toLowerCase().contains(query) ||
          tx.notes.toLowerCase().contains(query);
      return matchesType && matchesQuery;
    }).toList();

    // Calculations for the filtered scope
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in filteredTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "HISTORY & ANALYTICS",
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        actions: [
          IconButton(
            icon: Icon(_showAnalytics ? Icons.list_alt : Icons.pie_chart_outline, color: Colors.white, size: 20),
            onPressed: () {
              setState(() {
                _showAnalytics = !_showAnalytics;
              });
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filtering Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search notes, accounts, categories...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 11),
                  ),
                ),
              ),
            ),

            // Type Filter Chips (Ivy Wallet style rectangular indicators)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["All", "Expense", "Income", "Transfer"].map((type) {
                  final isSelected = _selectedTypeFilter == type;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTypeFilter = type;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),

            // Main Content Area
            Expanded(
              child: _showAnalytics
                  ? _buildAnalyticsView(provider, currencyFormat)
                  : _buildListView(filteredTxs, currencyFormat, totalIncome, totalExpense),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<TransactionModel> txs, NumberFormat currencyFormat, double totalIncome, double totalExpense) {
    return Column(
      children: [
        // Summary Header for the filtered set
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filtered Sum:",
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    "+${currencyFormat.format(totalIncome)}",
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "-${currencyFormat.format(totalExpense)}",
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: txs.isEmpty
              ? const Center(child: Text("No matching transactions", style: TextStyle(color: Colors.grey, fontSize: 12)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    final isExpense = tx.type == TransactionType.expense;
                    final isTransfer = tx.type == TransactionType.transfer;

                    Color amountColor = const Color(0xFF10B981);
                    String prefix = "+";
                    if (isExpense) {
                      amountColor = const Color(0xFFEF4444);
                      prefix = "-";
                    } else if (isTransfer) {
                      amountColor = const Color(0xFF6B7280);
                      prefix = "";
                    }

                    final catColor = _getCategoryColor(tx.category);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        onLongPress: () => _confirmDelete(tx),
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isTransfer ? "T" : (tx.category.isNotEmpty ? tx.category[0].toUpperCase() : 'O'),
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isTransfer ? "Transfer" : tx.category,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$prefix${currencyFormat.format(tx.amount)}",
                              style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                tx.notes.isNotEmpty
                                    ? tx.notes
                                    : (isTransfer ? "${tx.account} → ${tx.toAccount}" : tx.account),
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(tx.date),
                              style: const TextStyle(color: Colors.white24, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView(GoogleSheetsProvider provider, NumberFormat currencyFormat) {
    final categoryExpenses = provider.categoryExpenses;
    final budgets = provider.categories.where((c) => c.limit > 0).toList();

    if (categoryExpenses.isEmpty && budgets.isEmpty) {
      return const Center(child: Text("No expense data available for budget plotting", style: TextStyle(color: Colors.grey, fontSize: 12)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Category breakdown header
        const Text(
          "MONTHLY BUDGETS & SPENDING",
          style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),

        if (budgets.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text("No budgets configured in Google Sheets.", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),

        ...budgets.map((budget) {
          final spent = categoryExpenses[budget.name] ?? 0.0;
          final pct = budget.limit > 0 ? (spent / budget.limit) : 0.0;
          final pctClamped = pct.clamp(0.0, 1.0);
          final color = pct > 1.0 ? const Color(0xFFEF4444) : (pct > 0.8 ? Colors.amber : const Color(0xFF10B981));

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(budget.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      "${currencyFormat.format(spent)} / ${currencyFormat.format(budget.limit)} (${(pct * 100).toStringAsFixed(0)}%)",
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pctClamped,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF000000),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 18),
        const Text(
          "ALL OTHER SPENDING",
          style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),

        // List categories without limits
        ...categoryExpenses.keys.where((k) => !budgets.any((b) => b.name == k)).map((catName) {
          final spent = categoryExpenses[catName] ?? 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(catName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormat.format(spent),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
