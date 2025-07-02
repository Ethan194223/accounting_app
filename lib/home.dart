// lib/home.dart
//
// The main “inside” of your app – expense tracker, pet, AR view, etc.
// Exposes one public widget:  HomePage (registered in main.dart as ‘/home’).
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'add_sheet.dart';
import 'ai_chat_page.dart';
import 'analytics_page.dart';
import 'ar_view_page.dart';
import 'currency_data.dart';
import 'e_pet_game.dart';
import 'profile_page.dart';
import 'services/currency_service.dart';

//////////////////////////////////////////////////////////////////////////////
//  PUBLIC ENTRY POINT FOR THE ROUTE TABLE
//////////////////////////////////////////////////////////////////////////////

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) =>
      ExpenseTracker(storage: ExpenseStorage());
}

//////////////////////////////////////////////////////////////////////////////
//  DATA CLASSES & LOCAL PERSISTENCE
//////////////////////////////////////////////////////////////////////////////

class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final String type;     // 'income' | 'expense'
  final String currency;
  final String category;

  Transaction(this.title, this.amount, this.date, this.type, this.currency,
      this.category);

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type,
    'currency': currency,
    'category': category,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    json['title'] ?? 'Untitled',
    (json['amount'] as num?)?.toDouble() ?? 0.0,
    json['date'] != null
        ? DateTime.parse(json['date'])
        : DateTime.now(),
    json['type'] ?? 'expense',
    json['currency'] ?? 'HKD',
    json['category'] ?? 'Misc.',
  );
}

class AppData {
  List<Transaction> transactions;
  DateTime lastInteraction;
  List<DateTime> freeMealDays;

  AppData({
    required this.transactions,
    required this.lastInteraction,
    required this.freeMealDays,
  });

  Map<String, dynamic> toJson() => {
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'lastInteraction': lastInteraction.toIso8601String(),
    'freeMealDays': freeMealDays.map((d) => d.toIso8601String()).toList(),
  };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    transactions: (json['transactions'] as List<dynamic>?)
        ?.map((t) => Transaction.fromJson(t))
        .toList() ??
        [],
    lastInteraction:
    DateTime.tryParse(json['lastInteraction'] ?? '') ?? DateTime.now(),
    freeMealDays: (json['freeMealDays'] as List<dynamic>?)
        ?.map((d) => DateTime.tryParse(d as String))
        .whereType<DateTime>()
        .toList() ??
        [],
  );
}

class ExpenseStorage {
  Future<String> get _localPath async =>
      (await getApplicationDocumentsDirectory()).path;

  Future<File> get _localFile async =>
      File('${await _localPath}/app_data.json');

  Future<AppData> readAppData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return AppData(
            transactions: [], lastInteraction: DateTime.now(), freeMealDays: []);
      }
      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return AppData(
            transactions: [], lastInteraction: DateTime.now(), freeMealDays: []);
      }
      return AppData.fromJson(jsonDecode(raw));
    } catch (_) {
      return AppData(
          transactions: [], lastInteraction: DateTime.now(), freeMealDays: []);
    }
  }

  Future<File> writeAppData(AppData data) async =>
      (await _localFile).writeAsString(jsonEncode(data.toJson()));
}

//////////////////////////////////////////////////////////////////////////////
//  PET MOOD LOGIC   – pure functions
//////////////////////////////////////////////////////////////////////////////

enum PetMood { happy, sick, hungry, lowEnergy, lonely }

final Map<PetMood, String> moodMessages = {
  PetMood.happy:    "Great job! Your pet is full and happy today 🥳",
  PetMood.sick:     "I’m not feeling great... Let’s rest and recover 🩹",
  PetMood.hungry:   "I'm hungry! Log some food expenses or mark a free meal. 🍱",
  PetMood.lowEnergy:"I miss you... Come back soon and let’s save together ⚡",
  PetMood.lonely:   "It’s been a while... Let’s catch up tomorrow 💬",
};

