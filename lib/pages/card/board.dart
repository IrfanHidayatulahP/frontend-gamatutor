import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/localtokenService.dart';

class KanbanBoardView extends StatefulWidget {
  const KanbanBoardView({Key? key}) : super(key: key);

  @override
  State<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends State<KanbanBoardView> {
  final CardService _cardService = CardService();
  List<Card> _cards = [];
  bool _isLoading = true;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchKanbanCards();
  }

  Future<void> _fetchKanbanCards() async {
    setState(() => _isLoading = true);
    
    final token = await LocalTokenStorage.getToken();
    if (token != null) {
      final fetchedCards = await _cardService.getCardsByUser(token);
      
      // PERIKSA APAKAH WIDGET MASIH AKTIF SEBELUM SETSTATE
      if (!mounted) return;
      
      setState(() {
        _cards = fetchedCards;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Menentukan kolom berdasarkan aturan database timestamp
  String _determineColumn(Card? card) {
  if (card == null) return 'Planning';
  
  if (card.startTime == null && card.endTime == null) {
    return 'Planning';
  } else if (card.startTime != null && card.endTime == null) {
    return 'Monitoring';
  } else if (card.endTime != null && card.reflectionCompletedAt == null) {
    return 'Controlling';
  } else {
    return 'Reflection';
  }
}

  @override
  Widget build(BuildContext context) {
    // Memilah kartu ke masing-masing kolom berdasarkan toColumn terakhir dari tabel column_movements atau cardList
      final planningCards = _cards.where((c) {
        final lastColumn = c.columnMovements!.isNotEmpty ?  c.columnMovements?.last.toColumn : 'Planning';
        return lastColumn?.toLowerCase() == 'planning';
      }).toList();

      final monitoringCards = _cards.where((c) {
        final lastColumn = c.columnMovements!.isNotEmpty ?  c.columnMovements?.last.toColumn : 'Monitoring';
        return lastColumn?.toLowerCase() == 'monitoring';
      }).toList();

      final controllingCards = _cards.where((c) {
        final lastColumn = c.columnMovements!.isNotEmpty ?  c.columnMovements?.last.toColumn : 'Controlling';
        return lastColumn?.toLowerCase() == 'controlling';
      }).toList();

      final reflectionCards = _cards.where((c) {
        final lastColumn = c.columnMovements!.isNotEmpty ?  c.columnMovements?.last.toColumn : 'Reflection';
        return lastColumn?.toLowerCase() == 'reflection';
      }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Board
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Board',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_cards.length} Tugas Aktif',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.grey),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chip "All"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),

                  // Kanban Columns Horizontal Scroll
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65, // Batasi tinggi kolom agar ListView bisa melakukan scroll internal
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildColumn('Planning', Colors.lightBlue, planningCards, allowAdd: true),
                          const SizedBox(width: 16),
                          _buildColumn('Monitoring', Colors.blue, monitoringCards, allowAdd: false),
                          const SizedBox(width: 16),
                          _buildColumn('Controlling', Colors.orange, controllingCards, allowAdd: false),
                          const SizedBox(width: 16),
                          _buildColumn('Reflection', Colors.green, reflectionCards, allowAdd: false),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      
      // Floating Action Button Custom sesuai permintaan
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isFabExpanded) ...[
            GestureDetector(
              onTap: () {
                setState(() => _isFabExpanded = false);
                // Aksi Collaboration
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 140),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person_outline, color: Color(0xFF4F46E5)),
                    SizedBox(width: 8),
                    Text('Collaboration', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _isFabExpanded = false);
                // Aksi Tambah Card (Hanya dari Planning / Global Add)
                _showAddCardDialog();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.library_add, color: Color(0xFF4F46E5)),
                    SizedBox(width: 8, height: 2),
                    Text('Add Card', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                  ],
                ),
              ),
            ),
          ],
          FloatingActionButton(
            backgroundColor: const Color(0xFF4F46E5),
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            child: Icon(_isFabExpanded ? Icons.close : Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Widget Kolom Kanban (Parameter allowAdd hanya true jika title == 'PLANNING')
  Widget _buildColumn(String title, Color dotColor, List<Card> cards, {required bool allowAdd}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Text('${cards.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 12),

          // LAZY RENDERING MENGGUNAKAN LISTVIEW.BUILDER
          // Menggunakan Expanded agar ListView mengisi sisa ruang kolom secara dinamis
          Expanded(
            child: ListView.builder(
              itemCount: cards.length + (allowAdd ? 1 : 0), // Tambah 1 jika kolom ini ada tombol tambah
              itemBuilder: (context, index) {
                // Jika ini adalah indeks terakhir di kolom Planning dan tombol tambah diizinkan
                if (allowAdd && index == cards.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: InkWell(
                      onTap: () => _showAddCardDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text('Tambah tugas', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Render Kartu Kanban secara lazy
                final card = cards[index];
                final subtaskText = card.subtasks.isNotEmpty ? card.subtasks.first.subTitle : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (card.title!.isNotEmpty == true ? card.title : subtaskText) ?? 'Tanpa Judul',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      if (card.description != null && card.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Tugas Baru'),
        content: const Text('Form penambahan kartu baru khusus ke tahap Planning.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementasi tambah card ke API
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}