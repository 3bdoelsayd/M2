import 'dart:math';
import 'package:flutter/material.dart';
import '../models/kitchen_design.dart';
import '../models/customer_record.dart';
import '../services/storage_service.dart';

class KitchenDesignerPage extends StatefulWidget {
  final CustomerRecord? customer; 
  const KitchenDesignerPage({super.key, this.customer});

  @override
  State<KitchenDesignerPage> createState() => _KitchenDesignerPageState();
}

class _KitchenDesignerPageState extends State<KitchenDesignerPage> {
  List<KitchenComponent> _components = [];
  final List<List<KitchenComponent>> _history = []; 
  final TransformationController _transformationController = TransformationController();
  
  KitchenElementType _selectedTool = KitchenElementType.none;
  KitchenComponent? _activeComponent;
  KitchenComponent? _selectedComponent;
  
  int _moveMode = 0; 
  Offset _dragOffset = Offset.zero;
  Offset _dragOffsetEnd = Offset.zero;
  final double _gridSize = 10.0;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()..translate(-500.0, -500.0);
    if (widget.customer != null && widget.customer!.designComponents != null) {
      _components = List.from(widget.customer!.designComponents!.map((e) => _cloneComponent(e)));
    } else {
      _loadLastDesign();
    }
  }

  void _loadLastDesign() async {
    final components = await StorageService.loadKitchenDesign("last_work");
    if (components != null && components.isNotEmpty && widget.customer == null) {
      setState(() => _components = components);
    }
  }

  void _saveCurrentDesign() async {
    // إذا كان هناك عميل مفتوح بالفعل، نحدث ملفه مباشرة
    if (widget.customer != null) {
      _updateCustomerRecord(widget.customer!);
    } else {
      _showSaveOptionsDialog();
    }
  }

  void _updateCustomerRecord(CustomerRecord record) async {
    final updatedCustomer = CustomerRecord(
      id: record.id,
      customerName: record.customerName,
      phoneNumber: record.phoneNumber,
      address: record.address,
      paidAmount: record.paidAmount,
      notes: record.notes,
      date: record.date,
      items: record.items,
      designComponents: _components,
    );
    await StorageService.saveRecord(updatedCustomer);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ التعديلات في ملف العميل"), backgroundColor: Colors.green));
  }

  void _showSaveOptionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("خيارات الحفظ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text("حفظ كعميل جديد"),
                subtitle: const Text("سيتم إنشاء سجل جديد في مكتبة العملاء"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showNewCustomerDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text("ربط بعميل موجود"),
                subtitle: const Text("اختر عميلاً من القائمة لربط الرسمة به"),
                onTap: () {
                  Navigator.pop(ctx);
                  _linkDesignToCustomer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_outlined, color: Colors.orange),
                title: const Text("حفظ كتصميم مستقل فقط"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSaveAsStandaloneDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("بيانات العميل الجديد"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم العميل *")),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "رقم الهاتف"), keyboardType: TextInputType.phone),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "العنوان")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  final newRecord = CustomerRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerName: nameCtrl.text,
                    phoneNumber: phoneCtrl.text,
                    address: addressCtrl.text,
                    date: DateTime.now(),
                    items: [],
                    designComponents: _components,
                  );
                  await StorageService.saveRecord(newRecord);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنشاء العميل وحفظ الرسمة بنجاح"), backgroundColor: Colors.green));
                }
              },
              child: const Text("إنشاء وحفظ"),
            )
          ],
        ),
      ),
    );
  }

  void _showSaveAsStandaloneDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("حفظ التصميم"),
          content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "أدخل اسم التصميم")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(onPressed: () { if (ctrl.text.isNotEmpty) { StorageService.saveKitchenDesign(ctrl.text, _components); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green)); } }, child: const Text("حفظ")),
          ],
        ),
      ),
    );
  }

  void _linkDesignToCustomer() async {
    final customers = await StorageService.loadRecords();
    if (!mounted) return;
    if (customers.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يوجد عملاء مسجلين حالياً"))); return; }
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("اختر العميل لربط الرسمة"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customers.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(customers[i].customerName),
                leading: const Icon(Icons.person),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateCustomerRecord(customers[i]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startNewProject() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("مشروع جديد"),
          content: const Text("هل تريد مسح اللوحة والبدء في تصميم جديد؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                _saveToHistory();
                setState(() { _components.clear(); _selectedComponent = null; });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("بدء جديد"),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadDialog() async {
    final names = await StorageService.getAllDesignNames();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("فتح تصميم محفوظ"),
            content: names.isEmpty 
              ? const Text("لا توجد تصاميم محفوظة حالياً")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: names.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (c, i) => ListTile(
                      title: Text(names[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                      leading: const Icon(Icons.architecture, color: Colors.blue),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          await StorageService.deleteKitchenDesign(names[i]);
                          final newNames = await StorageService.getAllDesignNames();
                          setDialogState(() { names.clear(); names.addAll(newNames); });
                        },
                      ),
                      onTap: () async {
                        final loaded = await StorageService.loadKitchenDesign(names[i]);
                        if (loaded != null) setState(() => _components = loaded);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
            actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إغلاق")) ],
          ),
        ),
      ),
    );
  }

  void _saveToHistory() {
    _history.add(List.from(_components.map((e) => _cloneComponent(e))));
    if (_history.length > 20) _history.removeAt(0);
    StorageService.saveKitchenDesign("last_work", _components);
  }

  void _undo() {
    if (_history.isNotEmpty) {
      setState(() { _components = _history.removeLast(); _selectedComponent = null; });
      StorageService.saveKitchenDesign("last_work", _components);
    }
  }

  KitchenComponent _cloneComponent(KitchenComponent c) {
    return KitchenComponent(
      id: c.id, position: c.position, endPosition: c.endPosition, type: c.type, color: c.color, width: c.width, text: c.text, rotation: c.rotation,
      points: c.points != null ? List.from(c.points!) : null,
    );
  }

  void _handleTap(TapDownDetails details) {
    final pos = details.localPosition;
    KitchenComponent? clicked = _findComponentAt(pos);
    setState(() {
      _selectedComponent = clicked;
      if (clicked == null && _selectedTool == KitchenElementType.note) { _addNewNote(pos); }
      else if (clicked == null && _selectedTool != KitchenElementType.none && _selectedTool != KitchenElementType.wall && _selectedTool != KitchenElementType.scribble) {
        _saveToHistory(); _addComponent(_snapPos(pos));
      }
    });
  }

  void _addNewNote(Offset pos) {
    _saveToHistory();
    final newNote = KitchenComponent(id: DateTime.now().toString(), position: pos, type: KitchenElementType.note, text: "", color: Colors.red);
    _components.add(newNote);
    _selectedComponent = newNote;
    _showEditTextDialog(newNote); 
  }

  void _addComponent(Offset pos) {
    _components.add(KitchenComponent(id: DateTime.now().toString(), position: pos, type: _selectedTool, color: _getToolColor(_selectedTool), width: (_selectedTool == KitchenElementType.window || _selectedTool == KitchenElementType.door) ? 60 : 50, rotation: 0));
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final pos = details.localPosition;
    KitchenComponent? clicked = _findComponentAt(pos);
    if (clicked != null && clicked.type == KitchenElementType.wall) {
      Offset? joint;
      if ((clicked.position - pos).distance < 35) joint = clicked.position;
      else if ((clicked.endPosition! - pos).distance < 35) joint = clicked.endPosition;
      if (joint != null) { _saveToHistory(); _startNewWall(joint); setState(() {}); }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final pos = details.localPosition;
    KitchenComponent? clicked = _findComponentAt(pos);
    if (clicked != null) {
      _saveToHistory(); _selectedComponent = clicked;
      if (clicked.type == KitchenElementType.wall) {
        if ((clicked.position - pos).distance < 25) _moveMode = 1;
        else if ((clicked.endPosition! - pos).distance < 25) _moveMode = 2;
        else { _moveMode = 3; _dragOffset = clicked.position - pos; _dragOffsetEnd = clicked.endPosition! - pos; }
      } else { _moveMode = 3; _dragOffset = clicked.position - pos; }
      _activeComponent = clicked;
    } else if (_selectedTool == KitchenElementType.wall) { _saveToHistory(); _startNewWall(_snapPos(pos)); }
    else if (_selectedTool == KitchenElementType.scribble) { _saveToHistory(); _startNewScribble(pos); }
    setState(() {});
  }

  void _startNewWall(Offset pos) {
    final newWall = KitchenComponent(id: DateTime.now().toString(), position: pos, endPosition: pos, type: KitchenElementType.wall);
    _components.add(newWall);
    _activeComponent = newWall;
    _moveMode = 2;
  }

  void _startNewScribble(Offset pos) {
    final newScribble = KitchenComponent(id: DateTime.now().toString(), position: pos, type: KitchenElementType.scribble, points: [pos], color: Colors.red);
    _components.add(newScribble);
    _activeComponent = newScribble;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_activeComponent == null) return;
    final pos = details.localPosition;
    setState(() {
      if (_activeComponent!.type == KitchenElementType.wall) {
        if (_moveMode == 1) _activeComponent!.position = _snapPos(pos);
        else if (_moveMode == 2) _activeComponent!.endPosition = _snapPos(pos);
        else if (_moveMode == 3) { _activeComponent!.position = _snapPos(pos + _dragOffset); _activeComponent!.endPosition = _snapPos(pos + _dragOffsetEnd); }
      } else if (_activeComponent!.type == KitchenElementType.scribble) { _activeComponent!.points!.add(pos); }
      else { _activeComponent!.position = _snapPos(pos + _dragOffset); }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _activeComponent = null; _moveMode = 0;
    StorageService.saveKitchenDesign("last_work", _components);
  }

  KitchenComponent? _findComponentAt(Offset pos) {
    for (var comp in _components.reversed) {
      if (comp.type == KitchenElementType.wall && comp.endPosition != null) {
        if ((comp.position - pos).distance < 30 || (comp.endPosition! - pos).distance < 30) return comp;
        if (_isPointOnLine(pos, comp.position, comp.endPosition!, 20)) return comp;
      } else if (comp.type == KitchenElementType.scribble && comp.points != null) {
        for (var pt in comp.points!) { if ((pt - pos).distance < 15) return comp; }
      } else { if ((comp.position - pos).distance < 40) return comp; }
    }
    return null;
  }

  void _showEditLengthDialog() {
    if (_selectedComponent == null || _selectedComponent!.type != KitchenElementType.wall) return;
    final wall = _selectedComponent!;
    final controller = TextEditingController(text: (wall.position - wall.endPosition!).distance.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("الطول بالسنتيمتر"),
        content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null && val > 0) { _saveToHistory(); setState(() {
                  Offset dir = wall.endPosition! - wall.position;
                  if (dir.distance > 0) wall.endPosition = wall.position + (dir / dir.distance) * val;
                }); }
              Navigator.pop(context);
            },
            child: const Text("تطبيق"),
          )
        ],
      ),
    );
  }

  void _showEditTextDialog(KitchenComponent comp) {
    final controller = TextEditingController(text: comp.text);
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("اكتب النص أو الملاحظة"),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "اكتب هنا...")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(onPressed: () { _saveToHistory(); setState(() => comp.text = controller.text); Navigator.pop(context); }, child: const Text("حفظ")),
          ],
        ),
      ),
    );
  }

  Offset _snapPos(Offset pos) => Offset((pos.dx / _gridSize).round() * _gridSize, (pos.dy / _gridSize).round() * _gridSize);

  bool _isPointOnLine(Offset p, Offset a, Offset b, double threshold) {
    double l2 = (a - b).distanceSquared;
    if (l2 == 0) return (p - a).distance < threshold;
    double t = max(0, min(1, ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2));
    return (p - Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy))).distance < threshold;
  }

  Color _getToolColor(KitchenElementType type) {
    switch (type) {
      case KitchenElementType.wall: return Colors.black;
      case KitchenElementType.sink: return Colors.blue;
      case KitchenElementType.stove: return Colors.orange;
      case KitchenElementType.cabinet: return Colors.brown;
      case KitchenElementType.scribble: return Colors.red;
      case KitchenElementType.door: return Colors.brown[700]!;
      case KitchenElementType.window: return Colors.cyan;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.customer != null ? "مخطط: ${widget.customer!.customerName}" : "مصمم المطابخ", style: const TextStyle(color: Colors.black, fontSize: 14)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.black87), onPressed: _startNewProject),
          IconButton(icon: const Icon(Icons.center_focus_strong, color: Colors.green), onPressed: () => _transformationController.value = Matrix4.identity()..translate(-500.0, -500.0)),
          IconButton(icon: const Icon(Icons.folder_open, color: Colors.orange), onPressed: _showLoadDialog),
          IconButton(icon: const Icon(Icons.save, color: Colors.green), onPressed: _saveCurrentDesign),
          IconButton(icon: const Icon(Icons.undo, color: Colors.blue), onPressed: _undo),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(1500),
            minScale: 0.1,
            maxScale: 5.0,
            panEnabled: _selectedTool == KitchenElementType.none, 
            child: GestureDetector(
              onTapDown: _handleTap,
              onLongPressStart: _handleLongPressStart,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: CustomPaint(
                painter: SimplePainter(components: _components, selectedComponent: _selectedComponent),
                size: const Size(3000, 3000), 
              ),
            ),
          ),
          
          if (_selectedComponent != null)
            Positioned(
              top: 10, left: 10, right: 10,
              child: Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (_selectedComponent!.type == KitchenElementType.wall)
                            ActionChip(
                              avatar: const Icon(Icons.straighten, size: 16),
                              label: Text("${(_selectedComponent!.position - _selectedComponent!.endPosition!).distance.toStringAsFixed(1)} سم"),
                              onPressed: _showEditLengthDialog,
                            )
                          else if (_selectedComponent!.type != KitchenElementType.note && _selectedComponent!.type != KitchenElementType.scribble)
                            IconButton(
                              icon: const Icon(Icons.rotate_right, color: Colors.blue),
                              onPressed: () => setState(() { _saveToHistory(); _selectedComponent!.rotation += pi / 2; }),
                            ),
                          IconButton(icon: const Icon(Icons.text_fields, color: Colors.blue), onPressed: () => _showEditTextDialog(_selectedComponent!)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { _saveToHistory(); _selectedComponent!.width -= 1; })),
                          Text("${_selectedComponent!.width.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() { _saveToHistory(); _selectedComponent!.width += 1; })),
                          const SizedBox(width: 5),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() { _saveToHistory(); _components.remove(_selectedComponent); _selectedComponent = null; })),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _toolItem(KitchenElementType.none, Icons.touch_app, "تحديد"),
                    _toolItem(KitchenElementType.wall, Icons.edit, "جدار"),
                    _toolItem(KitchenElementType.door, Icons.sensor_door, "باب"),
                    _toolItem(KitchenElementType.window, Icons.window, "شباك"),
                    _toolItem(KitchenElementType.stove, Icons.fireplace, "فرن"),
                    _toolItem(KitchenElementType.sink, Icons.water_drop, "حوض"),
                    _toolItem(KitchenElementType.cabinet, Icons.grid_view, "خزانة"),
                    _toolItem(KitchenElementType.scribble, Icons.gesture, "قلم"),
                    _toolItem(KitchenElementType.note, Icons.sticky_note_2, "نص حر"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolItem(KitchenElementType type, IconData icon, String label) {
    bool isSelected = _selectedTool == type;
    return GestureDetector(
      onTap: () => setState(() { _selectedTool = type; _selectedComponent = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: isSelected ? Colors.blue : Colors.transparent, borderRadius: BorderRadius.circular(25)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class SimplePainter extends CustomPainter {
  final List<KitchenComponent> components;
  final KitchenComponent? selectedComponent;
  SimplePainter({required this.components, this.selectedComponent});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey[200]!..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 20) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    for (var comp in components) {
      final isSelected = comp == selectedComponent;
      if (comp.type == KitchenElementType.wall && comp.endPosition != null) {
        final paint = Paint()..color = isSelected ? Colors.blue : Colors.black..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawLine(comp.position, comp.endPosition!, paint);
        if (isSelected) {
          canvas.drawCircle(comp.position, 10, Paint()..color = Colors.blue);
          canvas.drawCircle(comp.endPosition!, 10, Paint()..color = Colors.blue);
        }
        _drawText(canvas, "${(comp.position - comp.endPosition!).distance.toStringAsFixed(1)} سم", (comp.position + comp.endPosition!) / 2 + const Offset(0, -15), Colors.black, 11);
        if (comp.text.isNotEmpty) _drawText(canvas, comp.text, (comp.position + comp.endPosition!) / 2 + const Offset(0, 15), Colors.blue[900]!, 10, isBold: true);
      } else {
        canvas.save();
        canvas.translate(comp.position.dx, comp.position.dy);
        canvas.rotate(comp.rotation);
        final paint = Paint()..color = isSelected ? Colors.blue : comp.color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        if (comp.type == KitchenElementType.door) { _drawDoor(canvas, comp.width, isSelected); }
        else if (comp.type == KitchenElementType.window) { _drawWindow(canvas, comp.width, isSelected); }
        else if (comp.type == KitchenElementType.stove) { _drawStove(canvas, comp.width, isSelected); }
        else if (comp.type == KitchenElementType.scribble && comp.points != null) { canvas.restore(); _drawScribble(canvas, comp, isSelected); continue; }
        else if (comp.type == KitchenElementType.note) {
          if (isSelected) canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 80, height: 30), Paint()..color = Colors.blue.withOpacity(0.1));
          _drawText(canvas, comp.text.isEmpty ? "نص..." : comp.text, Offset.zero, Colors.red, 13, isBold: true);
        } else {
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: comp.width, height: comp.width), paint..style = PaintingStyle.fill..color = (isSelected ? Colors.blue : comp.color).withOpacity(0.3));
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: comp.width, height: comp.width), paint..style = PaintingStyle.stroke);
        }
        if (comp.type != KitchenElementType.note && comp.text.isNotEmpty) {
           canvas.rotate(-comp.rotation); 
           _drawText(canvas, comp.text, Offset(0, comp.width/2 + 10), Colors.black87, 9);
        }
        canvas.restore();
      }
    }
  }

  void _drawScribble(Canvas canvas, KitchenComponent comp, bool isSelected) {
    final paint = Paint()..color = isSelected ? Colors.blue : comp.color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    if (comp.points == null || comp.points!.isEmpty) return;
    final path = Path()..moveTo(comp.points![0].dx, comp.points![0].dy);
    for (var i = 1; i < comp.points!.length; i++) path.lineTo(comp.points![i].dx, comp.points![i].dy);
    canvas.drawPath(path, paint);
  }

  void _drawDoor(Canvas canvas, double r, bool isSelected) {
    final paint = Paint()..color = isSelected ? Colors.blue : Colors.brown..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), 0, -pi/2, false, paint);
    canvas.drawLine(Offset.zero, Offset(r, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, -r), paint..strokeWidth = 1);
  }

  void _drawWindow(Canvas canvas, double w, bool isSelected) {
    final paint = Paint()..color = isSelected ? Colors.blue : Colors.cyan..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: 10), paint);
    canvas.drawLine(Offset(-w/2, 0), Offset(w/2, 0), paint);
  }

  void _drawStove(Canvas canvas, double s, bool isSelected) {
    final paint = Paint()..color = isSelected ? Colors.blue : Colors.orange..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), paint);
    double r = s * 0.2;
    canvas.drawCircle(Offset(-r, -r), r*0.7, paint);
    canvas.drawCircle(Offset(r, -r), r*0.7, paint);
    canvas.drawCircle(Offset(-r, r), r*0.7, paint);
    canvas.drawCircle(Offset(r, r), r*0.7, paint);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double size, {bool isBold = false}) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)), textDirection: TextDirection.rtl)..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
