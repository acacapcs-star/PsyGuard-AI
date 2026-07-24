import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum NoteItemType { text, bullet, checkbox }

enum NotePriority {
  // 紅系 (緊急) — 淺到深
  red1, red2, red3, red4, red5,
  // 黃系 (重要) — 淺到深
  yellow1, yellow2, yellow3, yellow4, yellow5,
  // 綠系 (一般) — 淺到深
  green1, green2, green3, green4, green5,
}

Color priorityColor(NotePriority p) {
  switch (p) {
    case NotePriority.red1:    return const Color(0xFFFFCDD2);
    case NotePriority.red2:    return const Color(0xFFEF9A9A);
    case NotePriority.red3:    return const Color(0xFFEF5350);
    case NotePriority.red4:    return const Color(0xFFC62828);
    case NotePriority.red5:    return const Color(0xFF7B2B2B);
    case NotePriority.yellow1: return const Color(0xFFFFF9C4);
    case NotePriority.yellow2: return const Color(0xFFFFEE58);
    case NotePriority.yellow3: return const Color(0xFFFFCA28);
    case NotePriority.yellow4: return const Color(0xFFF57F17);
    case NotePriority.yellow5: return const Color(0xFF7B5800);
    case NotePriority.green1:  return const Color(0xFFC8E6C9);
    case NotePriority.green2:  return const Color(0xFF81C784);
    case NotePriority.green3:  return const Color(0xFF66BB6A);
    case NotePriority.green4:  return const Color(0xFF2E7D32);
    case NotePriority.green5:  return const Color(0xFF1B4B1B);
  }
}

String priorityLabel(NotePriority p) {
  switch (p) {
    case NotePriority.red1:    return '🔴 緊急 1';
    case NotePriority.red2:    return '🔴 緊急 2';
    case NotePriority.red3:    return '🔴 緊急 3';
    case NotePriority.red4:    return '🔴 緊急 4';
    case NotePriority.red5:    return '🔴 緊急 5';
    case NotePriority.yellow1: return '🟡 重要 1';
    case NotePriority.yellow2: return '🟡 重要 2';
    case NotePriority.yellow3: return '🟡 重要 3';
    case NotePriority.yellow4: return '🟡 重要 4';
    case NotePriority.yellow5: return '🟡 重要 5';
    case NotePriority.green1:  return '🟢 一般 1';
    case NotePriority.green2:  return '🟢 一般 2';
    case NotePriority.green3:  return '🟢 一般 3';
    case NotePriority.green4:  return '🟢 一般 4';
    case NotePriority.green5:  return '🟢 一般 5';
  }
}

class NoteItem {
  String text;
  NoteItemType type;
  bool checked;
  NotePriority priority;

  NoteItem({
    required this.text,
    this.type = NoteItemType.text,
    this.checked = false,
    this.priority = NotePriority.green3,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type.index,
    'checked': checked,
    'priority': priority.index,
  };

  factory NoteItem.fromJson(Map<String, dynamic> j) => NoteItem(
    text: j['text'] ?? '',
    type: NoteItemType.values[j['type'] ?? 0],
    checked: j['checked'] ?? false,
    priority: NotePriority.values[j['priority'] ?? 12],
  );
}

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  List<NoteItem> _items = [];
  bool _isZh = true;
  DateTime _selectedDate = DateTime.now();

  String get _dateKey {
    return 'note_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
  }

