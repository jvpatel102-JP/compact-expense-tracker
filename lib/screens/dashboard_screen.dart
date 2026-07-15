import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/google_sheets_service.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final GoogleSheetsProvider provider;

  const DashboardScreen({super.key, required this.provider});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.provider.sheetUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2230),
          title: const Text(
            "Sheets API Settings",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Paste Google Apps Script Web App URL:",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "https://script.google.com/macros/s/.../exec",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF12141C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.provider.setSheetUrl(_urlController.text);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text("Save & Sync", style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2230),
          title: const Text("Delete Transaction?", style: TextStyle(color: Colors.white, fontSize: 15)),
          content: Text(
            "Are you sure you want to delete this transaction of ${NumberFormat.simpleCurrency(decimalDigits: 2).format(tx.amount)}?",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              child: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13)),
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
    final recentTxs = provider.transactions.take(8).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchData,
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF1E2230),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "BALANCE SUMMARY",
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currencyFormat.format(provider.totalBalance),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          if (provider.isLoading) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
                    onPressed: _showSettingsDialog,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Error banner if any
              if (provider.errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          provider.errorMessage,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Monthly stats widget (Income vs Expense)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2230),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.arrow_downward, color: Color(0xFF10B981), size: 12),
                              SizedBox(width: 4),
                              Text("INCOME", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(provider.monthlyIncome),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2230),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.arrow_upward, color: Color(0xFFEF4444), size: 12),
                              SizedBox(width: 4),
                              Text("EXPENSE", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(provider.monthlyExpense),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Accounts Horizontal List
              const Text(
                "ACCOUNTS",
                style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: provider.accounts.isEmpty
                    ? const Center(child: Text("No accounts found. Sync with Sheets.", style: TextStyle(color: Colors.grey, fontSize: 11)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.accounts.length,
                        itemBuilder: (context, index) {
                          final acc = provider.accounts[index];
                          final balance = provider.accountBalances[acc.name] ?? acc.initialBalance;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2230),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(acc.name, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                                Text(
                                  currencyFormat.format(balance),
                                  style: TextStyle(
                                    color: balance >= 0 ? Colors.white : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT ACTIVITY",
                    style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryScreen(provider: provider)),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("View All", style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Transactions List
              if (recentTxs.isEmpty)
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2230),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "No transactions recorded.\nTap the + button to add one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTxs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF12141C)),
                  itemBuilder: (context, index) {
                    final tx = recentTxs[index];
                    final isExpense = tx.type == TransactionType.expense;
                    final isTransfer = tx.type == TransactionType.transfer;

                    Color amountColor = const Color(0xFF10B981); // Income
                    String prefix = "+";
                    if (isExpense) {
                      amountColor = const Color(0xFFEF4444);
                      prefix = "-";
                    } else if (isTransfer) {
                      amountColor = const Color(0xFF8B5CF6);
                      prefix = "";
                    }

                    return Material(
                      color: const Color(0xFF1E2230),
                      borderRadius: index == 0
                          ? const BorderRadius.vertical(top: Radius.circular(8))
                          : index == recentTxs.length - 1
                              ? const BorderRadius.vertical(bottom: Radius.circular(8))
                              : BorderRadius.zero,
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        onLongPress: () => _confirmDelete(tx),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12141C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isTransfer ? "Transfer" : tx.category,
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isTransfer ? "${tx.account} → ${tx.toAccount}" : tx.account,
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: tx.notes.isNotEmpty
                            ? Text(
                                tx.notes,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                DateFormat('MMM dd, yyyy').format(tx.date),
                                style: const TextStyle(color: Colors.white30, fontSize: 10),
                              ),
                        trailing: Text(
                          "$prefix${currencyFormat.format(tx.amount)}",
                          style: TextStyle(color: amountColor, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 60), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (provider.accounts.isEmpty || provider.categories.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Setup API and load categories/accounts first!"),
                backgroundColor: Colors.amber,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(provider: provider),
            ),
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        mini: true, // Mini FAB to make it compact
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}
