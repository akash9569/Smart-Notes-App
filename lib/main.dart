import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'app_theme.dart';
import 'widgets/sidebar.dart';
import 'widgets/dashboard.dart';
import 'widgets/expense_manager.dart';
import 'widgets/task_manager.dart';
import 'widgets/notes_manager.dart';
import 'widgets/calendar_view.dart';
import 'widgets/sticky_notes_view.dart';
import 'widgets/habit_tracker_view.dart';
import 'widgets/profile_view.dart';
import 'widgets/journal_view.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart'; // ─── NEW IMPORT ───
import 'services/notification_service.dart';

final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // ─── CHECK FIRST LAUNCH & THEME ───
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
  final bool isDark = prefs.getBool('dark_mode') ?? false;
  
  appThemeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(SmartNotesApp(hasSeenWelcome: hasSeenWelcome));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Smart Image Provider (Handles Files, Web URLs, and Base64)
// ─────────────────────────────────────────────────────────────────────────────
ImageProvider? getAvatarProvider(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return null;

  // 1. Handle Local File Paths (from ImagePicker)
  if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
    final file = File(imagePath);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }
  // 2. Handle Network Images
  else if (imagePath.startsWith('http')) {
    return NetworkImage(imagePath);
  }
  // 3. Handle Base64 (Fallback for legacy data)
  else {
    try {
      final raw = imagePath.contains(',') ? imagePath.split(',').last : imagePath;
      return MemoryImage(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: safely decode a JSON list from SharedPreferences.
// ─────────────────────────────────────────────────────────────────────────────
List<T> _safeDecodeList<T>(
    String? json,
    T Function(Map<String, dynamic>) fromJson,
    ) {
  if (json == null || json.isEmpty) return [];
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((e) {
      try {
        return fromJson(e);
      } catch (_) {
        return null;
      }
    })
        .whereType<T>()
        .toList();
  } catch (_) {
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────
class SmartNotesApp extends StatelessWidget {
  final bool hasSeenWelcome; // ─── NEW FLAG ───

  const SmartNotesApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Smart Notes',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          // ─── ROUTING LOGIC ───
          home: hasSeenWelcome ? const AuthWrapper() : const WelcomeScreen(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthWrapper
// ─────────────────────────────────────────────────────────────────────────────
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  String? _userEmail;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('last_user_email');

    if (_userEmail != null) {
      final bioEnabled =
          prefs.getBool('biometric_enabled_$_userEmail') ?? false;
      if (bioEnabled) {
        await _authenticate();
        return;
      }
    }
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _authenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (canCheck && isSupported) {
        final ok = await _auth.authenticate(
          localizedReason: 'Please authenticate to access Smart Notes',
          options: const AuthenticationOptions(
              stickyAuth: true, biometricOnly: true),
        );
        if (ok && mounted) {
          setState(() => _isChecking = false);
          return;
        }
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
    }
    if (mounted) {
      setState(() {
        _userEmail = null;
        _isChecking = false;
      });
    }
  }

  void _onLoginSuccess(String email) {
    setState(() {
      _userEmail = email;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: context.themeBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accentBlue),
              const SizedBox(height: 24),
              Text(
                'Authenticating...',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_userEmail != null) return MainScreen(userEmail: _userEmail!);
    return LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav Items (mobile only)
// ─────────────────────────────────────────────────────────────────────────────
const List<_NavItem> _bottomNavItems = [
  _NavItem(tab: 'Home',          icon: Icons.grid_view_rounded,               label: 'Home'),
  _NavItem(tab: 'Notes',         icon: Icons.notes_rounded,                   label: 'Notes'),
  _NavItem(tab: 'Journal',       icon: Icons.auto_stories_rounded,            label: 'Journal'),
  _NavItem(tab: 'Expenses',      icon: Icons.account_balance_wallet_outlined, label: 'Expenses'),
  _NavItem(tab: 'Habit Tracker', icon: Icons.local_fire_department_outlined,  label: 'Habits'),
];

class _NavItem {
  final String tab;
  final IconData icon;
  final String label;
  const _NavItem({required this.tab, required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// MainScreen
// ─────────────────────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final String userEmail;
  const MainScreen({super.key, required this.userEmail});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _activeTab = 'Home';

  List<Task>        _tasks        = [];
  List<Note>        _notes        = [];
  List<JournalEntry> _journalEntries = [];
  List<StickyNote>  _stickyNotes  = [];
  List<Transaction> _transactions = [];
  List<Loan>        _loans        = [];
  List<Habit>       _habits       = [];

  String  _userName     = 'User';
  String? _profileImage;
  String  _phoneNumber  = '';
  String  _dob          = '';
  String  _gender       = 'Other';
  String  _jobTitle     = '';
  String  _address      = '';
  String  _bio          = '';
  bool    _isLoading    = true;

  // ── SharedPreferences keys ──
  String get _taskKey          => 'tasks_${widget.userEmail}';
  String get _noteKey          => 'notes_${widget.userEmail}';
  String get _journalKey       => 'journals_${widget.userEmail}';
  String get _stickyKey        => 'sticky_${widget.userEmail}';
  String get _expenseKey       => 'expenses_${widget.userEmail}';
  String get _loanKey          => 'loans_${widget.userEmail}';
  String get _habitKey         => 'habits_${widget.userEmail}';

  String get _profileNameKey   => 'name_${widget.userEmail}';
  String get _profileImageKey  => 'profile_image_${widget.userEmail}';
  String get _profilePhoneKey  => 'phone_${widget.userEmail}';
  String get _profileDobKey    => 'dob_${widget.userEmail}';
  String get _profileGenderKey => 'gender_${widget.userEmail}';
  String get _profileJobTitleKey => 'jobTitle_${widget.userEmail}';
  String get _profileAddressKey  => 'address_${widget.userEmail}';
  String get _profileBioKey      => 'bio_${widget.userEmail}';

  @override
  void initState() {
    super.initState();
    _saveLastUser();
    _loadData();
  }

  Future<void> _saveLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user_email', widget.userEmail);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _userName    = prefs.getString(_profileNameKey) ?? widget.userEmail.split('@')[0];
    _phoneNumber = prefs.getString(_profilePhoneKey) ?? '';
    _dob         = prefs.getString(_profileDobKey) ?? '';
    _gender      = prefs.getString(_profileGenderKey) ?? 'Other';
    _jobTitle    = prefs.getString(_profileJobTitleKey) ?? '';
    _address     = prefs.getString(_profileAddressKey) ?? '';
    _bio         = prefs.getString(_profileBioKey) ?? '';

    _profileImage = prefs.getString(_profileImageKey);

    _tasks        = _safeDecodeList(prefs.getString(_taskKey),    Task.fromJson);
    _notes        = _safeDecodeList(prefs.getString(_noteKey),    Note.fromJson);
    _journalEntries = _safeDecodeList(prefs.getString(_journalKey), JournalEntry.fromJson);
    _stickyNotes  = _safeDecodeList(prefs.getString(_stickyKey),  StickyNote.fromJson);
    _transactions = _safeDecodeList(prefs.getString(_expenseKey), Transaction.fromJson);
    _loans        = _safeDecodeList(prefs.getString(_loanKey),    Loan.fromJson);
    _habits       = _safeDecodeList(prefs.getString(_habitKey),   Habit.fromJson);

    // Schedule active habit reminders
    for (final h in _habits) {
      final numericId = int.tryParse(h.id) ?? h.id.hashCode;
      NotificationService().scheduleHabitReminders(
        baseId: numericId,
        habitName: h.name,
        timeOfDayStr: h.timeOfDay,
        durationMinutes: h.durationMinutes,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(String key, List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(
          key, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Save error [$key]: $e');
    }
  }

  void _saveTasks() => _save(_taskKey, _tasks);
  void _saveNotes() => _save(_noteKey, _notes);
  void _saveJournals() => _save(_journalKey, _journalEntries);
  void _saveStickyNotes() => _save(_stickyKey, _stickyNotes);
  void _saveExpenses() => _save(_expenseKey, _transactions);
  void _saveLoans() => _save(_loanKey, _loans);
  void _saveHabits() {
    _save(_habitKey, _habits);
    for (final h in _habits) {
      final numericId = int.tryParse(h.id) ?? h.id.hashCode;
      NotificationService().scheduleHabitReminders(
        baseId: numericId,
        habitName: h.name,
        timeOfDayStr: h.timeOfDay,
        durationMinutes: h.durationMinutes,
      );
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey,     _userName);
    await prefs.setString(_profilePhoneKey,    _phoneNumber);
    await prefs.setString(_profileDobKey,      _dob);
    await prefs.setString(_profileGenderKey,   _gender);
    await prefs.setString(_profileJobTitleKey, _jobTitle);
    await prefs.setString(_profileAddressKey,  _address);
    await prefs.setString(_profileBioKey,      _bio);

    if (_profileImage != null && _profileImage!.isNotEmpty) {
      await prefs.setString(_profileImageKey, _profileImage!);
    } else {
      await prefs.remove(_profileImageKey);
    }
  }

  void _updateActiveTab(String tab) => setState(() => _activeTab = tab);

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: TextStyle(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to sign out? All your notes, tasks, expenses, and habits are safely saved.',
            style: TextStyle(color: context.themeTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.themeTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Flush and ensure all user data is safely persisted
              _saveTasks();
              _saveNotes();
              _saveJournals();
              _saveStickyNotes();
              _saveExpenses();
              _saveLoans();
              _saveHabits();
              await _saveProfile();

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('last_user_email');

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(ImageProvider? avatarProvider) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _updateActiveTab('Profile'),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: avatarProvider == null ? AppColors.accentBlue.withValues(alpha: 0.2) : Colors.black12,
          backgroundImage: avatarProvider,
          child: avatarProvider == null
              ? Text(
            _userName.trim().isNotEmpty ? _userName.trim()[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.themeBackground,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue)),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 800;
    final ImageProvider? avatarProvider = getAvatarProvider(_profileImage);

    final sidebar = Sidebar(
      activeTab:    _activeTab,
      onTabChanged: _updateActiveTab,
      userEmail:    widget.userEmail,
      userName:     _userName,
      profileImage: _profileImage,
    );

    return PopScope(
      canPop: _activeTab == 'Home',
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        setState(() {
          _activeTab = 'Home';
        });
      },
      child: isMobile
          ? Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(_activeTab == 'Home' ? 'Smart Notes' : _activeTab,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          leading: _activeTab == 'Home' ? null : IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.themeTextPrimary),
            onPressed: () => setState(() => _activeTab = 'Home'),
          ),
          actions: [
            if (_activeTab != 'Profile') _buildProfileAvatar(avatarProvider),
          ],
        ),
        body: _buildContent(),
        bottomNavigationBar: _activeTab == 'Profile' ? null : _buildBottomNavBar(),
      )
          : Scaffold(
        backgroundColor: context.themeBackground,
        body: Row(children: [
          sidebar,
          Expanded(child: _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSidebarBackground.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ..._bottomNavItems.map((item) {
                final isActive = _activeTab == item.tab;
                final color = isActive ? const Color(0xFFF08A82) : context.themeTextSecondary;
                return GestureDetector(
                  onTap: () => _updateActiveTab(item.tab),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 24, color: color),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  _updateActiveTab('Tasks');
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF08A82),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case 'Home':
        return Dashboard(
          userName: _userName,
          notes: _notes,
          tasks: _tasks,
          habits: _habits,
          transactions: _transactions,
          onTabChange: _updateActiveTab,
        );
      case 'Notes':
        return NotesManager(
          notes: _notes,
          onNotesChanged: (n) {
            setState(() => _notes = n);
            _saveNotes();
          },
        );
      case 'Journal':
        return JournalView(
          entries: _journalEntries,
          onEntriesChanged: (e) {
            setState(() => _journalEntries = e);
            _saveJournals();
          },
        );
      case 'Tasks':
        return TaskManager(
          tasks: _tasks,
          onTasksChanged: (t) {
            setState(() => _tasks = t);
            _saveTasks();
          },
        );
      case 'Calendar':
        return CalendarView(
          tasks: _tasks,
          onAddTask: (title, priority, date) {
            final ds =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            setState(() => _tasks = [
              ..._tasks,
              Task(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                priority: priority,
                dueDate: ds,
              ),
            ]);
            _saveTasks();
          },
        );
      case 'Sticky Notes':
        return StickyNotesView(
          stickyNotes: _stickyNotes,
          onStickyNotesChanged: (s) {
            setState(() => _stickyNotes = s);
            _saveStickyNotes();
          },
        );
      case 'Expenses':
        return ExpenseManager(
          transactions: _transactions,
          onTransactionsChanged: (t) {
            setState(() => _transactions = t);
            _saveExpenses();
          },
          loans: _loans,
          onLoansChanged: (l) {
            setState(() => _loans = l);
            _saveLoans();
          },
        );
      case 'Habit Tracker':
        return HabitTrackerView(
          habits: _habits,
          onHabitsChanged: (h) {
            setState(() => _habits = h);
            _saveHabits();
          },
        );
      case 'Profile':
        return ProfileView(
          userName:     _userName,
          userEmail:    widget.userEmail,
          phoneNumber:  _phoneNumber,
          dob:          _dob,
          gender:       _gender,
          profileImage: _profileImage,
          jobTitle:     _jobTitle,
          address:      _address,
          bio:          _bio,
          onSignOut:    _handleSignOut,
          onSave: (name, phone, dob, gender, jobTitle, address, bio, img) {
            setState(() {
              _userName     = name;
              _phoneNumber  = phone;
              _dob          = dob;
              _gender       = gender;
              _jobTitle     = jobTitle;
              _address      = address;
              _bio          = bio;
              _profileImage = img;
              _activeTab    = 'Home';
            });
            _saveProfile();
          },
          onCancel: () => setState(() => _activeTab = 'Home'),
        );
      default:
        return Dashboard(
          userName: _userName,
          notes: _notes,
          tasks: _tasks,
          habits: _habits,
          transactions: _transactions,
          onTabChange: _updateActiveTab,
        );
    }
  }
}