int _daysSinceInteraction(DateTime last) =>
    DateTime.now().difference(
      DateTime(last.year, last.month, last.day),
    ).inDays;

int _countFoodExpensesOnDate(List<Transaction> tx, DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return tx.where((t) {
    final tDate = DateTime(t.date.year, t.date.month, t.date.day);
    return tDate == d &&
        t.type == 'expense' &&
        t.category.toLowerCase().contains('food');
  }).length;
}

double _dailyBalance(List<Transaction> tx, DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final dayTx = tx.where((t) =>
  DateTime(t.date.year, t.date.month, t.date.day) == d);
  final income = dayTx
      .where((t) => t.type == 'income')
      .fold(0.0, (s, t) => s + t.amount);
  final expense = dayTx
      .where((t) => t.type == 'expense')
      .fold(0.0, (s, t) => s + t.amount);
  return income - expense;
}

PetMood getPetMood({
  required double satiety,
  required double happiness,
  required DateTime lastInteraction,
  required List<DateTime> freeMealDays,
}) {
  final days = _daysSinceInteraction(lastInteraction);
  if (days >= 3) return PetMood.lonely;
  if (days >= 1) return PetMood.lowEnergy;

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final hadFreeMeal = freeMealDays.any((d) =>
  DateTime(d.year, d.month, d.day) == todayOnly);

  const satietyThreshold = 50.0;
  const happyThreshold = 70.0;

  if (!hadFreeMeal && satiety < satietyThreshold) return PetMood.hungry;
  if (happiness < happyThreshold) return PetMood.sick;
  return PetMood.happy;
}

//////////////////////////////////////////////////////////////////////////////
//  STATEFUL WIDGETS  – ExpenseTracker / UI
//////////////////////////////////////////////////////////////////////////////

enum BottomContent { transactions, petStatus, reports }
enum ActiveButton { none, reports, petStatus, add }

class ExpenseTracker extends StatefulWidget {
  const ExpenseTracker({super.key, required this.storage});
  final ExpenseStorage storage;

  @override
  State<ExpenseTracker> createState() => _ExpenseTrackerState();
}

class _ExpenseTrackerState extends State<ExpenseTracker> {
  /////////////////////////////////////////////////////////////////////
  // high‑level page state
  /////////////////////////////////////////////////////////////////////
  BottomContent _section = BottomContent.transactions;
  int _navIndex = 2;
  ActiveButton _activeBtn = ActiveButton.none;

  /////////////////////////////////////////////////////////////////////
  // transaction & pet data
  /////////////////////////////////////////////////////////////////////
  List<Transaction> _transactions = [];
  List<Transaction> _filtered = [];
  List<DateTime> _freeMealDays = [];
  DateTime _lastInteraction = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  /////////////////////////////////////////////////////////////////////
  // currency & rates
  /////////////////////////////////////////////////////////////////////
  final CurrencyService _currencyService = CurrencyService();
  Map<String, dynamic> _rates = {};
  bool _loadingRates = false;
  String _displayCurrency = 'HKD';

  /////////////////////////////////////////////////////////////////////
  // pet game & bgm
  /////////////////////////////////////////////////////////////////////
  EPetGame? _game;
  Key _gameKey = UniqueKey();
  final AudioPlayer _bgm = AudioPlayer();

  /////////////////////////////////////////////////////////////////////
  // other pages
  /////////////////////////////////////////////////////////////////////
  List<Widget> get _pages => [
    AnalyticsPage(allTransactions: _transactions), // 0
    const AiChatPage(),                            // 1
    const SizedBox.shrink(),                       // 2 placeholder (Home)
    const ProfilePage(),                           // 3
    const Center(child: Text('Settings (WIP)')),   // 4
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startMusic();
  }

  @override
  void dispose() {
    _bgm.dispose();
    super.dispose();
  }

