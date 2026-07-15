import 'dart:convert';

enum TransactionType {
  expense,
  income,
  transfer,
}

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}

class TransactionModel {
  final String id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final String category;
  final String account;
  final String toAccount;
  final String notes;

  TransactionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    this.toAccount = '',
    this.notes = '',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'].toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      type: TransactionTypeExtension.fromString(json['type']?.toString() ?? 'Expense'),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      category: json['category']?.toString() ?? '',
      account: json['account']?.toString() ?? '',
      toAccount: json['toAccount']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'amount': amount,
      'category': category,
      'account': account,
      'toAccount': toAccount,
      'notes': notes,
    };
  }
}

class CategoryModel {
  final String name;
  final double limit;

  CategoryModel({
    required this.name,
    required this.limit,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name']?.toString() ?? '',
      limit: double.tryParse(json['limit']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AccountModel {
  final String name;
  final double initialBalance;

  AccountModel({
    required this.name,
    required this.initialBalance,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      name: json['name']?.toString() ?? '',
      initialBalance: double.tryParse(json['initialBalance']?.toString() ?? '0') ?? 0.0,
    );
  }
}
