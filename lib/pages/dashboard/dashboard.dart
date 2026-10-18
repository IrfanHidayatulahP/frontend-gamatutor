import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/user.dart';
import 'package:gamatutor_kanban/pages/Auth/authwrapper.dart';
import 'package:gamatutor_kanban/pages/card/board.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/localtokenService.dart';
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/columnmovement.dart';
import 'package:gamatutor_kanban/service/loginService.dart';

class Dashboard extends StatefulWidget {
  final User? user;
  const Dashboard({super.key, this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  final bool _isSpeedDialOpen = false;

  // List data Card utama
  List<Card> _cardsList = [];

  // Helper method untuk mendapatkan sapaan waktu otomatis
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 3 && hour < 11) {
      return 'Selamat Pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUser =
        widget.user ??
        User(
          userId: 'usr_default',
          email: 'kim.maru@example.com',
          firstName: 'Kim',
          lastName: 'Maru',
          username: 'kimmaru',
          role: 'user',
          status: 'online',
          archived: false,
          createdAt: DateTime.now(),
          token: 'sample_token',
        );

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final token = await LocalTokenStorage.getToken();

    if (token != null) {
      try {
        final apiCards = await CardService().getCardsByUser(token);
        if (apiCards.isNotEmpty && mounted) {
          setState(() {
            _cardsList = apiCards;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Koneksi ke database gagal: $e');
      }
    }

    final now = DateTime.now();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _uncompletedTaskCount {
    return _cardsList.where((card) {
      final col = (card.computedColumn ?? 'planning').toLowerCase();
      return col != 'reflection' && col != 'done' && col != 'completed';
    }).length;
  }

  int get _completedTaskCount {
    return _cardsList.where((card) {
      final col = (card.computedColumn ?? 'planning').toLowerCase();
      return col == 'reflection' || col == 'done' || col == 'completed';
    }).length;
  }

  String get _formattedFocusDuration {
    double totalMinutes = 0;

    for (var card in _cardsList) {
      // Prioritas 1: Hitung selisih langsung dari startTime ke endTime pada kartu utama
      if (card.startTime != null && card.endTime != null) {
        final diff = card.endTime!.difference(card.startTime!);
        if (diff.inMinutes > 0) {
          totalMinutes += diff.inMinutes;
        }
      } 
      // Prioritas 2 (Fallback): Jika card utama belum ada endTime, akumulasikan dari subtask yang punya rentang waktu
      else if (card.subtasks.isNotEmpty) {
        for (var sub in card.subtasks) {
          if (sub.startTimeList != null && sub.endTimeList != null) {
            final subDiff = sub.endTimeList!.difference(sub.startTimeList!);
            if (subDiff.inMinutes > 0) {
              totalMinutes += subDiff.inMinutes;
            }
          }
        }
      }
    }

    if (totalMinutes <= 0) return '0j';

    // Jika total menit kurang dari 60, tampilkan dalam bentuk menit (misal: "21 mnt" atau desimal jam)
    if (totalMinutes < 60) {
      return '${totalMinutes.toInt()} mnt';
    }

    final double totalHours = totalMinutes / 60.0;
    if (totalHours % 1 == 0) {
      return '${totalHours.toInt()}j';
    }
    return '${totalHours.toStringAsFixed(1)}j';
  }

  // 3. TUGAS HARI INI: Card yang dijadwalkan pada hari ini
  List<Card> get _todaysTasks {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    return _cardsList.where((card) {
      // Ambil tanggal dari deadline atau startTime, abaikan jamnya
      DateTime? targetDate = card.deadline ?? card.startTime;
      if (targetDate == null) return false;

      final targetOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

      // Jika ingin mencocokkan persis hari ini:
      return targetOnly.isAtSameMomentAs(todayOnly);
      
      // ATAU jika ingin menampilkan SEMUA kartu aktif (agar langsung nampak saat diuji):
      // return true; 
    }).toList();
  }

  List<Card> _getCardsByColumnCategory(String category) {
    return _cardsList.where((card) {
      final col = card.computedColumn ?? 'planning';
      return col == category;
    }).toList();
  }

  Future<void> _handleLogout() async {
    await LoginService().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildQuoteCard(),
          const SizedBox(height: 16),
          _buildQuestBanner(),
          const SizedBox(height: 16),
          _buildCharacterAndStatsCard(),
          const SizedBox(height: 16),
          _buildAchievementCard(),
          const SizedBox(height: 16),
          _buildLearningPatternCard(),
          const SizedBox(height: 16),
          _buildPersonalBestCard(),
          const SizedBox(height: 20),
          _buildTaskHeader(),
          const SizedBox(height: 12),
          _buildTodaysTaskList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_selectedIndex) {
      case 0:
        currentBody = _buildHomeView();
        break;
      case 1:
        currentBody = KanbanBoardView();
        break;
      case 2:
        currentBody = _buildPlaceholderView('Goals Screen');
        break;
      case 3:
        currentBody = _buildPlaceholderView('Progress Screen');
        break;
      case 4:
        currentBody = _buildPlaceholderView('Account Screen');
        break;
      default:
        currentBody = _buildHomeView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: Stack(children: [currentBody])),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    final displayName = _currentUser?.fullName ?? 'ax!';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$displayName!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildQuoteCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '“ ',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        Expanded(
          child: Text(
            'Belajar itu proses, bukan lomba. Mulai dari yang paling ringan.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF64748B).withValues(alpha: 0.9),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Quest Segera Hadir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Petualangan baru sedang disiapkan — nantikan!',
                  style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterAndStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                _buildStatItem(
                  Icons.local_fire_department_outlined,
                  '0',
                  'Streak',
                  Colors.orange,
                ),
                _buildVerticalDivider(),
                // Dihitung dinamis dari durasi pergerakan 'todo' -> 'reflection'
                _buildStatItem(
                  Icons.timer_outlined,
                  _formattedFocusDuration,
                  'Fokus',
                  Colors.blue,
                ),
                _buildVerticalDivider(),
                _buildStatItem(
                  Icons.close_rounded,
                  '$_uncompletedTaskCount',
                  'Belum Selesai',
                  Colors.red,
                ),
                _buildVerticalDivider(),
                // 2. Statistik Tugas Selesai (Ikon Checklist Hijau)
                _buildStatItem(
                  Icons.check_circle_rounded,
                  '$_completedTaskCount',
                  'Selesai',
                  Colors.green,
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFF6FF)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Mulai Belajar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 80,
                          height: 120,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/People/Man%20Student.png',
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          width: 90,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.elliptical(90, 12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 24, width: 1, color: const Color(0xFFE2E8F0));
  }

  Widget _buildAchievementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '0 Pencapaian Tercapai',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          value: 0.0,
                          backgroundColor: Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF59E0B),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '0/0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPatternCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pola Belajarmu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Berdasarkan 30 hari terakhir',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: const [
                Text(
                  'Belum cukup data untuk menampilkan pola belajar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Minimal 7 sesi belajar dalam 30 hari terakhir',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Personal Best',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '3 sesi terlama kamu',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selesaikan minimal 1 sesi untuk lihat personal best',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Tugas Hari Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_todaysTasks.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysTaskList() {
    final tasks = _todaysTasks;

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Tidak ada tugas yang dijadwalkan untuk hari ini.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    // 1. Pisahkan tugas menjadi 2 kategori
    final uncompletedTasks = tasks.where((card) {
      final col = (card.computedColumn ?? 'planning').toLowerCase();
      return col != 'reflection';
    }).toList();

    final completedTasks = tasks.where((card) {
      final col = (card.computedColumn ?? 'planning').toLowerCase();
      return col == 'reflection';
    }).toList();

    // 2. Tampilkan keduanya secara bersamaan dalam Column
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- KATEGORI 1: BELUM SELESAI ---
        if (uncompletedTasks.isNotEmpty) ...[
          const Text(
            'Belum Selesai',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          ...uncompletedTasks.map((card) => _buildTaskCardItem(card, isDone: false)),
          const SizedBox(height: 16),
        ],

        // --- KATEGORI 2: SELESAI (REFLECTION) ---
        if (completedTasks.isNotEmpty) ...[
          const Text(
            'Selesai (Reflection)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 8),
          ...completedTasks.map((card) => _buildTaskCardItem(card, isDone: true)),
        ],

        // Jika kedua list kosong (seharusnya tertangani oleh tasks.isEmpty di atas, tapi untuk berjaga-jaga)
        if (uncompletedTasks.isEmpty && completedTasks.isEmpty)
          const Center(
            child: Text(
              'Tidak ada tugas hari ini.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCardItem(Card card, {required bool isDone}) {
    final col = (card.computedColumn ?? 'planning').toLowerCase();
    final subtaskTitle = card.subtasks.isNotEmpty ? card.subtasks.first.subTitle : null;

    Color badgeBg = const Color(0xFFF1F5F9);
    Color badgeText = const Color(0xFF475569);
    String badgeLabel = 'Planning';

    switch (col) {
      case 'reflection':
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF166534);
        badgeLabel = 'Reflection';
        break;
      case 'controlling':
        badgeBg = const Color(0xFFE0E7FF);
        badgeText = const Color(0xFF3730A3);
        badgeLabel = 'Controlling';
        break;
      case 'monitoring':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFF92400E);
        badgeLabel = 'Monitoring';
        break;
      case 'planning':
      default:
        badgeBg = const Color(0xFFF1F5F9);
        badgeText = const Color(0xFF475569);
        badgeLabel = 'Planning';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Berdasarkan Status: Checklist hijau jika selesai, Icon Close / Lingkaran jika belum
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.close_rounded,
            color: isDone ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (card.title != null && card.title!.isNotEmpty
                          ? card.title
                          : subtaskTitle) ??
                      'Tanpa Judul',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (card.description != null && card.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    card.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_kanban_outlined),
            activeIcon: Icon(Icons.view_kanban_rounded),
            label: 'Board',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes_rounded),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