  /////////////////////////////////////////////////////////////////////
  //  INIT HELPERS
  /////////////////////////////////////////////////////////////////////

  Future<void> _loadData() async {
    final data = await widget.storage.readAppData();
    if (!mounted) return;
    setState(() {
      _transactions = data.transactions;
      _freeMealDays = data.freeMealDays;
      _lastInteraction = data.lastInteraction;
      _selectedDate = DateTime.now();
      _filterByDate(_selectedDate);
    });
    _initOrUpdateGame();
    _fetchRates();
  }

  Future<void> _startMusic() async {
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.play(AssetSource('audio/e_pet_bgmusic.mp3'));
    } catch (_) {
      // silent catch – music failure shouldn’t crash app
    }
  }

  Future<void> _fetchRates() async {
    setState(() => _loadingRates = true);
    final r = await _currencyService.getLatestRates(_displayCurrency);
    if (!mounted) return;
    setState(() {
      _rates = r ?? {};
      _loadingRates = false;
    });
  }

  /////////////////////////////////////////////////////////////////////
  //  PET GAME
  /////////////////////////////////////////////////////////////////////

  Map<String, double> _stateFor(DateTime d) {
    final food = _countFoodExpensesOnDate(_transactions, d);
    final satiety = (30 + food * 25).clamp(0, 100).toDouble();
    final balance = _dailyBalance(_transactions, d);
    final double happiness = balance > 0
        ? 100.0                     // literal is now **double**
        : (40 + balance / 10).clamp(0, 100).toDouble();
    return {
      'satiety': satiety,
      'happiness': happiness,
    };
  }

  void _initOrUpdateGame() {
    final s = _stateFor(_selectedDate);
    if (_game == null) {
      _game = EPetGame(
        initialSatiety: s['satiety']!,
        initialHappiness: s['happiness']!,
      );
      _gameKey = UniqueKey();
    } else {
      _game!
        ..updateSatiety(s['satiety']!)
        ..updateHappiness(s['happiness']!);
    }
    if (mounted) setState(() {});
  }

  void _updateGame() {
    if (_game == null) return;
    final s = _stateFor(_selectedDate);
    _game!
      ..updateSatiety(s['satiety']!)
      ..updateHappiness(s['happiness']!);
    if (mounted) setState(() {});
  }

  /////////////////////////////////////////////////////////////////////
  //  TRANSACTIONS CRUD
  /////////////////////////////////////////////////////////////////////

  void _filterByDate(DateTime d) {
    final target = DateTime(d.year, d.month, d.day);
    _filtered = _transactions
        .where((t) =>
    DateTime(t.date.year, t.date.month, t.date.day) == target)
        .toList();
  }

  Future<void> _addTx(String title, double amount, String type,
      String currency, String category) async {
    if (title.isEmpty || amount <= 0) return;

    final t = Transaction(
        title, amount, _selectedDate, type, currency, category);
    setState(() {
      _transactions.add(t);
      _filterByDate(_selectedDate);
      _lastInteraction = DateTime.now();
    });
    await widget.storage.writeAppData(AppData(
        transactions: _transactions,
        lastInteraction: _lastInteraction,
        freeMealDays: _freeMealDays));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record added: $title')));
      _updateGame();
    }
  }

  Future<void> _deleteTx(Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _transactions.remove(t);
      _filterByDate(_selectedDate);
      _lastInteraction = DateTime.now();
    });
    await widget.storage.writeAppData(AppData(
        transactions: _transactions,
        lastInteraction: _lastInteraction,
        freeMealDays: _freeMealDays));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted.')));
      _updateGame();
    }
  }

  /////////////////////////////////////////////////////////////////////
  //  UI HELPERS
  /////////////////////////////////////////////////////////////////////

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterByDate(picked);
      });
      _updateGame();
    }
  }

  Future<void> _showAddSheet() async {
    setState(() => _activeBtn = ActiveButton.add);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseSheet(onSubmit: _addTx),
    );
    if (mounted) setState(() => _activeBtn = ActiveButton.none);
  }

  Future<void> _showCurrencyPicker() async {
    String term = '';
    List<Map<String, String>> filtered = allSupportedCurrencies;

    final res = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: DraggableScrollableSheet(
            expand: false,
            builder: (_, sc) => Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    decoration: const InputDecoration(
                        hintText: 'Search currency',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (v) {
                      setModal(() {
                        term = v.toLowerCase();
                        filtered = term.isEmpty
                            ? allSupportedCurrencies
                            : allSupportedCurrencies.where((c) {
                          return c['code']!.toLowerCase().contains(term) ||
                              c['name']!.toLowerCase().contains(term);
                        }).toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: sc,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final selected = c['code'] == _displayCurrency;
                      return ListTile(
                        leading: Text(c['flag']!, style: const TextStyle(fontSize: 22)),
                        title: Text(c['name']!,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        trailing: Text(c['code']!,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        selected: selected,
                        onTap: () => Navigator.pop(ctx, c['code']),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (res != null && res != _displayCurrency) {
      setState(() => _displayCurrency = res);
      _fetchRates();
    }
  }

  double _convert(double amt, String cur) {
    if (cur == _displayCurrency) return amt;
    if (_loadingRates || _rates.isEmpty) return amt;
    final rate = _rates[cur.toUpperCase()];
    if (rate is num && rate > 0) return amt / rate.toDouble();
    return amt;
  }

  /////////////////////////////////////////////////////////////////////
  //  BUILD
  /////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // running balance for info card
    double balance = 0;
    for (final t in _filtered) {
      final v = _convert(t.amount, t.currency);
      balance += t.type == 'income' ? v : -v;
    }

    Widget body;
    switch (_section) {
      case BottomContent.transactions:
      case BottomContent.reports:
        body = _buildTransactionList();
        break;
      case BottomContent.petStatus:
        body = _buildPetStatus();
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: _navIndex == 2  // Home tab shows pet header + content
            ? Column(
          children: [
            _buildPetHeader(),
            _buildInfoCard(balance),
            Expanded(child: body),
          ],
        )
            : _pages[_navIndex],
      ),
      bottomNavigationBar: _buildNavBar(theme),
    );
  }

  /////////////////////////////////////////////////////////////////////
  //  UI sections
  /////////////////////////////////////////////////////////////////////

  Widget _buildPetHeader() => GestureDetector(
    onTap: () => setState(() => _section = BottomContent.petStatus),
    child: Container(
      color: Colors.grey.shade100,
      height: MediaQuery.of(context).size.height * 0.25,
      child: _game == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        alignment: Alignment.center,
        children: [
          GameWidget(key: _gameKey, game: _game!),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.4),
                  shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.view_in_ar_outlined),
                color: Colors.white,
                tooltip: 'AR Pet View',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ARViewPage())),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildInfoCard(double balance) => Padding(
    padding: const EdgeInsets.all(12),
    child: Card(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 6),
                      Text(_isToday(_selectedDate)
                          ? 'Today'
                          : DateFormat('MMM d, EEEE').format(_selectedDate)),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _showCurrencyPicker,
                  child: Row(
                    children: [
                      if (_loadingRates)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      Text(NumberFormat.currency(
                          symbol: '$_displayCurrency ', decimalDigits: 2)
                          .format(balance),
                          style: TextStyle(
                              color: balance >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(Icons.receipt_long, 'Records',
                        () => setState(() => _section = BottomContent.transactions)),
                _actionButton(Icons.pets, 'Pet',
                        () => setState(() => _section = BottomContent.petStatus)),
                _actionButton(Icons.add_circle, 'Add', _showAddSheet,
                    isAdd: true),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _actionButton(IconData icon, String label, VoidCallback onTap,
      {bool isAdd = false}) {
    final active = (_section == BottomContent.transactions && label == 'Records') ||
        (_section == BottomContent.petStatus && label == 'Pet');
    final bg = active || isAdd
        ? Theme.of(context).colorScheme.primary.withOpacity(.1)
        : Colors.grey.shade200;
    final fg = active || isAdd
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade700;
    return TextButton(
      style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isAdd ? 32 : 24),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_filtered.isEmpty) {
      return Center(
          child: Text('No transactions.',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final t = _filtered[i];
        final convert = _convert(t.amount, t.currency);
        final showOriginal = t.currency != _displayCurrency && !_loadingRates;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: _categoryIcon(t.category, t.type),
            title: Text(t.title),
            subtitle: Text(t.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${t.type == 'expense' ? '-' : '+'}${NumberFormat.currency(symbol: '$_displayCurrency ').format(convert)}',
                      style: TextStyle(
                          color: t.type == 'expense'
                              ? Colors.red.shade600
                              : Colors.green.shade600),
                    ),
                    if (showOriginal)
                      Text('(${t.currency} ${t.amount.toStringAsFixed(2)})',
                          style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400),
                    onPressed: () => _deleteTx(t)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetStatus() {
    if (_game == null) return const Center(child: CircularProgressIndicator());

    final sat = _game!.satiety;
    final happy = _game!.happiness;
    final days = _daysSinceInteraction(_lastInteraction);
    final energy = days == 0 ? 100 : days == 1 ? 60 : 20;
    final mood = getPetMood(
        satiety: sat,
        happiness: happy,
        lastInteraction: _lastInteraction,
        freeMealDays: _freeMealDays);

    Widget bar(String label, int val, IconData icon, Color color) => Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: val / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$val%'),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Pet Status',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(moodMessages[mood]!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              bar('Satiety', sat.toInt(), Icons.restaurant_menu,
                  Colors.orange.shade400),
              const SizedBox(height: 12),
              bar('Happiness', happy.toInt(), Icons.sentiment_satisfied,
                  Colors.green.shade400),
              const SizedBox(height: 12),
              bar('Energy', energy, Icons.bolt, Colors.blue.shade400),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildNavBar(ThemeData theme) => BottomNavigationBar(
    currentIndex: _navIndex,
    onTap: (i) {
      if (_navIndex == i) return;
      if (i == 2) _section = BottomContent.transactions;
      setState(() => _navIndex = i);
    },
    selectedItemColor: theme.colorScheme.primary,
    unselectedItemColor: Colors.grey.shade600,
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Analytics'),
      BottomNavigationBarItem(
          icon: Icon(Icons.psychology_alt_outlined),
          activeIcon: Icon(Icons.psychology_alt),
          label: 'AI'),
      BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
      BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings'),
    ],
  );

  /////////////////////////////////////////////////////////////////////
  //  ICONS
  /////////////////////////////////////////////////////////////////////

  Icon _categoryIcon(String cat, String type) {
    IconData data;
    if (type == 'income') {
      switch (cat.toLowerCase()) {
        case 'salary':
          data = Icons.account_balance_wallet;
          break;
        case 'savings':
          data = Icons.savings;
          break;
        case 'bonus':
          data = Icons.card_giftcard;
          break;
        default:
          data = Icons.attach_money;
      }
      return Icon(data, color: Colors.green.shade600);
    } else {
      switch (cat.toLowerCase()) {
        case 'food':
        case 'dining':
        case 'groceries':
          data = Icons.lunch_dining;
          break;
        case 'transport':
          data = Icons.directions_bus;
          break;
        case 'health':
          data = Icons.local_hospital_outlined;
          break;
        case 'shopping':
          data = Icons.shopping_bag;
          break;
        default:
          data = Icons.receipt_long;
      }
      return Icon(data, color: Colors.red.shade600);
    }
  }
}

