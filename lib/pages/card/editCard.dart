import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/rekomendasiService.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class EditTaskPage extends StatefulWidget {
  final Card card;
  final Function(Card) onSaveUpdatedCard;

  const EditTaskPage({
    super.key,
    required this.card,
    required this.onSaveUpdatedCard,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller Form Utama
  late final TextEditingController _matkulController = TextEditingController(
    text: widget.card.courseName ?? '',
  );
  late final TextEditingController _titleController = TextEditingController(
    text: widget.card.title ?? '',
  );
  late final TextEditingController _descController = TextEditingController(
    text: widget.card.description ?? '',
  );

  late String _selectedPriority;
  late String _selectedDifficulty;

  // Controller untuk Tanggal & Waktu Deadline
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? _selectedDeadline;
  TimeOfDay? _selectedTime;

  // List Dinamis untuk Subtasks & URLs
  final List<TextEditingController> _subTaskControllers = [];
  final List<TextEditingController> _urlControllers = [];

  // Data Strategi & Unlocked Features
  List<dynamic> _strategies = [];
  List<String> _unlockedFeatures = [];
  String? _selectedStrategyId;
  bool _isLoadingStrategies = true;

  // Menyimpan subtask asli dari card untuk mempertahankan status penyelesaiannya (endTimeList)
  late List<CardList> _originalSubtasks;

  final List<dynamic> _friendsList = [];
  final List<String> _selectedCollaborators = [];
  bool _isLoadingFriends = false;

  @override
  void initState() {
    super.initState();
    _matkulController;
    _titleController;
    _descController;
    _selectedPriority = widget.card.priority ?? 'sedang';
    _selectedDifficulty = widget.card.difficulty ?? 'sedang';
    _selectedDeadline = widget.card.deadline ?? DateTime.now();
    _selectedStrategyId = widget.card.learningId;
    _originalSubtasks = List.from(widget.card.subtasks);
    _loadFriendsData();

    // Inisialisasi format tanggal & waktu dari deadline card yang ada
    if (widget.card.deadline != null) {
      _dateController.text =
          "${widget.card.deadline!.day} ${_getMonthName(widget.card.deadline!.month)} ${widget.card.deadline!.year}";
      _timeController.text =
          "${widget.card.deadline!.hour.toString().padLeft(2, '0')}:${widget.card.deadline!.minute.toString().padLeft(2, '0')}";
      _selectedTime = TimeOfDay(
        hour: widget.card.deadline!.hour,
        minute: widget.card.deadline!.minute,
      );
    }

    // --- PERBAIKAN DI SINI: Looping seluruh subtask agar controller terisi semua ---
    if (widget.card.subtasks.isNotEmpty) {
      for (var sub in widget.card.subtasks) {
        _subTaskControllers.add(
          TextEditingController(text: sub.subTitle ?? ''),
        );
      }
    } else {
      _subTaskControllers.add(TextEditingController());
    }

    // Masukkan URL yang sudah ada ke controller masing-masing
    if (widget.card.urlList.isNotEmpty) {
      for (var url in widget.card.urlList) {
        _urlControllers.add(TextEditingController(text: url));
      }
    } else {
      _urlControllers.add(TextEditingController());
    }

    _loadStrategyData();
  }

  void _addSubTaskField() {
    setState(() {
      _subTaskControllers.add(TextEditingController());
    });
  }

  void _addURLField() {
    setState(() {
      _urlControllers.add(TextEditingController());
    });
  }

  Future<void> _loadStrategyData() async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        setState(() => _isLoadingStrategies = false);
        return;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['userId'] ?? decodedToken['id'];

      final results = await Future.wait([
        CardService.getAllStrategies(),
        rekomendasiService.getUnlockedFeatures(userId, token),
      ]);

      setState(() {
        _strategies = results[0];
        _unlockedFeatures = results[1] as List<String>;
        _isLoadingStrategies = false;
      });
    } catch (e) {
      debugPrint('Error loading strategy data: $e');
      setState(() {
        _isLoadingStrategies = false;
      });
    }
  }

  Future<void> _loadFriendsData() async {
    setState(() => _isLoadingFriends = true);
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      // Ambil daftar teman (bisa disesuaikan dengan service API pertemanan yang ada di projekmu)
      // Contoh: final friends = await CardService.getFriends(token);
      // Untuk sementara kita inisialisasi list kosong atau dari card jika ada
      setState(() {
        // _friendsList = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
      setState(() => _isLoadingFriends = false);
    }
  }

  void _showAddCollaboratorDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cari & Tambah Teman Kolaborasi',
            style: TextStyle(fontSize: 16),
          ),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Masukkan username atau email...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
              ),
              onPressed: () async {
                final query = searchController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.pop(context);
                  // Panggil API untuk mencari/menambahkan kolaborator ke tugas ini
                  try {
                    final token = await SecureTokenStorage.getToken();
                    if (token != null && widget.card.cardId != null) {
                      // Contoh pemanggilan API addCollaborator
                      // await CardService().addCollaborator(token, widget.card.cardId!, {'friendUsername': query, 'role': 'member'});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berhasil menambahkan kolaborator!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadFriendsData(); // Refresh list
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menambahkan teman: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Tambah',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  bool get _isHelpSeekingStrategy {
    if (_selectedStrategyId == null) return false;
    final selected = _strategies.firstWhere(
      (s) => s['learningId'] == _selectedStrategyId,
      orElse: () => null,
    );
    if (selected == null) return false;
    final keyCode = (selected['keyCode'] ?? '').toString().toLowerCase();
    final name = (selected['learningStrategy'] ?? '').toString().toLowerCase();
    return keyCode.contains('help') || name.contains('help');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline != null && _selectedDeadline!.isAfter(today)
          ? _selectedDeadline!
          : today,
      firstDate: today, // Mencegah deadline dimundurkan dari hari ini
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _dateController.text =
            "${picked.day} ${_getMonthName(picked.month)} ${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _matkulController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    for (var c in _subTaskControllers) {
      c.dispose();
    }
    for (var c in _urlControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTaskStarted = widget.card.startTime != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Tugas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTaskStarted)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Catatan: Task sudah dimulai. Mata kuliah, nama tugas, strategi, prioritas, dan deskripsi dikunci.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                  ),
                ),

              // --- MATA KULIAH ---
              const Text(
                'Mata Kuliah *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _matkulController,
                enabled: !isTaskStarted,
                decoration: InputDecoration(
                  hintText: 'Ketik mata kuliah...',
                  prefixIcon: const Icon(Icons.book_outlined),
                  filled: true,
                  fillColor: isTaskStarted
                      ? const Color(0xFFF8FAFC)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Mata kuliah wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- NAMA TUGAS ---
              const Text(
                'Nama Tugas *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                enabled: !isTaskStarted,
                decoration: InputDecoration(
                  hintText: 'Apa yang mau dikerjakan?',
                  prefixIcon: const Icon(Icons.task_alt),
                  filled: true,
                  fillColor: isTaskStarted
                      ? const Color(0xFFF8FAFC)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Nama tugas wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- DESKRIPSI ---
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                enabled: !isTaskStarted,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Deskripsi tambahan (opsional)...',
                  filled: true,
                  fillColor: isTaskStarted
                      ? const Color(0xFFF8FAFC)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- STRATEGI BELAJAR ---
              const Text(
                'Strategi Belajar *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _isLoadingStrategies
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _strategies.map((strategy) {
                        final String label = strategy['learningStrategy'];
                        final String keyCode = strategy['keyCode'];
                        final String learningId = strategy['learningId'];

                        bool isUnlocked = _unlockedFeatures.contains(keyCode);
                        bool isSelected = _selectedStrategyId == learningId;

                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label),
                              if (!isUnlocked) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.lock,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFEEF2FF),
                          backgroundColor: isUnlocked
                              ? Colors.white
                              : Colors.grey[200],
                          labelStyle: TextStyle(
                            color: !isUnlocked
                                ? Colors.grey
                                : (isSelected
                                      ? const Color(0xFF4F46E5)
                                      : Colors.black),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (isTaskStarted || !isUnlocked)
                              ? null
                              : (selected) {
                                  setState(() {
                                    _selectedStrategyId = selected
                                        ? learningId
                                        : null;
                                  });
                                },
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),

              // --- PRIORITAS ---
              const Text(
                'Prioritas *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityButton('Rendah', 'low', isTaskStarted),
                  const SizedBox(width: 8),
                  _buildPriorityButton('Sedang', 'medium', isTaskStarted),
                  const SizedBox(width: 8),
                  _buildPriorityButton('Tinggi', 'high', isTaskStarted),
                  const SizedBox(width: 8),
                  _buildPriorityButton('Kritis', 'critical', isTaskStarted),
                ],
              ),
              const SizedBox(height: 24),
              // --- TINGKAT KESULITAN (DIFFICULTY) ---
              const Text(
                'Tingkat Kesulitan *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDifficultyButton('Mudah', 'easy', isTaskStarted),
                  const SizedBox(width: 8),
                  _buildDifficultyButton('Sedang', 'medium', isTaskStarted),
                  const SizedBox(width: 8),
                  _buildDifficultyButton('Sulit', 'hard', isTaskStarted),
                  const SizedBox(width: 8),
                  _buildDifficultyButton('Expert', 'expert', isTaskStarted),
                ],
              ),
              const SizedBox(height: 24),
              // --- SUBTASKS ---
              const Text(
                'SUBTASKS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ..._subTaskControllers.asMap().entries.map((entry) {
                int index = entry.key;
                // Cek apakah subtask ini sudah selesai di data asli card (berdasarkan index atau kecocokan teks)
                bool isSubtaskDone = false;
                if (index < _originalSubtasks.length) {
                  isSubtaskDone = _originalSubtasks[index].endTimeList != null;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          enabled: !isSubtaskDone, // Kunci jika subtask sudah selesai
                          decoration: InputDecoration(
                            hintText: 'Subtaks ${index + 1}',
                            filled: true,
                            fillColor: isSubtaskDone
                                ? const Color(0xFFF8FAFC)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            decoration: isSubtaskDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isSubtaskDone ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isSubtaskDone
                              ? Colors.grey.shade300
                              : Colors.grey,
                        ),
                        // Jika subtask sudah selesai, tombol hapus didisable
                        onPressed: isSubtaskDone
                            ? null
                            : () {
                                setState(() {
                                  _subTaskControllers.removeAt(index);
                                });
                              },
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addSubTaskField,
                icon: const Icon(Icons.add, color: Color(0xFF4F46E5)),
                label: const Text(
                  'Tambah Subtaks',
                  style: TextStyle(color: Color(0xFF4F46E5)),
                ),
              ),
              const SizedBox(height: 16),

              // --- URL / REFERENCES ---
              const Text(
                'URL / REFERENCES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ..._urlControllers.asMap().entries.map((entry) {
                int index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          enabled: !isTaskStarted,
                          decoration: InputDecoration(
                            hintText: 'URL ${index + 1}',
                            filled: true,
                            fillColor: isTaskStarted
                                ? const Color(0xFFF8FAFC)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (!isTaskStarted)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _urlControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
              if (!isTaskStarted)
                TextButton.icon(
                  onPressed: _addURLField,
                  icon: const Icon(Icons.add, color: Color(0xFF4F46E5)),
                  label: const Text(
                    'Tambah URL',
                    style: TextStyle(color: Color(0xFF4F46E5)),
                  ),
                ),
              const SizedBox(height: 16),

              // --- DEADLINE ---
              Row(
                children: const [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF0D9488),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Deadline',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        hintText: 'Pilih Tanggal',
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () => _selectTime(context),
                      decoration: InputDecoration(
                        hintText: '23:59',
                        suffixIcon: const Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- KOLABORASI (Hanya muncul jika strategi Help-Seeking dipilih) ---
              if (_isHelpSeekingStrategy) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kolaborasi Teman',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddCollaboratorDialog,
                      icon: const Icon(
                        Icons.person_add,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                      label: const Text(
                        'Cari & Tambah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _isLoadingFriends
                    ? const Center(child: CircularProgressIndicator())
                    : _friendsList.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Belum ada teman kolaborasi di tugas ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: _showAddCollaboratorDialog,
                              child: const Text(
                                'Tambah Sekarang',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Wrap(
                        spacing: 8.0,
                        children: _friendsList.map((friend) {
                          final friendId = friend['userId'] ?? friend['id'];
                          final friendName = friend['username'] ?? 'Teman';
                          bool isSelected = _selectedCollaborators.contains(
                            friendId,
                          );

                          return FilterChip(
                            label: Text(friendName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCollaborators.add(friendId);
                                } else {
                                  _selectedCollaborators.remove(friendId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, String value, bool isTaskStarted) {
    bool isSelected = _selectedPriority == value;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFEEF2FF)
              : (isTaskStarted ? const Color(0xFFF8FAFC) : Colors.white),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isTaskStarted
            ? null
            : () => setState(() => _selectedPriority = value),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : (isTaskStarted ? Colors.grey : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    String label,
    String value,
    bool isTaskStarted,
  ) {
    bool isSelected = _selectedDifficulty == value;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFFEF3C7) // Warna kuning lembut untuk kesulitan
              : (isTaskStarted ? const Color(0xFFF8FAFC) : Colors.white),
          side: BorderSide(
            color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isTaskStarted
            ? null
            : () => setState(() => _selectedDifficulty = value),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFD97706)
                : (isTaskStarted ? Colors.grey : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStrategyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih strategi belajar terlebih dahulu!'),
          ),
        );
        return;
      }

      if (_selectedDeadline != null) {
        _selectedDeadline = DateTime(
          _selectedDeadline!.year,
          _selectedDeadline!.month,
          _selectedDeadline!.day,
          _selectedTime?.hour ?? 23,
          _selectedTime?.minute ?? 59,
        );
      }

      // 1. Kumpulkan URL
      List<String> urlList = _urlControllers
          .map((c) => c.text.trim())
          .where((u) => u.isNotEmpty)
          .toList();
      String combinedUrls = urlList.join(', ');

      // 2. Kumpulkan list subtask dengan mempertahankan ID dan timestamp aslinya agar tidak ter-reset
      List<Map<String, dynamic>> subtasksPayload = [];
      List<CardList> updatedSubtasksList = [];

      for (int i = 0; i < _subTaskControllers.length; i++) {
        String title = _subTaskControllers[i].text.trim();
        if (title.isEmpty) continue;

        if (i < _originalSubtasks.length) {
          final existingSub = _originalSubtasks[i];
          existingSub.subTitle = title; // Update nama subtask yang diubah
          
          subtasksPayload.add({
            'clId': existingSub.clId,
            'subTitle': title,
            'startTimeList': existingSub.startTimeList?.toIso8601String(),
            'endTimeList': existingSub.endTimeList?.toIso8601String(),
          });
          updatedSubtasksList.add(existingSub);
        } else {
          // Jika ini subtask baru yang ditambahkan saat edit
          subtasksPayload.add({
            'subTitle': title,
            'startTimeList': null,
            'endTimeList': null,
          });
          updatedSubtasksList.add(
            CardList(cardId: widget.card.cardId, subTitle: title),
          );
        }
      }

      final String? finalStartTime = widget.card.startTime?.toIso8601String();

      final updatedDataJson = {
        'nmMatkul': _matkulController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'learningId': _selectedStrategyId,
        'priority': _selectedPriority,
        'difficulty': _selectedDifficulty,
        'deadline': _selectedDeadline?.toIso8601String(),
        'startTime': finalStartTime,
        'subtasks': subtasksPayload, // Kirim payload lengkap beserta status waktunya
        'URL': combinedUrls,
      };

      try {
        final token = await SecureTokenStorage.getToken();
        if (token != null && widget.card.cardId != null) {
          final cardService = CardService();

          bool cardSuccess = await cardService.updateCard(
            token,
            widget.card.cardId!,
            updatedDataJson,
          );

          if (!cardSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menyimpan perubahan kartu utama!'),
              ),
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('Error submit update: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat menyimpan: $e')),
        );
        return;
      }

      // Update state lokal kartu
      widget.card.subtasks = updatedSubtasksList;
      widget.card.courseName = _matkulController.text.trim();
      widget.card.title = _titleController.text.trim();
      widget.card.description = _descController.text.trim();
      widget.card.learningId = _selectedStrategyId;
      widget.card.priority = _selectedPriority;
      widget.card.difficulty = _selectedDifficulty;
      widget.card.deadline = _selectedDeadline;
      widget.card.url = combinedUrls;

      widget.onSaveUpdatedCard(widget.card);
      Navigator.pop(context);
    }
  }
}
