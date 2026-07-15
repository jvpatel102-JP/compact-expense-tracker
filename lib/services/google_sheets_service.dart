import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class GoogleSheetsService {
  // Make a request and manually follow redirects if necessary
  static Future<Map<String, dynamic>> get(String url) async {
    if (url.isEmpty) throw Exception("API URL is empty");
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        final redirectRes = await http.get(Uri.parse(redirectUrl));
        return jsonDecode(redirectRes.body);
      }
    }
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load data: ${response.statusCode}");
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    if (url.isEmpty) throw Exception("API URL is empty");

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    // Apps Script redirects the output of doPost
    if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        final redirectRes = await http.get(Uri.parse(redirectUrl));
        return jsonDecode(redirectRes.body);
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to post data: ${response.statusCode}");
  }
}

class GoogleSheetsProvider extends ChangeNotifier {
  String _sheetUrl = "";
  bool _isLoading = false;
  String _errorMessage = "";

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];

  String get sheetUrl => _sheetUrl;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  List<AccountModel> get accounts => _accounts;

  // Constructor loads cached data first
  GoogleSheetsProvider() {
    _loadSettingsAndCache();
  }

  Future<void> _loadSettingsAndCache() async {
    final prefs = await SharedPreferences.getInstance();
    _sheetUrl = prefs.getString("sheet_url") ?? "";
    
    // Load cached lists
    final txJson = prefs.getString("cached_transactions");
    if (txJson != null) {
      try {
        final List decoded = jsonDecode(txJson);
        _transactions = decoded.map((e) => TransactionModel.fromJson(e)).toList();
      } catch (e) {
        if (kDebugMode) print("Error parsing cached transactions: $e");
      }
    }

    final catJson = prefs.getString("cached_categories");
    if (catJson != null) {
      try {
        final List decoded = jsonDecode(catJson);
        _categories = decoded.map((e) => CategoryModel.fromJson(e)).toList();
      } catch (e) {
        if (kDebugMode) print("Error parsing cached categories: $e");
      }
    }

    final accJson = prefs.getString("cached_accounts");
    if (accJson != null) {
      try {
        final List decoded = jsonDecode(accJson);
        _accounts = decoded.map((e) => AccountModel.fromJson(e)).toList();
      } catch (e) {
        if (kDebugMode) print("Error parsing cached accounts: $e");
      }
    }

    notifyListeners();
    
    // Automatically trigger a refresh if we have a URL
    if (_sheetUrl.isNotEmpty) {
      fetchData();
    }
  }

  Future<void> setSheetUrl(String url) async {
    _sheetUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("sheet_url", _sheetUrl);
    notifyListeners();
    if (_sheetUrl.isNotEmpty) {
      fetchData();
    }
  }

  // Fetch from sheet API
  Future<void> fetchData() async {
    if (_sheetUrl.isEmpty) {
      _errorMessage = "Please set the Google Sheets URL in settings.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      final data = await GoogleSheetsService.get(_sheetUrl);
      
      // Parse Transactions
      final List txList = data['transactions'] ?? [];
      _transactions = txList.map((e) => TransactionModel.fromJson(e)).toList();
      // Sort: Newest first
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      // Parse Categories
      final List catList = data['categories'] ?? [];
      _categories = catList.map((e) => CategoryModel.fromJson(e)).toList();

      // Parse Accounts
      final List accList = data['accounts'] ?? [];
      _accounts = accList.map((e) => AccountModel.fromJson(e)).toList();

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("cached_transactions", jsonEncode(_transactions.map((e) => e.toJson()).toList()));
      await prefs.setString("cached_categories", jsonEncode(catList));
      await prefs.setString("cached_accounts", jsonEncode(accList));

      _errorMessage = "";
    } catch (e) {
      _errorMessage = "Failed to sync: ${e.toString()}";
      if (kDebugMode) print("Fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a transaction
  Future<bool> addTransaction(TransactionModel transaction) async {
    // 1. Optimistic UI update (append immediately to local state)
    _transactions.insert(0, transaction);
    notifyListeners();

    if (_sheetUrl.isEmpty) {
      _errorMessage = "Sheet URL not set. Transaction added locally only.";
      notifyListeners();
      return false;
    }

    try {
      final body = {
        "action": "addTransaction",
        "transaction": transaction.toJson()
      };
      
      final response = await GoogleSheetsService.post(_sheetUrl, body);
      
      if (response['success'] == true) {
        // Trigger a background refresh to make sure we are synced
        fetchData();
        return true;
      } else {
        throw Exception(response['message'] ?? "Unknown error");
      }
    } catch (e) {
      _errorMessage = "Failed to send transaction: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(String id) async {
    // Optimistic remove
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();

    if (_sheetUrl.isEmpty) return false;

    try {
      final body = {
        "action": "deleteTransaction",
        "id": id
      };
      final response = await GoogleSheetsService.post(_sheetUrl, body);
      if (response['success'] == true) {
        fetchData();
        return true;
      } else {
        throw Exception(response['message'] ?? "Unknown error");
      }
    } catch (e) {
      _errorMessage = "Failed to delete: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // Calculated Metrics
  double get totalBalance {
    double balance = 0.0;
    // Sum initial balances of all accounts
    for (var acc in _accounts) {
      balance += acc.initialBalance;
    }
    
    // Process transactions
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        balance -= tx.amount;
      }
      // Transfers between accounts don't change the net balance
    }
    return balance;
  }

  Map<String, double> get accountBalances {
    final Map<String, double> balances = {};
    for (var acc in _accounts) {
      balances[acc.name] = acc.initialBalance;
    }

    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        balances[tx.account] = (balances[tx.account] ?? 0.0) + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        balances[tx.account] = (balances[tx.account] ?? 0.0) - tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        balances[tx.account] = (balances[tx.account] ?? 0.0) - tx.amount;
        balances[tx.toAccount] = (balances[tx.toAccount] ?? 0.0) + tx.amount;
      }
    }
    return balances;
  }

  double get monthlyIncome {
    final now = DateTime.now();
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        total += tx.amount;
      }
    }
    return total;
  }

  double get monthlyExpense {
    final now = DateTime.now();
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        total += tx.amount;
      }
    }
    return total;
  }

  Map<String, double> get categoryExpenses {
    final now = DateTime.now();
    final Map<String, double> categoriesMap = {};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        categoriesMap[tx.category] = (categoriesMap[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return categoriesMap;
  }
}
