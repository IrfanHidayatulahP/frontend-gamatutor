import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/user.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/localtokenService.dart';
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/model/columnmovement.dart';

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
    _currentUser = widget.user ??
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

    // 1. Ambil Token dari Local Storage
    final token = await LocalTokenStorage.getToken();
    
    if (token != null) {
      try {
        // 2. Minta data Card aktual dari Database via REST API
        final apiCards = await CardService().getCardsByUser(token);
        if (apiCards.isNotEmpty && mounted) {
          setState(() {
            _cardsList = apiCards;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Koneksi ke database gagal, menggunakan fallback data: $e');
      }
    }

    final now = DateTime.now();

    // 3. Fallback Mock Data (jika server/database belum aktif)
    _cardsList = [
      Card(
        cardId: 'card_101',
        userId: _currentUser?.userId ?? 'usr_default',
        title: 'Review Modul Matematika Dasar',
        cardList: CardList(
          cardId: 'card_101',
          courseName: 'Matematika Dasar',
          subTitle: 'Review Modul Matematika Dasar',
          description: 'Mempelajari bab aljabar linier dan latihan soal.',
          learningId : null,
          difficulty: 'hard',
          priority: 'high',
          startTime: now,
        ),
        columnMovements: [
          ColumnMovement(
            ccmId: 'ccm_101_1',
            cardId: 'card_101',
            fromColumn: 'backlog',
            toColumn: 'todo',
            timestamp: now.subtract(const Duration(hours: 5)),
            completed: true,
          ),
        ],
      ),
      Card(
        cardId: 'card_102',
        userId: _currentUser?.userId ?? 'usr_default',
        title: 'Kuis Pemrograman Dart',
        cardList: CardList(
          cardId: 'card_102',
          courseName: 'Pemrograman Dart',
          subTitle: 'Kuis Pemrograman Dart',
          description: 'Kerjakan kuis async await & futures.',
          learningId : null,
          difficulty: 'medium',
          priority: 'medium',
          startTime: now,
        ),
        columnMovements: [
          ColumnMovement(
            ccmId: 'ccm_102_1',
            cardId: 'card_102',
            fromColumn: 'todo',
            toColumn: 'in_progress',
            timestamp: now.subtract(const Duration(hours: 2)),
            completed: true,
          ),
        ],
      ),
      Card(
        cardId: 'card_103',
        userId: _currentUser?.userId ?? 'usr_default',
        title: 'Penyusunan Laporan Proyek UI/UX',
        cardList: CardList(
          cardId: 'card_103',
          courseName: 'UI/UX Design',
          subTitle: 'Penyusunan Laporan Proyek UI/UX',
          description: 'Rangkum hasil usability testing.',
          learningId : null,
          difficulty: 'expert',
          priority: 'critical',
          startTime: now,
        ),
        columnMovements: [
          ColumnMovement(
            ccmId: 'ccm_103_1',
            cardId: 'card_103',
            fromColumn: 'todo',
            toColumn: 'in_progress',
            timestamp: now.subtract(const Duration(hours: 4)),
            completed: true,
          ),
          ColumnMovement(
            ccmId: 'ccm_103_2',
            cardId: 'card_103',
            fromColumn: 'in_progress',
            toColumn: 'reflection',
            timestamp: now.subtract(const Duration(hours: 1)),
            completed: true,
          ),
        ],
      ),
      Card(
        cardId: 'card_104',
        userId: _currentUser?.userId ?? 'usr_default',
        title: 'Latihan Soal Fisika',
        cardList: CardList(
          cardId: 'card_104',
          courseName: 'Fisika Dasar',
          subTitle: 'Latihan Soal Fisika',
          description: 'Hukum Newton dan Aplikasinya.',
          learningId : null,
          difficulty: 'medium',
          priority: 'low',
          startTime: now,
        ),
        columnMovements: [],
      ),
    ];

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _uncompletedTaskCount {
  return _cardsList.where((card) {
    final movements = card.columnMovements;
    final lastMovement = (movements != null && movements.isNotEmpty) 
        ? movements.last 
        : null;
        
    final col = (lastMovement?.toColumn ?? '').toLowerCase();
    
    // Kembalikan kondisi filter Anda di sini, contoh:
    return col != 'done' && col != 'completed';
  }).length;
}
String get _formattedFocusDuration {
    double totalMinutes = 0;

    for (var card in _cardsList) {
      final movements = card.columnMovements ?? [];
      if (movements.isEmpty) continue;

      // Urutkan pergerakan berdasarkan timestamp
      final sortedLogs = List<ColumnMovement>.from(movements)
        ..sort((a, b) => (a.timestamp ?? DateTime.now())
            .compareTo(b.timestamp ?? DateTime.now()));

      // Cari log saat pertama dari/ke 'todo'
      final todoLog = sortedLogs.cast<ColumnMovement?>().firstWhere(
            (l) => l?.fromColumn?.toLowerCase() == 'todo' || l?.toColumn?.toLowerCase() == 'todo',
            orElse: () => null,
          );

      // Cari log saat mencapai 'reflection'
      final reflectionLog = sortedLogs.cast<ColumnMovement?>().firstWhere(
            (l) => l?.toColumn?.toLowerCase() == 'reflection',
            orElse: () => null,
          );

      if (todoLog?.timestamp != null && reflectionLog?.timestamp != null) {
        final diff = reflectionLog!.timestamp!.difference(todoLog!.timestamp!);
        if (diff.inMinutes > 0) {
          totalMinutes += diff.inMinutes;
        }
      }
    }

    final double totalHours = totalMinutes / 60.0;
    if (totalHours == 0) return '0j';
    if (totalHours % 1 == 0) return '${totalHours.toInt()}j';
    return '${totalHours.toStringAsFixed(1)}j';
  }

  // 3. TUGAS HARI INI: Card yang dijadwalkan pada hari ini
  List<Card> get _todaysTasks {
    final now = DateTime.now();
    return _cardsList.where((card) {
      final scheduled = card.cardList?.startTime;
      if (scheduled == null) return false;
      return scheduled.year == now.year &&
          scheduled.month == now.month &&
          scheduled.day == now.day;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section (Sapaan + Nama Pengguna Dinamis)
              _buildHeader(),
              const SizedBox(height: 16),

              // 2. Quote Card
              _buildQuoteCard(),
              const SizedBox(height: 16),

              // 3. Quest Banner
              _buildQuestBanner(),
              const SizedBox(height: 16),

              // 4. Main Character & Stats Card
              _buildCharacterAndStatsCard(),
              const SizedBox(height: 16),

              // 5. Achievement Card
              _buildAchievementCard(),
              const SizedBox(height: 16),

              // 6. Learning Pattern Card
              _buildLearningPatternCard(),
              const SizedBox(height: 16),

              // 7. Personal Best Card
              _buildPersonalBestCard(),
              const SizedBox(height: 20),

              // 8. Bottom Section Title
              _buildTaskHeader(),
              const SizedBox(height: 20),
              
              // 9. List of Tasks for Today
              _buildTodaysTaskList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
            const SizedBox(width: 8)
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
                  ),
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
          )
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
                // Dihitung dinamis dari cardlist yang belum masuk 'reflection'
                _buildStatItem(
                  Icons.check_circle_outline_rounded,
                  '$_uncompletedTaskCount',
                  'Tugas',
                  Colors.green,
                ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2563EB)),
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
                            borderRadius: const BorderRadius.all(Radius.elliptical(90, 12)),
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

  Widget _buildStatItem(IconData icon, String value, String label, Color iconColor) {
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
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Lihat Statistik Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF334155)),
                ],
              ),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
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
        GestureDetector(
          onTap: () {},
          child: Row(
            children: const [
              Text(
                'Lihat Board',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
            ],
          ),
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
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    return Column(
      children: tasks.map((card) {
        final cm = card.columnMovements?.isNotEmpty == true ? card.columnMovements!.last : null;
        final isReflection = cm?.toColumn?.toLowerCase() == 'reflection';
        final isInProgress = cm?.toColumn?.toLowerCase() == 'in_progress';

        final cardList = card.cardList;

        Color badgeBg = const Color(0xFFF1F5F9);
        Color badgeText = const Color(0xFF475569);
        String badgeLabel = 'To Do';

        if (isReflection) {
          badgeBg = const Color(0xFFDCFCE7);
          badgeText = const Color(0xFF166534);
          badgeLabel = 'Reflection';
        } else if (isInProgress) {
          badgeBg = const Color(0xFFFEF3C7);
          badgeText = const Color(0xFF92400E);
          badgeLabel = 'In Progress';
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
              Icon(
                isReflection
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isReflection ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title ?? cardList?.subTitle?? 'Tanpa Judul',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        decoration: isReflection ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (cardList?.description != null &&
                        cardList!.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        cardList.description!,
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
      }).toList(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
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
