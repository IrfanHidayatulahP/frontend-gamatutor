import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/pages/card/editCard.dart';
import 'package:gamatutor_kanban/pages/card/focusSession.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/localtokenService.dart';

class TaskDetailPage extends StatefulWidget {
  final Card card;
  final Function(Card, CardList) onStartSubtask;
  final Function(Card, CardList) onStopSubtask;
  final VoidCallback onNavigateToReflection;
  final Function(Card)? onEditCard;
  final VoidCallback? onDeleteCard;

  const TaskDetailPage({
    super.key,
    required this.card,
    required this.onStartSubtask,
    required this.onStopSubtask,
    required this.onNavigateToReflection,
    this.onEditCard,
    this.onDeleteCard,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final CardService _cardService = CardService();
  String? _strategyName;
  bool _isLoadingStrategy = true;

  @override
  void initState() {
    super.initState();
    _loadLearningStrategy();
  }

  Future<void> _loadLearningStrategy() async {
    if (widget.card.learningId == null || widget.card.learningId!.isEmpty) {
      setState(() {
        _strategyName = 'Pomodoro';
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
          _strategyName = strategy?.learningStrategy ?? 'Pomodoro';
          _isLoadingStrategy = false;
        });
      } else {
        setState(() {
          _strategyName = 'Pomodoro';
          _isLoadingStrategy = false;
        });
      }
    } catch (e) {
      setState(() {
        _strategyName = 'Pomodoro';
        _isLoadingStrategy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final String currentColumn = card.computedColumn.toLowerCase();

    final bool isStrikeThroughEnabled = currentColumn != 'planning';

    String bottomButtonText = 'Mulai Sesi Fokus';
    Color bottomButtonColor = const Color(0xFF3B82F6);
    VoidCallback? onBottomButtonPressed = () {};
    bool isEditDeleteEnabled = true;

    if (currentColumn == 'planning') {
      bottomButtonText = 'Mulai Sesi Fokus';
      bottomButtonColor = const Color(0xFF3B82F6);
      onBottomButtonPressed = () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Mulai Belajar?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: const Text(
              'Kamu mau belajar card ini? Semua subtask akan langsung dimulai secara bersamaan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  try {
                    final token = await LocalTokenStorage.getToken();
                    if (token != null) {
                      final nowStr = DateTime.now().toIso8601String();

                      if (card.startTime == null) {
                        await _cardService.updateCard(token, card.cardId!, {
                          'nmMatkul': card.courseName ?? '',
                          'title': card.title ?? '',
                          'description': card.description ?? '',
                          'learningId': card.learningId ?? '',
                          'priority': card.priority ?? 'sedang',
                          'difficulty': card.difficulty ?? 'sedang',
                          'deadline': card.deadline != null
                              ? card.deadline!.toIso8601String().split('T')[0]
                              : null,
                          'startTime': nowStr,
                        });
                      }

                      for (var sub in card.subtasks) {
                        if (sub.startTimeList == null && sub.clId != null) {
                          await _cardService.updateCardList(
                            token,
                            card.cardId!,
                            sub.clId!,
                            {'subTitle': sub.subTitle, 'startTimeList': nowStr},
                          );
                          sub.startTimeList = DateTime.parse(nowStr);
                        }
                      }
                      card.startTime = DateTime.parse(nowStr);
                    }
                  } catch (e) {
                    debugPrint('Gagal mencatat start otomatis: $e');
                  }

                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FocusSessionPage(
                        card: card,
                        onStartSubtask: widget.onStartSubtask,
                        onStopSubtask: widget.onStopSubtask,
                        onNavigateToReflection: () {
                          Navigator.pop(context);
                          widget.onNavigateToReflection();
                        },
                      ),
                    ),
                  ).then((_) async {
                    if (mounted) {
                      try {
                        final token = await LocalTokenStorage.getToken();
                        if (token != null && card.cardId != null) {
                          // Ambil semua cards lalu cari card dengan ID yang sama untuk memperbarui state lokal
                          final updatedCards = await _cardService
                              .getCardsByUser(token);
                          final freshCard = updatedCards.firstWhere(
                            (c) => c.cardId == card.cardId,
                            orElse: () => card,
                          );
                          setState(() {
                            widget.card.subtasks = freshCard.subtasks;
                            widget.card.notes = freshCard.notes;
                            widget.card.startTime = freshCard.startTime;
                            widget.card.endTime = freshCard.endTime;
                          });
                        }
                      } catch (e) {
                        debugPrint('Gagal memperbarui data detail card: $e');
                        setState(() {});
                      }
                    }
                  });
                },
                child: const Text(
                  'Ya, Mulai',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      };
    } else if (currentColumn == 'monitoring') {
      bottomButtonText = 'Mulai Sesi Fokus';
      bottomButtonColor = const Color(0xFF3B82F6);
      onBottomButtonPressed = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FocusSessionPage(
              card: card,
              onStartSubtask: widget.onStartSubtask,
              onStopSubtask: widget.onStopSubtask,
              onNavigateToReflection: () {
                Navigator.pop(context);
                widget.onNavigateToReflection();
              },
            ),
          ),
        ).then((_) async{
          if (mounted) {
            try {
              final token = await LocalTokenStorage.getToken();
              if (token != null && card.cardId != null) {
                // Ambil semua cards lalu cari card dengan ID yang sama untuk memperbarui state lokal
                final updatedCards = await _cardService.getCardsByUser(token);
                final freshCard = updatedCards.firstWhere(
                  (c) => c.cardId == card.cardId,
                  orElse: () => card,
                );
                setState(() {
                  widget.card.subtasks = freshCard.subtasks;
                  widget.card.notes = freshCard.notes;
                  widget.card.startTime = freshCard.startTime;
                  widget.card.endTime = freshCard.endTime;
                });
              }
            } catch (e) {
              debugPrint('Gagal memperbarui data detail card: $e');
              setState(() {});
            }
          }
        });
      };
    } else if (currentColumn == 'controlling') {
      bottomButtonText = 'Mulai Reflection';
      bottomButtonColor = const Color(0xFF10B981);
      onBottomButtonPressed = widget.onNavigateToReflection;
      isEditDeleteEnabled = false;
    } else if (currentColumn == 'reflection') {
      bottomButtonText = 'Completed';
      bottomButtonColor = const Color(0xFF10B981);
      onBottomButtonPressed = null;
      isEditDeleteEnabled = false;
    }

    final totalSub = card.subtasks.length;
    final completedSub = card.subtasks
        .where((s) => s.endTimeList != null)
        .length;
    final double progressRatio = totalSub > 0 ? (completedSub / totalSub) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Column Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.show_chart,
                    size: 12,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentColumn.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              card.title ?? 'Tanpa Judul',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // Badge Strategy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 14,
                        color: Color(0xFF9333EA),
                      ),
                      const SizedBox(width: 4),
                      _isLoadingStrategy
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF9333EA),
                              ),
                            )
                          : Text(
                              'Strategy: ${_strategyName ?? 'Pomodoro'}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9333EA),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Due Date & Priority Boxes
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.deadline != null
                              ? '${card.deadline!.day}/${card.deadline!.month}/${card.deadline!.year}'
                              : 'Tidak ada',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.flag_outlined,
                              size: 12,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.priority != null
                              ? card.priority!.toUpperCase()
                              : 'MEDIUM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: card.priority?.toLowerCase() == 'high'
                                ? const Color(0xFFEA580C)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description Section
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (card.description != null && card.description!.isNotEmpty)
                    ? card.description!
                    : 'Tidak ada deskripsi.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),

            // --- NOTES SECTION (CATATAN DARI SESI FOKUS) ---
            if (card.notes != null && card.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Catatan Sesi Fokus (Notes)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Subtasks Section dengan Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtasks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: currentColumn == 'planning'
                              ? 0.0
                              : progressRatio,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentColumn == 'planning'
                          ? '0/$totalSub'
                          : '$completedSub/$totalSub',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Render Subtasks Dinamis
            if (card.subtasks.isEmpty)
              const Text(
                'Tidak ada subtask.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              ...card.subtasks.map((subtask) {
                final bool isDone =
                    isStrikeThroughEnabled && (subtask.endTimeList != null);
                final bool isStarted = subtask.startTimeList != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtask.subTitle ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF334155),
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (!isStarted && !isDone)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            onPressed: () async {
                              await widget.onStartSubtask(card, subtask);
                              if (context.mounted) setState(() {});
                            },
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),

                      if (isStarted && !isDone)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            onPressed: () async {
                              await widget.onStopSubtask(card, subtask);
                              if (context.mounted) setState(() {});
                            },
                            icon: const Icon(
                              Icons.stop_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),

                      if (isDone)
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

            // References Section
            const Text(
              'References',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            if (card.urlCount == 0)
              const Text(
                'Tidak ada lampiran URL.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              ...card.urlList.map((urlItem) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.link,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          urlItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: isEditDeleteEnabled
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskPage(
                              card: widget.card,
                              onSaveUpdatedCard: (updatedCard) {
                                if (widget.onEditCard != null) {
                                  widget.onEditCard!(updatedCard);
                                }
                              },
                            ),
                          ),
                        );
                        setState(() {
                          _isLoadingStrategy = true;
                        });
                        _loadLearningStrategy();
                      }
                    : null,
                icon: Icon(
                  Icons.edit_outlined,
                  color: isEditDeleteEnabled
                      ? const Color(0xFF64748B)
                      : Colors.grey.shade300,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onBottomButtonPressed,
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    bottomButtonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bottomButtonColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: IconButton(
                onPressed: isEditDeleteEnabled ? widget.onDeleteCard : null,
                icon: Icon(
                  Icons.delete_outline,
                  color: isEditDeleteEnabled
                      ? const Color(0xFFEF4444)
                      : Colors.grey.shade300,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