  String get _dateLabel {
    //
    return '${_selectedDate.year} 年 ${_selectedDate.month} 月 ${_selectedDate.day} 日';
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'zh_TW';
    setState(() => _isZh = lang != 'en');
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dateKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() => _items = list.map((e) => NoteItem.fromJson(e)).toList());
    } else {
      setState(() => _items = []);
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadNotes();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0ABFBC),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadNotes();
    }
  }

  Future<void> _clearAllNotes() async {
    if (_items.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📝 Clear all notes?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('This will delete all notes for this day. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _items = []);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dateKey);
    }
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('💡 ', style: TextStyle(fontSize: 20)),
            Text(_isZh ? 'PsyGuard 筆記指南' : 'Note Guide', style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold, color: const Color(0xFF2C5282), fontSize: 18
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GuideRow(icon: '•', text: '[Bullet] Great for quick ideas and key points.'),
            const _GuideRow(icon: '☑', text: '[Todo] Tap the checkbox to mark done.'),
            const _GuideRow(icon: '🟢', text: '[Priority] Tap dot to cycle 15 levels. Long press to pick directly.'),
            const _GuideRow(icon: '↕', text: '[Reorder] Long press any item to drag and reorder.'),
            const _GuideRow(icon: '🤖', text: '[AI Sync] All notes sync to AI chat. Luna will check in on your urgent red tasks!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isZh ? '我知道了 0_0/' : 'Got it 0_0/', style: TextStyle(color: Color(0xFF0ABFBC), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addItem(NoteItemType type) {
    setState(() => _items.add(NoteItem(text: '', type: type)));
    _saveNotes();
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
    _saveNotes();
  }

  void _cyclePriority(int index) {
    setState(() {
      final current = _items[index].priority.index;
      _items[index].priority = NotePriority.values[(current + 1) % 15];
    });
    _saveNotes();
  }

  // 長按直接選等級
  void _showPriorityPicker(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isZh ? '選擇優先等級' : 'Choose Priority Level', style: GoogleFonts.playfairDisplay(
              fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C5282),
            )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NotePriority.values.map((p) {
                final selected = _items[index].priority == p;
                return GestureDetector(
                  onTap: () {
                    setState(() => _items[index].priority = p);
                    _saveNotes();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor(p).withOpacity(selected ? 1.0 : 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: priorityColor(p),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      priorityLabel(p),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? Colors.white : priorityColor(p),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2C5282)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Diary \0_0/", style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontStyle: FontStyle.italic,
              color: const Color(0xFF2C5282),
            )),
            Text(_isZh ? '支援即時連動 AI 對話' : 'Syncs with AI chat in real time', style: const TextStyle(fontSize: 10, color: Color(0xFF0ABFBC))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0ABFBC)),
            onPressed: _showGuideDialog,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Color(0xFFEF5350), size: 20),
            onPressed: _clearAllNotes,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0ABFBC)),
                  onPressed: () => _changeDate(-1),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF2C5282)),
                      const SizedBox(width: 6),
                      Text(_dateLabel, style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)
                      )),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0ABFBC)),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickButton(label: _isZh ? '• 列點' : '• Bullet', onTap: () => _addItem(NoteItemType.bullet)),
                const SizedBox(width: 8),
                _QuickButton(label: _isZh ? '☑ 待辦' : '☑ Todo', onTap: () => _addItem(NoteItemType.checkbox)),
                const SizedBox(width: 8),
                _QuickButton(label: _isZh ? '✏ 文字' : '✏ Text', onTap: () => _addItem(NoteItemType.text)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(_isZh ? '這天還沒有筆記' : 'No notes for this day',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    onReorder: (old, newIndex) {
                      setState(() {
                        if (newIndex > old) newIndex--;
                        final item = _items.removeAt(old);
                        _items.insert(newIndex, item);
                      });
                      _saveNotes();
                    },
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return _NoteItemWidget(
                        key: ValueKey('${_dateKey}_$i'),
                        item: item,
                        priorityColor: priorityColor(item.priority),
                        onTextChange: (v) {
                          item.text = v;
                          _saveNotes();
                        },
                        onCheckToggle: () {
                          setState(() => item.checked = !item.checked);
                          _saveNotes();
                        },
                        onPriorityCycle: () => _cyclePriority(i),
                        onPriorityLongPress: () => _showPriorityPicker(i),
                        onDelete: () => _deleteItem(i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final String icon;
  final String text;
  const _GuideRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.4))),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0ABFBC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0ABFBC).withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF0ABFBC))),
      ),
    );
  }
}

class _NoteItemWidget extends StatefulWidget {
  final NoteItem item;
  final Color priorityColor;
  final ValueChanged<String> onTextChange;
  final VoidCallback onCheckToggle;
  final VoidCallback onPriorityCycle;
  final VoidCallback onPriorityLongPress;
  final VoidCallback onDelete;

  const _NoteItemWidget({
    super.key,
    required this.item,
    required this.priorityColor,
    required this.onTextChange,
    required this.onCheckToggle,
    required this.onPriorityCycle,
    required this.onPriorityLongPress,
    required this.onDelete,
  });

  @override
  State<_NoteItemWidget> createState() => _NoteItemWidgetState();
}

class _NoteItemWidgetState extends State<_NoteItemWidget> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(_NoteItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text) {
      _ctrl.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: widget.priorityColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          if (widget.item.type == NoteItemType.checkbox)
            GestureDetector(
              onTap: widget.onCheckToggle,
              child: Icon(
                widget.item.checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: widget.item.checked ? const Color(0xFF0ABFBC) : Colors.grey.shade400,
                size: 22,
              ),
            )
          else if (widget.item.type == NoteItemType.bullet)
            Text('•', style: TextStyle(fontSize: 20, color: widget.priorityColor))
          else
            Icon(Icons.edit_note_rounded, size: 20, color: Colors.grey.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '輸入內容...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 16,
                decoration: widget.item.checked ? TextDecoration.lineThrough : null,
                color: widget.item.checked ? Colors.grey.shade400 : const Color(0xFF2D3748),
              ),
              maxLines: null,
              onChanged: widget.onTextChange,
            ),
          ),
          GestureDetector(
            onTap: widget.onPriorityCycle,
            onLongPress: widget.onPriorityLongPress,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onDelete,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
