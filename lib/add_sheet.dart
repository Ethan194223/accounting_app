// lib/add_sheet.dart

import 'package:flutter/material.dart';
import 'AI_camera_page.dart'; // For the camera functionality
import 'currency_data.dart'; // Import the comprehensive currency list and flag helper

// Note: The main() and MyApp, MyHomePage widgets are typically in main.dart.
// If your add_sheet.dart is intended to be runnable standalone for testing,
// you might keep them, but for integration into your main app, they are usually removed from here.
// For this example, I'll assume AddExpenseSheet is a component used by your main app
// and remove the standalone main(), MyApp, MyHomePage.

class AddExpenseSheet extends StatefulWidget {
  final Function(String title, double amount, String type, String currency, String category) onSubmit;

  const AddExpenseSheet({super.key, required this.onSubmit});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  int _expenseIncomeToggleIndex = 0; // 0: expense, 1: income
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  String? selectedCategory;

  // Use the comprehensive list from currency_data.dart for the picker
  // String selectedCurrency = 'USD'; // Default currency for new transactions
  // Default to HKD as it's the primary display currency in main.dart, or make it configurable
  String selectedTransactionCurrency = 'HKD';


  final List<Map<String, dynamic>> expenseCategories = [
    {'label': 'Food', 'icon': Icons.lunch_dining, 'bgColor': Colors.orange.shade100, 'iconColor': Colors.orange.shade800},
    {'label': 'Transport', 'icon': Icons.directions_bus, 'bgColor': Colors.green.shade100, 'iconColor': Colors.green.shade800},
    {'label': 'Health', 'icon': Icons.local_hospital_outlined, 'bgColor': Colors.teal.shade100, 'iconColor': Colors.teal.shade800},
    {'label': 'Housing', 'icon': Icons.house, 'bgColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800},
    {'label': 'Shopping', 'icon': Icons.shopping_bag, 'bgColor': Colors.pink.shade100, 'iconColor': Colors.pink.shade800},
    {'label': 'Entertainment', 'icon': Icons.sports_esports, 'bgColor': Colors.red.shade100, 'iconColor': Colors.red.shade800},
    {'label': 'Personal', 'icon': Icons.spa, 'bgColor': Colors.purple.shade100, 'iconColor': Colors.purple.shade800},
    {'label': 'Education', 'icon': Icons.menu_book, 'bgColor': Colors.indigo.shade100, 'iconColor': Colors.indigo.shade800},
    {'label': 'Misc.', 'icon': Icons.question_mark, 'bgColor': Colors.amber.shade100, 'iconColor': Colors.amber.shade800},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {'label': 'Salary', 'icon': Icons.account_balance_wallet, 'bgColor': Colors.green.shade100, 'iconColor': Colors.green.shade800},
    {'label': 'Savings', 'icon': Icons.savings, 'bgColor': Colors.pink.shade100, 'iconColor': Colors.pink.shade800},
    {'label': 'Bonus', 'icon': Icons.card_giftcard, 'bgColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800},
    {'label': 'Investment', 'icon': Icons.trending_up, 'bgColor': Colors.purple.shade100, 'iconColor': Colors.purple.shade800},
    {'label': 'Freelance', 'icon': Icons.work, 'bgColor': Colors.orange.shade100, 'iconColor': Colors.orange.shade800},
    {'label': 'Other', 'icon': Icons.attach_money, 'bgColor': Colors.teal.shade100, 'iconColor': Colors.teal.shade800},
  ];

  @override
  void initState() {
    super.initState();
    _resetSelectedCategory();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _resetSelectedCategory() {
    if (_expenseIncomeToggleIndex == 0 && expenseCategories.isNotEmpty) {
      selectedCategory = expenseCategories[0]['label'];
    } else if (_expenseIncomeToggleIndex == 1 && incomeCategories.isNotEmpty) {
      selectedCategory = incomeCategories[0]['label'];
    } else {
      selectedCategory = null;
    }
  }

  void _openCameraPage() async {
    final recognizedText = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const LiveOCRScreen()),
    );
    if (recognizedText != null && recognizedText.isNotEmpty) {
      final cleanedText = recognizedText.replaceAll(RegExp(r'[^\d.]'), '');
      final parsedAmount = double.tryParse(cleanedText);
      if (parsedAmount != null) {
        setState(() {
          amountController.text = parsedAmount.toStringAsFixed(2);
        });
        amountController.selection = TextSelection.fromPosition(
          TextPosition(offset: amountController.text.length),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not parse a valid amount from the image."),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    }
  }

  // --- NEW: Currency Picker Modal (adapted from main.dart) ---
  Future<void> _showTransactionCurrencyPicker(BuildContext context) async {
    String searchTerm = '';
    // Use a local variable for filtered currencies within the modal's state
    List<Map<String, String>> modalFilteredCurrencies = allSupportedCurrencies;

    final String? chosenCurrency = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                  top: 10, left: 10, right: 10
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Select Transaction Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(modalContext).textTheme.titleLarge?.color)),
                            IconButton(icon: Icon(Icons.close, color: Colors.redAccent.withOpacity(0.7), size: 26), onPressed: () => Navigator.pop(modalContext), tooltip: 'Close'),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search currency (e.g., USD or Dollar)',
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(modalContext).primaryColor)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              searchTerm = value.toLowerCase();
                              if (searchTerm.isEmpty) {
                                modalFilteredCurrencies = allSupportedCurrencies;
                              } else {
                                modalFilteredCurrencies = allSupportedCurrencies.where((currency) {
                                  final codeMatch = currency['code']!.toLowerCase().contains(searchTerm);
                                  final nameMatch = currency['name']!.toLowerCase().contains(searchTerm);
                                  return codeMatch || nameMatch;
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: modalFilteredCurrencies.length,
                          itemBuilder: (BuildContext context, int index) {
                            final currency = modalFilteredCurrencies[index];
                            // For the transaction currency picker, 'isSelected' highlights the currently chosen transaction currency
                            bool isCurrentlySelectedInSheet = currency['code'] == selectedTransactionCurrency;
                            return ListTile(
                              leading: Text(currency['flag']!, style: const TextStyle(fontSize: 24)),
                              title: Text(
                                currency['name']!,
                                style: TextStyle(fontWeight: isCurrentlySelectedInSheet ? FontWeight.bold : FontWeight.normal, color: isCurrentlySelectedInSheet ? Theme.of(modalContext).primaryColor : Theme.of(modalContext).textTheme.bodyLarge?.color),
                              ),
                              trailing: Text(
                                currency['code']!,
                                style: TextStyle(fontWeight: isCurrentlySelectedInSheet ? FontWeight.bold : FontWeight.normal, color: isCurrentlySelectedInSheet ? Theme.of(modalContext).primaryColor : Colors.grey.shade600),
                              ),
                              onTap: () {
                                Navigator.pop(modalContext, currency['code']);
                              },
                              tileColor: isCurrentlySelectedInSheet ? Theme.of(modalContext).primaryColor.withOpacity(0.1) : null,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(modalContext).padding.bottom > 0 ? MediaQuery.of(modalContext).padding.bottom : 10),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (chosenCurrency != null && chosenCurrency != selectedTransactionCurrency) {
      setState(() {
        selectedTransactionCurrency = chosenCurrency;
      });
    }
  }
  // --- END NEW ---


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final currentCategories = _expenseIncomeToggleIndex == 0 ? expenseCategories : incomeCategories;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ToggleButtons(
                  isSelected: [_expenseIncomeToggleIndex == 0, _expenseIncomeToggleIndex == 1],
                  onPressed: (index) {
                    if (_expenseIncomeToggleIndex != index) {
                      setState(() {
                        _expenseIncomeToggleIndex = index;
                        _resetSelectedCategory();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(20.0),
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  color: primaryColor,
                  constraints: const BoxConstraints(minHeight: 35.0, minWidth: 100.0),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Expense')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Income')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Amount:', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none, isDense: true),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'Scan Amount',
                    onPressed: _openCameraPage,
                  ),
                  const SizedBox(width: 8),
                  // --- MODIFIED: Currency Picker Button ---
                  InkWell(
                    onTap: () => _showTransactionCurrencyPicker(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Add padding for better tap area
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedTransactionCurrency, // Display the selected currency code
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  )
                  // --- END MODIFIED ---
                ],
              ),
              Divider(color: Colors.grey.shade300, height: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Title:', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(hintText: 'Enter title', border: InputBorder.none, isDense: true),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 20),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: (_expenseIncomeToggleIndex == 1) ? 0.90 : 0.95,
                ),
                itemCount: currentCategories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final cat = currentCategories[index];
                  final isSelected = selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat['label']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(color: isSelected ? primaryColor.withOpacity(0.5) : Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: cat['bgColor'] ?? Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                            child: Icon(cat['icon'] as IconData?, color: cat['iconColor'] ?? primaryColor, size: 28),
                          ),
                          const SizedBox(height: 6),
                          Text(cat['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryColor : Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _submitData,
                child: const Text('Add Record', style: TextStyle(fontSize: 16)),
              ),
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _submitData() {
    FocusScope.of(context).unfocus();
    final title = titleController.text.trim();
    final amountText = amountController.text.trim();

    if (title.isEmpty) { _showValidationError('Please enter a title.'); return; }
    if (amountText.isEmpty) { _showValidationError('Please enter an amount.'); return; }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) { _showValidationError('Please enter a valid positive amount.'); return; }
    if (selectedCategory == null || selectedCategory!.isEmpty) { _showValidationError('Please select a category.'); return; }

    final type = _expenseIncomeToggleIndex == 0 ? 'expense' : 'income';
    widget.onSubmit(title, amount, type, selectedTransactionCurrency, selectedCategory!); // Use selectedTransactionCurrency

    Navigator.of(context).pop();
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 2)),
    );
  }
}


// --- REMOVED Simple Placeholder Camera Page ---
// The CameraPage class definition was removed from here.


