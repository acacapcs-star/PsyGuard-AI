import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum NoteItemType { text, bullet, checkbox }
enum NotePriority { red, yellow, green }

class NoteItem {
  String text;
  NoteItemType type;
  bool checked;
  NotePriority priority;

  NoteItem({
    required this.text,
    this.type = NoteItemType.text,
    this.checked = false,
    this.priority = NotePriority.green,
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
    priority: NotePriority.values[j['priority'] ?? 2],
  );
}

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  List<NoteItem> _items = [];
  final _today = DateTime.now();

  String get _dateKey {
    return 'note_${_today.year}_${_today.month}_${_today.day}';
  }

  String get _dateLabel {
    const months = ['一','二','三','四','五','六','七','八','九','十','十一','十二'];
    return '${_today.year} 年 ${months[_today.month-1]} 月 ${_today.day} 日';
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dateKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() => _items = list.map((e) => NoteItem.fromJson(e)).toList());
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
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
      _items[index].priority = NotePriority.values[(current + 1) % 3];
    });
    _saveNotes();
  }

  Color _priorityColor(NotePriority p) {
    switch (p) {
      case NotePriority.red: return const Color(0xFFEF5350);
      case NotePriority.yellow: return const Color(0xFFFFCA28);
      case NotePriority.green: return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日筆記', style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontStyle: FontStyle.italic,
              color: const Color(0xFF2C5282),
            )),
            Text(_dateLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Color(0xFF0ABFBC)),
            onPressed: _saveNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          // 快捷按鈕
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickButton(label: '• 列點', onTap: () => _addItem(NoteItemType.bullet)),
                const SizedBox(width: 8),
                _QuickButton(label: '☑ 待辦', onTap: () => _addItem(NoteItemType.checkbox)),
                const SizedBox(width: 8),
                _QuickButton(label: '✏ 文字', onTap: () => _addItem(NoteItemType.text)),
              ],
            ),
          ),
          const Divider(height: 1),
          // 筆記列表
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('今天還沒有筆記',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('點上方按鈕新增',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
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
                        key: ValueKey(i),
                        item: item,
                        priorityColor: _priorityColor(item.priority),
                        onTextChange: (v) {
                          item.text = v;
                          _saveNotes();
                        },
                        onCheckToggle: () {
                          setState(() => item.checked = !item.checked);
                          _saveNotes();
                        },
                        onPriorityCycle: () => _cyclePriority(i),
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
          color: const Color(0xFF0ABFBC).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0ABFBC).withValues(alpha: 0.3)),
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
  final VoidCallback onDelete;

  const _NoteItemWidget({
    super.key,
    required this.item,
    required this.priorityColor,
    required this.onTextChange,
    required this.onCheckToggle,
    required this.onPriorityCycle,
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // 左側icon
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
          // 文字輸入
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '輸入內容...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                decoration: widget.item.checked ? TextDecoration.lineThrough : null,
                color: widget.item.checked ? Colors.grey.shade400 : const Color(0xFF2D3748),
              ),
              maxLines: null,
              onChanged: widget.onTextChange,
            ),
          ),
          // 優先級顏色
          GestureDetector(
            onTap: widget.onPriorityCycle,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: widget.priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 刪除
          GestureDetector(
            onTap: widget.onDelete,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
