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
  DateTime _selectedDate = DateTime.now();

  String get _dateKey {
    return 'note_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
  }

  String get _dateLabel {
    const months = ['一','二','三','四','五','六','七','八','九','十','十一','十二'];
    return '${_selectedDate.year} 年 ${months[_selectedDate.month-1]} 月 ${_selectedDate.day} 日';
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

  // 新增功能：一鍵清空（橡皮擦演算法）
  Future<void> _clearAllNotes() async {
    if (_items.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📝 清空今日筆記？', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('確定要清除這一天所有的待辦事項與筆記嗎？此動作無法復原喔。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('確定清空', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold)),
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

  // 新增功能：彈出精美使用指南
  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('💡 ', style: TextStyle(fontSize: 20)),
            Text('PsyGuard 筆記指南', style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold, color: const Color(0xFF2C5282), fontSize: 18
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GuideRow(icon: '•', text: '【列點模式】適合記錄零碎靈感或重點。'),
            const _GuideRow(icon: '☑', text: '【待辦清單】點擊左側方框可打勾，會全自動畫上刪除線。'),
            const _GuideRow(icon: '🟢', text: '【輕重緩急】點擊右側圓點可循環切換 紅(緊急) ➔ 黃(重要) ➔ 綠(一般) 顏色標記。'),
            const _GuideRow(icon: '↕', text: '【長按拖拽】在列表任意處長按，即可上下拖動調整事情順序。'),
            const _GuideRow(icon: '🤖', text: '【AI 連動】此頁面寫下的所有筆記，都會全自動同步為 AI 聊天室的背景知識，Lumi 會主動關心妳的紅色緊急任務喔！'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我知道了 0_0/', style: TextStyle(color: Color(0xFF0ABFBC), fontWeight: FontWeight.bold)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2C5282)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日筆記', style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontStyle: FontStyle.italic,
              color: const Color(0xFF2C5282),
            )),
            Text('支援即時連動 AI 對話', style: const TextStyle(fontSize: 10, color: Color(0xFF0ABFBC))),
          ],
        ),
        actions: [
          // 指南按鈕
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0ABFBC)),
            onPressed: _showGuideDialog,
          ),
          // 橡皮擦清空按鈕
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
                        fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)
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
                _QuickButton(label: '• 列點', onTap: () => _addItem(NoteItemType.bullet)),
                const SizedBox(width: 8),
                _QuickButton(label: '☑ 待辦', onTap: () => _addItem(NoteItemType.checkbox)),
                const SizedBox(width: 8),
                _QuickButton(label: '✏ 文字', onTap: () => _addItem(NoteItemType.text)),
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
                        Text('這天還沒有筆記',
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
          GestureDetector(
            onTap: widget.onDelete,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
