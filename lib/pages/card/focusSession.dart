import 'dart:async';

import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/pages/card/editCard.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/localtokenService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class FocusSessionPage extends StatefulWidget {
  final Card card;
  final Function(Card, CardList) onStartSubtask;
  final Function(Card, CardList) onStopSubtask;
  final VoidCallback onNavigateToReflection;

  const FocusSessionPage({
    super.key,
    required this.card,
    required this.onStartSubtask,
    required this.onStopSubtask,
    required this.onNavigateToReflection,
  });

  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class AppBlockerService {
  static const platform = MethodChannel('gamatutor.app/blocker');

  static Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await platform.invokeMethod(
        'checkUsagePermission',
      );
      return hasPermission;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
    } catch (e) {
      debugPrint("Error requesting permission: $e");
    }
  }
}

class _FocusSessionPageState extends State<FocusSessionPage> {
  final CardService _cardService = CardService();
  String? _strategyName;
  bool _isLoadingStrategy = true;

  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isPaused = false;

  late final TextEditingController _quickNotesController = TextEditingController(
    text: widget.card.notes ?? '',
  );

  @override
  void initState() {
    super.initState();
    _loadLearningStrategy();
    _startFocusTimer();
  }

  void _startFocusTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _quickNotesController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadLearningStrategy() async {
    if (widget.card.learningId == null || widget.card.learningId!.isEmpty) {
      setState(() {
        _strategyName = 'Video Tutorial';
        _isLoadingStrategy = false;
      });
      return;
    }

    try {
      final token = await LocalTokenStorage.getToken();
      if (token != null) {
        final strategy = await CardService.getStrategyById(
          token,
          widget.card.learningId!,
        );
        setState(() {
          _strategyName = strategy?.learningStrategy ?? 'Video Tutorial';
          _isLoadingStrategy = false;
        });
      }
    } catch (e) {
      setState(() {
        _strategyName = 'Video Tutorial';
        _isLoadingStrategy = false;
      });
    }
  }

