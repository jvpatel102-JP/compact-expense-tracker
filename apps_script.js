// Google Apps Script for Android Expense Tracker
// Deploy this as a Web App with access set to "Anyone, even anonymous"

function doGet(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet();
  initializeSheets(sheet);
  
  var data = {
    transactions: getSheetData(sheet.getSheetByName("Transactions")),
    categories: getSheetData(sheet.getSheetByName("Categories")),
    accounts: getSheetData(sheet.getSheetByName("Accounts"))
  };
  
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet();
  initializeSheets(sheet);
  
  var response = { success: false, message: "" };
  
  try {
    var postData = JSON.parse(e.postData.contents);
    var action = postData.action;
    
    if (action === "addTransaction") {
      var tx = postData.transaction;
      var txSheet = sheet.getSheetByName("Transactions");
      
      txSheet.appendRow([
        tx.id || Utilities.getUuid(),
        tx.date || new Date().toISOString(),
        tx.type, // "Expense" | "Income" | "Transfer"
        Number(tx.amount),
        tx.category || "",
        tx.account || "",
        tx.toAccount || "",
        tx.notes || ""
      ]);
      
      response.success = true;
      response.message = "Transaction added successfully";
    } else if (action === "deleteTransaction") {
      var id = postData.id;
      var txSheet = sheet.getSheetByName("Transactions");
      var rows = txSheet.getDataRange().getValues();
      var deleted = false;
      
      for (var i = 1; i < rows.length; i++) {
        if (rows[i][0] === id) {
          txSheet.deleteRow(i + 1);
          deleted = true;
          break;
        }
      }
      
      if (deleted) {
        response.success = true;
        response.message = "Transaction deleted successfully";
      } else {
        response.success = false;
        response.message = "Transaction ID not found";
      }
    } else {
      response.message = "Unknown action: " + action;
    }
  } catch (err) {
    response.success = false;
    response.message = "Error: " + err.toString();
  }
  
  return ContentService.createTextOutput(JSON.stringify(response))
    .setMimeType(ContentService.MimeType.JSON);
}

function getSheetData(sheet) {
  var range = sheet.getDataRange();
  var values = range.getValues();
  var headers = values[0];
  var data = [];
  
  for (var i = 1; i < values.length; i++) {
    var row = values[i];
    var obj = {};
    for (var j = 0; j < headers.length; j++) {
      obj[headers[j]] = row[j];
    }
    data.push(obj);
  }
  
  return data;
}

function initializeSheets(sheet) {
  // Check and create Transactions sheet
  var txSheet = sheet.getSheetByName("Transactions");
  if (!txSheet) {
    txSheet = sheet.insertSheet("Transactions");
    txSheet.appendRow(["id", "date", "type", "amount", "category", "account", "toAccount", "notes"]);
    txSheet.getRange("A1:H1").setFontWeight("bold").setBackground("#E2E8F0");
  }
  
  // Check and create Categories sheet
  var catSheet = sheet.getSheetByName("Categories");
  if (!catSheet) {
    catSheet = sheet.insertSheet("Categories");
    catSheet.appendRow(["name", "limit"]);
    catSheet.getRange("A1:B1").setFontWeight("bold").setBackground("#E2E8F0");
    
    // Add default categories
    var defaultCategories = [
      ["Food", 300],
      ["Rent", 1000],
      ["Utilities", 150],
      ["Transport", 100],
      ["Entertainment", 200],
      ["Salary", 0],
      ["Gift", 0],
      ["Other", 100]
    ];
    for (var i = 0; i < defaultCategories.length; i++) {
      catSheet.appendRow(defaultCategories[i]);
    }
  }
  
  // Check and create Accounts sheet
  var accSheet = sheet.getSheetByName("Accounts");
  if (!accSheet) {
    accSheet = sheet.insertSheet("Accounts");
    accSheet.appendRow(["name", "initialBalance"]);
    accSheet.getRange("A1:B1").setFontWeight("bold").setBackground("#E2E8F0");
    
    // Add default accounts
    var defaultAccounts = [
      ["Cash", 200],
      ["Bank", 1500],
      ["Credit Card", 0]
    ];
    for (var i = 0; i < defaultAccounts.length; i++) {
      accSheet.appendRow(defaultAccounts[i]);
    }
  }
}
