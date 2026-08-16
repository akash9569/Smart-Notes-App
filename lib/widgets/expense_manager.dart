import 'package:flutter/material.dart';
import '../app_theme.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
const Color _kIncomeColor = Color(0xFF10B981); // Emerald
const Color _kExpenseColor = Color(0xFFF43F5E); // Rose / Coral
const Color _kLendColor = Color(0xFF3B82F6); // Blue
const Color _kBorrowColor = Color(0xFFF59E0B); // Amber
const Color _kCoral = Color(0xFFF08A82);

enum TransactionType { income, expense }

class Transaction {
  String id;
  String title;
  double amount;
  String date;
  String category;
  TransactionType type;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date,
        'category': category,
        'type': type.index,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        date: json['date'],
        category: json['category'],
        type: TransactionType.values[json['type'] ?? 1],
      );
}

enum LoanType { lend, borrow }

class Loan {
  String id;
  String person;
  double amount;
  double outstanding;
  String dueDate;
  LoanType type;
  bool isCompleted;

  Loan({
    required this.id,
    required this.person,
    required this.amount,
    required this.outstanding,
    required this.dueDate,
    required this.type,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'amount': amount,
        'outstanding': outstanding,
        'dueDate': dueDate,
        'type': type.index,
        'isCompleted': isCompleted,
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'],
        person: json['person'],
        amount: (json['amount'] as num).toDouble(),
        outstanding: (json['outstanding'] as num).toDouble(),
        dueDate: json['dueDate'],
        type: LoanType.values[json['type']],
        isCompleted: json['isCompleted'] ?? false,
      );
}

class ExpenseManager extends StatefulWidget {
  final List<Transaction> transactions;
  final Function(List<Transaction>) onTransactionsChanged;
  final List<Loan> loans;
  final Function(List<Loan>) onLoansChanged;

  const ExpenseManager({
    super.key,
    required this.transactions,
    required this.onTransactionsChanged,
    required this.loans,
    required this.onLoansChanged,
  });