  Future<void> launchSpotifyPlaylist() async {
    final Uri spotifyAppUri = Uri.parse('spotify://playlist/37i9dQZF1DX8Uebhn9wzrS');
    final Uri spotifyWebUri = Uri.parse('https://open.spotify.com/playlist/37i9dQZF1DX8Uebhn9wzrS');

    try {
      if (await canLaunchUrl(spotifyAppUri)) {
        await launchUrl(spotifyAppUri);
      } else {
        await launchUrl(spotifyWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Spotify: $e');
    }
  }

  String _getPersonalBest() {
    if (widget.card.startTime != null && widget.card.endTime != null) {
      final diff = widget.card.endTime!.difference(widget.card.startTime!);
      if (diff.inMinutes > 0) {
        return '${diff.inMinutes} MNT';
      }
    }
    return '2J 15M';
  }

  // --- FUNGSI UTAMA MENYIMPAN CATATAN & MENGAKHIRI SESI ---
  Future<void> _saveNotesAndEndSession() async {
    final token = await LocalTokenStorage.getToken();
    if (token != null) {
      final String quickNotesText = _quickNotesController.text.trim();
      if (quickNotesText.isNotEmpty) {
        try {
          // Kirim update ke backend untuk memasukkan catatan ke kolom 'notes' di tabel card
          await _cardService.updateCard(token, widget.card.cardId!, {
            'notes': quickNotesText,
          });
          widget.card.notes = quickNotesText; // Perbarui state lokal kartu
        } catch (e) {
          debugPrint('Gagal menyimpan catatan Quick Notes ke database: $e');
        }
      }
    }
  }

  // --- POP-UP KONFIRMASI SEBELUM MENYELESAIKAN 1 SUBTASK ---
  void _handleStopSingleSubtask(CardList subtask) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Tuntasin subtask ini?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Mau tandai "${subtask.subTitle ?? ''}" sebagai selesai dan balik sebentar ke detail tugas?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Belum, lanjut dlu', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // Tutup dialog menggunakan dialogContext
              _timer.cancel(); 
              
              await _saveNotesAndEndSession();
              await widget.onStopSubtask(widget.card, subtask); 

              // 👇 Pengecekan mounted yang aman sebelum menggunakan context utama
              if (!mounted) return;
              Navigator.pop(context, true); 
            },
            child: const Text('Gas, Selesai!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- AKHIRI SELURUH SESI & MASUK KE REFLEKSI ---
  Future<void> _handleEndSession() async {
    _timer.cancel();
    try {
      final token = await LocalTokenStorage.getToken();
      if (token != null) {
        final nowStr = DateTime.now().toIso8601String();

        await _saveNotesAndEndSession();

        for (var sub in widget.card.subtasks) {
          if (sub.endTimeList == null && sub.clId != null) {
            await _cardService.updateCardList(token, widget.card.cardId!, sub.clId!, {
              'subTitle': sub.subTitle,
              'startTimeList': sub.startTimeList?.toIso8601String(),
              'endTimeList': nowStr,
            });
            sub.endTimeList = DateTime.parse(nowStr);
          }
        }

        await _cardService.updateCard(token, widget.card.cardId!, {
          'endTime': nowStr,
        });
      }
    } catch (e) {
      debugPrint('Gagal mengakhiri sesi: $e');
    }

    // 👇 Pengecekan mounted sebelum memanggil callback navigasi keluar sesi
    if (!mounted) return;
    widget.onNavigateToReflection();
  }

  // --- JEDA & SESUAIKAN (PAUSE & EDIT TASK) ---
  void _handlePauseAndCustomize() async {
    setState(() => _isPaused = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskPage(
          card: widget.card,
          onSaveUpdatedCard: (updatedCard) {
            setState(() {});
          },
        ),
      ),
    );

    if (mounted) {
      setState(() => _isPaused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Tanpa tombol silang bawaan
        title: Text(
          card.title ?? 'Sesi Fokus',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _handleEndSession,
            child: const Text(
              'AKHIRI',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SPOTIFY MINI PLAYER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Lo-Fi Beats to Study To • Spotify',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF166534),
                      size: 20,
                    ),
                    onPressed: () => launchSpotifyPlaylist(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- STRATEGI BADGE ---
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.video_collection_outlined,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    _isLoadingStrategy
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'STRATEGI: ${_strategyName?.toUpperCase() ?? 'POMODORO'}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                '⚡ Tip: Catat poin penting & putar ulang bagian yang sulit.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- TIMER LINGKARAN ---
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: (_secondsElapsed % 60) / 60,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimer(_secondsElapsed),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_isPaused)
                        const Text(
                          'PAUSED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- PERSONAL BEST BADGE ---
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PERSONAL BEST: ${_getPersonalBest()}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- TOMBOL JEDA & SESUAIKAN ---
            Center(
              child: OutlinedButton.icon(
                onPressed: _handlePauseAndCustomize,
                icon: const Icon(
                  Icons.pause_circle_outline,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
                label: const Text(
                  'Jeda & Sesuaikan',
                  style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E7FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- LANGKAH-LANGKAH / SUBTASKS ---
            const Text(
              'LANGKAH-LANGKAH',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (card.subtasks.isEmpty)
              const Text(
                'Tidak ada subtask.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              ...card.subtasks.map((subtask) {
                final bool isDone = subtask.endTimeList != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isDone ? const Color(0xFF16A34A) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subtask.subTitle ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isDone
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isDone
                                ? const Color(0xFF166534)
                                : const Color(0xFF334155),
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // TOMBOL SUBTASK DENGAN TAMPILAN HIJAU RAMAH & POP-UP GEN Z
                      if (subtask.startTimeList == null)
                        TextButton(
                          onPressed: () => widget.onStartSubtask(card, subtask),
                          child: const Text(
                            'Mulai',
                            style: TextStyle(fontSize: 11),
                          ),
                        )
                      else if (subtask.startTimeList != null &&
                          subtask.endTimeList == null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 169, 60, 60), // Hijau menenangkan
                            minimumSize: const Size(75, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            elevation: 0,
                          ),
                          onPressed: () => _handleStopSingleSubtask(subtask),
                          icon: const Icon(Icons.check, size: 14, color: Colors.white),
                          label: const Text(
                            'Akhiri',
                            style: TextStyle(fontSize: 10.5, color: Colors.white),
                          ),
                        )
                      else
                        const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),

            // --- PARKIR PIKIRAN (QUICK NOTES) ---
            Row(
              children: const [
                Icon(Icons.edit_note, size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 6),
                Text(
                  'PARKIR PIKIRAN (QUICK NOTES)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quickNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ada distraksi? Tulis di sini agar otakmu tetap tenang dan fokus...',
                hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- TOMBOL SELESAI & BERI REFLEKSI ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleEndSession,
                icon: const Icon(
                  Icons.rate_review_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Selesai & Beri Refleksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}