  @override
  State<ExpenseManager> createState() => _ExpenseManagerState();
}

class _ExpenseManagerState extends State<ExpenseManager> {
  String _selectedTab = 'All'; // 'All', 'Income', 'Expense', 'Loans'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addTransaction(String title, double amount, String category,
      TransactionType type, String dateStr) {
    final updated = List<Transaction>.from(widget.transactions)
      ..insert(
        0,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          amount: amount,
          date: dateStr,
          category: category,
          type: type,
        ),
      );
    widget.onTransactionsChanged(updated);
  }

  void _addLoan(String person, double amount, String dueDate, LoanType type) {
    final updated = List<Loan>.from(widget.loans)
      ..insert(
        0,
        Loan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          person: person,
          amount: amount,
          outstanding: amount,
          dueDate: dueDate,
          type: type,
        ),
      );
    widget.onLoansChanged(updated);
  }

  void _deleteTransaction(String id) {
    final updated = widget.transactions.where((t) => t.id != id).toList();
    widget.onTransactionsChanged(updated);
  }

  void _deleteLoan(String id) {
    final updated = widget.loans.where((l) => l.id != id).toList();
    widget.onLoansChanged(updated);
  }

  void _settleLoan(Loan loan) {
    final updated = widget.loans.map((l) {
      if (l.id == loan.id) {
        return Loan(
          id: l.id,
          person: l.person,
          amount: l.amount,
          outstanding: 0,
          dueDate: l.dueDate,
          type: l.type,
          isCompleted: true,
        );
      }
      return l;
    }).toList();
    widget.onLoansChanged(updated);
  }

  double get _totalIncome => widget.transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalExpenses => widget.transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalLent => widget.loans
      .where((l) => l.type == LoanType.lend && !l.isCompleted)
      .fold(0, (sum, l) => sum + l.outstanding);

  double get _totalBorrowed => widget.loans
      .where((l) => l.type == LoanType.borrow && !l.isCompleted)
      .fold(0, (sum, l) => sum + l.outstanding);

  List<Transaction> get _filteredTransactions {
    return widget.transactions.where((tx) {
      if (_selectedTab == 'Income' && tx.type != TransactionType.income) {
        return false;
      }
      if (_selectedTab == 'Expense' && tx.type != TransactionType.expense) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = tx.title.toLowerCase().contains(query);
        final matchesCat = tx.category.toLowerCase().contains(query);
        return matchesTitle || matchesCat;
      }
      return true;
    }).toList();
  }

  List<Loan> get _filteredLoans {
    return widget.loans.where((l) {
      if (_searchQuery.isNotEmpty) {
        return l.person.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalIncome - _totalExpenses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 36,
        16,
        isMobile ? 18 : 36,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. TOP HEADER (Fixed) ───
          _buildTopHeader(isMobile),
          const SizedBox(height: 14),

          // ─── 2. BALANCE HERO & SUMMARY CARD (Fixed) ───
          _buildBalanceHeroCard(balance, isMobile),
          const SizedBox(height: 14),

          // ─── 3. SEGMENTED TABS (ALL / INCOME / EXPENSES / LOANS) (Fixed) ───
          _buildSegmentedFilterBar(),
          const SizedBox(height: 12),

          // ─── 4. SEARCH BAR (Fixed) ───
          if (_selectedTab != 'Loans') ...[
            _buildSearchBar(),
            const SizedBox(height: 14),
          ],

          // ─── 5. SCROLLABLE TRANSACTION HISTORY / LOANS SECTION ───
          Expanded(
            child: _selectedTab == 'Loans'
                ? _buildLoansSection(isMobile)
                : _buildTransactionsSection(isMobile),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Finance & ',
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      color: _kCoral,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Track your balance, cashflow & loans',
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Income Button
            _buildHeaderActionButton(
              tooltip: 'Add Income',
              icon: Icons.add_rounded,
              color: _kIncomeColor,
              onTap: () => _showAddTransactionDialog(TransactionType.income),
            ),
            const SizedBox(width: 8),
            // Add Expense Button
            _buildHeaderActionButton(
              tooltip: 'Add Expense',
              icon: Icons.remove_rounded,
              color: _kExpenseColor,
              onTap: () => _showAddTransactionDialog(TransactionType.expense),
            ),
            const SizedBox(width: 8),
            // Add Loan Button
            _buildHeaderActionButton(
              tooltip: 'Add Loan',
              icon: Icons.handshake_outlined,
              color: _kLendColor,
              onTap: () => _showAddLoanDialogChoice(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. BALANCE HERO & SUMMARY CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBalanceHeroCard(double balance, bool isMobile) {
    final income = _totalIncome;
    final expense = _totalExpenses;
    final percent = income > 0 ? (expense / income * 100).clamp(0, 100) : 0.0;
    final isHealthy = percent < 75;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL NET BALANCE',
                    style: TextStyle(
                      color: context.themeTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isHealthy ? _kIncomeColor : _kExpenseColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHealthy ? 'Healthy Cashflow' : 'High Spending',
                  style: TextStyle(
                    color: isHealthy ? _kIncomeColor : _kExpenseColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini Stat Capsules
          Row(
            children: [
              Expanded(
                child: _buildMetricCapsule(
                  label: 'Total Income',
                  value: '+₹${income.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                  color: _kIncomeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCapsule(
                  label: 'Total Expenses',
                  value: '-₹${expense.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                  color: _kExpenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Spending Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percent.toInt()}% of income spent',
                    style: TextStyle(
                      color: context.themeTextSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${(income - expense).clamp(0, double.infinity).toStringAsFixed(0)} savings',
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0,
                  minHeight: 6,
                  backgroundColor:
                      context.themeTextPrimary.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isHealthy ? _kIncomeColor : _kExpenseColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCapsule({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.themeTextPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.themeTextSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. SEGMENTED FILTER BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedFilterBar() {
    final tabs = [
      {'key': 'All', 'label': 'All', 'count': widget.transactions.length},
      {
        'key': 'Income',
        'label': 'Income',
        'count': widget.transactions
            .where((t) => t.type == TransactionType.income)
            .length
      },
      {
        'key': 'Expense',
        'label': 'Expenses',
        'count': widget.transactions
            .where((t) => t.type == TransactionType.expense)
            .length
      },
      {
        'key': 'Loans',
        'label': 'Loan Book',
        'count': widget.loans.where((l) => !l.isCompleted).length
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = tab['key'] as String),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _kCoral
                      : context.themeTextPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _kCoral
                        : context.themeTextPrimary.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : context.themeTextPrimary,
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : context.themeTextPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${tab['count']}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.themeTextSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. SEARCH & CATEGORY PILLS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: TextStyle(
          color: context.themeTextPrimary,
          fontSize: 13.5,
        ),
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: TextStyle(
            color: context.themeTextSecondary.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.themeTextSecondary,
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  color: context.themeTextSecondary,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. TRANSACTIONS SECTION (SCROLLABLE LIST)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTransactionsSection(bool isMobile) {
    final list = _filteredTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRANSACTION HISTORY',
              style: TextStyle(
                color: context.themeTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.themeTextPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${list.length} ${list.length == 1 ? 'Record' : 'Records'}',
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildEmptyTransactionsView(),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final tx = list[index];
                    final isIncome = tx.type == TransactionType.income;
                    final color = isIncome ? _kIncomeColor : _kExpenseColor;
                    IconData catIcon = Icons.category_rounded;

                    if (tx.category == 'Food') catIcon = Icons.restaurant_rounded;
                    if (tx.category == 'Transport') catIcon = Icons.directions_car_rounded;
                    if (tx.category == 'Shopping') catIcon = Icons.shopping_bag_rounded;
                    if (tx.category == 'Bills') catIcon = Icons.receipt_rounded;
                    if (tx.category == 'Salary') catIcon = Icons.account_balance_rounded;
                    if (tx.category == 'Freelance') catIcon = Icons.laptop_mac_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.themeTextPrimary
                              .withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(catIcon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: TextStyle(
                                    color: context.themeTextPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: context.themeTextPrimary
                                            .withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.category,
                                        style: TextStyle(
                                          color: context.themeTextSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tx.date,
                                      style: TextStyle(
                                        color: context.themeTextSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () => _deleteTransaction(tx.id),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactionsView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: context.themeTextSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            'No Transactions Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + or - at the top to record income or expense.',
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. LOANS SECTION (SCROLLABLE LIST)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLoansSection(bool isMobile) {
    final list = _filteredLoans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loans Summary Cards (Fixed)
        Row(
          children: [
            Expanded(
              child: _buildLoanSummaryTile(
                label: 'You Lent (Receivable)',
                amount: _totalLent,
                color: _kLendColor,
                icon: Icons.north_east_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLoanSummaryTile(
                label: 'You Borrowed (Payable)',
                amount: _totalBorrowed,
                color: _kBorrowColor,
                icon: Icons.south_west_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE LOAN RECORDS',
              style: TextStyle(
                color: context.themeTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            Row(
              children: [
                _buildSmallActionPill(
                  label: '+ Lend',
                  color: _kLendColor,
                  onTap: () => _showLoanDialog(LoanType.lend),
                ),
                const SizedBox(width: 6),
                _buildSmallActionPill(
                  label: '+ Borrow',
                  color: _kBorrowColor,
                  onTap: () => _showLoanDialog(LoanType.borrow),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        Expanded(
          child: list.isEmpty
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildEmptyLoansView(),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final loan = list[index];
                    final isLend = loan.type == LoanType.lend;
                    final color = isLend ? _kLendColor : _kBorrowColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: loan.isCompleted
                              ? _kIncomeColor.withValues(alpha: 0.2)
                              : context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isLend
                                      ? Icons.north_east_rounded
                                      : Icons.south_west_rounded,
                                  size: 16,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.person,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      isLend
                                          ? 'Money Lent'
                                          : 'Money Borrowed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (loan.isCompleted
                                          ? _kIncomeColor
                                          : color)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  loan.isCompleted
                                      ? 'Settled'
                                      : (isLend ? 'Lent' : 'Borrowed'),
                                  style: TextStyle(
                                    color: loan.isCompleted
                                        ? _kIncomeColor
                                        : color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Outstanding',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '₹${loan.outstanding.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Due Date',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    loan.dueDate.isNotEmpty
                                        ? loan.dueDate
                                        : 'No date',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (!loan.isCompleted) ...[
                                    InkWell(
                                      onTap: () => _settleLoan(loan),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _kIncomeColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Settle',
                                          style: TextStyle(
                                            color: _kIncomeColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16),
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.7),
                                    onPressed: () =>
                                        _deleteLoan(loan.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyLoansView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 36,
            color: context.themeTextSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            'No Loan Records Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track money lent to or borrowed from friends.',
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSummaryTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.themeTextSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionPill({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddLoanDialogChoice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.themeTextPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Select Loan Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showLoanDialog(LoanType.lend);
                    },
                    icon: const Icon(Icons.north_east_rounded),
                    label: const Text('Lend Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kLendColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showLoanDialog(LoanType.borrow);
                    },
                    icon: const Icon(Icons.south_west_rounded),
                    label: const Text('Borrow Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBorrowColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. KEYBOARD-SAFE MODERN DIALOGS
  // ───────────────────────────────────────────────────────────────────────────
  void _showAddTransactionDialog(TransactionType type) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'General';
    DateTime selectedDate = DateTime.now();
    final categories = type == TransactionType.expense
        ? ['Food', 'Transport', 'Shopping', 'Bills', 'General']
        : ['Salary', 'Freelance', 'Gift', 'General'];
    final isIncome = type == TransactionType.income;
    final accentColor = isIncome ? _kIncomeColor : _kExpenseColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final totalHeight = MediaQuery.of(context).size.height;
          final availableHeight = totalHeight - bottomInset;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: (availableHeight * 0.90).clamp(280.0, 720.0),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.themeCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.themeTextPrimary.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isIncome ? 'Add Income' : 'Add Expense',
                                  style: TextStyle(
                                    color: context.themeTextPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 20, color: context.themeTextSecondary),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),

                      // Form Body
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDialogField(
                                controller: titleController,
                                label: 'Title (e.g. Groceries, Freelance)',
                                icon: Icons.edit_rounded,
                                accentColor: accentColor,
                              ),
                              const SizedBox(height: 14),
                              _buildDialogField(
                                controller: amountController,
                                label: 'Amount (₹)',
                                icon: Icons.currency_rupee_rounded,
                                keyboardType: TextInputType.number,
                                accentColor: accentColor,
                              ),
                              const SizedBox(height: 16),

                              // ── Transaction Date Section ──
                              Text(
                                'TRANSACTION DATE',
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => selectedDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.themeTextPrimary
                                        .withValues(alpha: 0.035),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          accentColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: accentColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.calendar_month_rounded,
                                          color: accentColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatDateLabel(selectedDate),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: context.themeTextPrimary,
                                              ),
                                            ),
                                            Text(
                                              'Tap to change transaction date',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    context.themeTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 18,
                                        color: accentColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _dateChip(
                                      label: 'Today',
                                      targetDate: DateTime.now(),
                                      selectedDate: selectedDate,
                                      onSelect: (d) => setDialogState(
                                          () => selectedDate = d),
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    _dateChip(
                                      label: 'Yesterday',
                                      targetDate: DateTime.now()
                                          .subtract(const Duration(days: 1)),
                                      selectedDate: selectedDate,
                                      onSelect: (d) => setDialogState(
                                          () => selectedDate = d),
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    _dateChip(
                                      label: '2 Days Ago',
                                      targetDate: DateTime.now()
                                          .subtract(const Duration(days: 2)),
                                      selectedDate: selectedDate,
                                      onSelect: (d) => setDialogState(
                                          () => selectedDate = d),
                                      accentColor: accentColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Text(
                                'CATEGORY',
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categories.map((cat) {
                                  final isSel = selectedCategory == cat;
                                  return GestureDetector(
                                    onTap: () => setDialogState(
                                        () => selectedCategory = cat),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? accentColor
                                                .withValues(alpha: 0.15)
                                            : context.themeTextPrimary
                                                .withValues(alpha: 0.04),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSel
                                              ? accentColor
                                              : context.themeTextPrimary
                                                  .withValues(alpha: 0.06),
                                        ),
                                      ),
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          color: isSel
                                              ? accentColor
                                              : context.themeTextPrimary,
                                          fontWeight: isSel
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final amount = double.tryParse(
                                    amountController.text.trim());
                                if (titleController.text.trim().isNotEmpty &&
                                    amount != null &&
                                    amount > 0) {
                                  final dateStr =
                                      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
                                  _addTransaction(
                                    titleController.text.trim(),
                                    amount,
                                    selectedCategory,
                                    type,
                                    dateStr,
                                  );
                                  Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Transaction',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLoanDialog(LoanType type) {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    final isLend = type == LoanType.lend;
    final accentColor = isLend ? _kLendColor : _kBorrowColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final totalHeight = MediaQuery.of(context).size.height;
          final availableHeight = totalHeight - bottomInset;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: (availableHeight * 0.90).clamp(280.0, 720.0),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.themeCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.themeTextPrimary.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isLend
                                        ? Icons.north_east_rounded
                                        : Icons.south_west_rounded,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isLend ? 'Lend Money' : 'Borrow Money',
                                  style: TextStyle(
                                    color: context.themeTextPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 20, color: context.themeTextSecondary),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDialogField(
                                controller: personController,
                                label: 'Person Name (e.g. Rahul, Priya)',
                                icon: Icons.person_rounded,
                                accentColor: accentColor,
                              ),
                              const SizedBox(height: 14),
                              _buildDialogField(
                                controller: amountController,
                                label: 'Amount (₹)',
                                icon: Icons.currency_rupee_rounded,
                                keyboardType: TextInputType.number,
                                accentColor: accentColor,
                              ),
                              const SizedBox(height: 16),

                              // Due Date Section
                              Text(
                                'DUE DATE',
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => dueDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.themeTextPrimary
                                        .withValues(alpha: 0.035),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          accentColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: accentColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.calendar_month_rounded,
                                          color: accentColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: context.themeTextPrimary,
                                              ),
                                            ),
                                            Text(
                                              'Tap to set repayment due date',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    context.themeTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 18,
                                        color: accentColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _dateChip(
                                      label: 'In 7 Days',
                                      targetDate: DateTime.now()
                                          .add(const Duration(days: 7)),
                                      selectedDate: dueDate,
                                      onSelect: (d) =>
                                          setDialogState(() => dueDate = d),
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    _dateChip(
                                      label: 'In 15 Days',
                                      targetDate: DateTime.now()
                                          .add(const Duration(days: 15)),
                                      selectedDate: dueDate,
                                      onSelect: (d) =>
                                          setDialogState(() => dueDate = d),
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    _dateChip(
                                      label: 'In 30 Days',
                                      targetDate: DateTime.now()
                                          .add(const Duration(days: 30)),
                                      selectedDate: dueDate,
                                      onSelect: (d) =>
                                          setDialogState(() => dueDate = d),
                                      accentColor: accentColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final amount = double.tryParse(
                                    amountController.text.trim());
                                if (personController.text.trim().isNotEmpty &&
                                    amount != null &&
                                    amount > 0) {
                                  final dueDateStr =
                                      '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
                                  _addLoan(personController.text.trim(),
                                      amount, dueDateStr, type);
                                  Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Loan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    if (difference == 0) return 'Today ($dateStr)';
    if (difference == 1) return 'Yesterday ($dateStr)';
    return dateStr;
  }

  Widget _dateChip({
    required String label,
    required DateTime targetDate,
    required DateTime selectedDate,
    required Function(DateTime) onSelect,
    required Color accentColor,
  }) {
    final isSel = selectedDate.year == targetDate.year &&
        selectedDate.month == targetDate.month &&
        selectedDate.day == targetDate.day;
    return GestureDetector(
      onTap: () => onSelect(targetDate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel
              ? accentColor
              : context.themeTextPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel
                ? accentColor
                : context.themeTextPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSel ? Colors.white : context.themeTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeTextPrimary.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: context.themeTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: context.themeTextSecondary.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: context.themeTextSecondary, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}