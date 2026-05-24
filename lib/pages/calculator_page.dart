import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/band_item.dart';
import '../models/customer_record.dart';
import '../services/storage_service.dart';
import '../widgets/custom_widgets.dart';
import 'library_page.dart';
import 'kitchen_designer_page.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _mode = 'sqm';
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _linearCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double _sqm = 0;
  double _lm = 0;
  double _perimeter = 0;
  double _total = 0;
  final List<BandItem> _items = [];

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _linearCtrl.dispose();
    _priceCtrl.dispose();
    _nameCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerAddressCtrl.dispose();
    _paidAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _calc() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    double qty = 0;
    if (_mode == 'sqm') {
      final l = double.tryParse(_lengthCtrl.text) ?? 0;
      final w = double.tryParse(_widthCtrl.text) ?? 0;
      qty = l * w;
      setState(() {
        _sqm = qty;
        _perimeter = (l + w) * 2;
        _lm = 0;
        _total = qty * price;
      });
    } else {
      qty = double.tryParse(_linearCtrl.text) ?? 0;
      setState(() {
        _lm = qty;
        _sqm = 0;
        _perimeter = 0;
        _total = qty * price;
      });
    }
  }

  void _addItem() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    double qty = 0;
    String detail = '';
    if (_mode == 'sqm') {
      final l = double.tryParse(_lengthCtrl.text) ?? 0;
      final w = double.tryParse(_widthCtrl.text) ?? 0;
      qty = l * w;
      detail = '${l.toStringAsFixed(2)} × ${w.toStringAsFixed(2)} م = ${qty.toStringAsFixed(2)} م²';
    } else {
      qty = double.tryParse(_linearCtrl.text) ?? 0;
      detail = '${qty.toStringAsFixed(2)} م.ط';
    }
    if (qty == 0 || price == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أدخل القياسات والسعر أولاً', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFFE24B4A)),
      );
      return;
    }
    final name = _nameCtrl.text.trim().isEmpty ? (_mode == 'sqm' ? 'بند متر مربع' : 'بند متر طولي') : _nameCtrl.text.trim();
    setState(() {
      _items.add(BandItem(name: name, detail: detail, mode: _mode, qty: qty, price: price, total: qty * price));
      _nameCtrl.clear();
    });
  }

  void _saveToLibrary() async {
    if (_items.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حفظ في المكتبة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم العميل'),
                  style: GoogleFonts.cairo(),
                ),
                TextField(
                  controller: _customerPhoneCtrl,
                  decoration: const InputDecoration(labelText: 'رقم التليفون'),
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.cairo(),
                ),
                TextField(
                  controller: _customerAddressCtrl,
                  decoration: const InputDecoration(labelText: 'عنوان العميل'),
                  style: GoogleFonts.cairo(),
                ),
                TextField(
                  controller: _paidAmountCtrl,
                  decoration: const InputDecoration(labelText: 'المبلغ المدفوع (العربون)', suffixText: 'ج'),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(),
                ),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
                  maxLines: 2,
                  style: GoogleFonts.cairo(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white),
              onPressed: () async {
                final name = _customerNameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final record = CustomerRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerName: name,
                    phoneNumber: _customerPhoneCtrl.text.trim(),
                    address: _customerAddressCtrl.text.trim(),
                    paidAmount: double.tryParse(_paidAmountCtrl.text) ?? 0,
                    notes: _notesCtrl.text.trim(),
                    date: DateTime.now(),
                    items: List.from(_items),
                  );
                  await StorageService.saveRecord(record);
                  _customerNameCtrl.clear();
                  _customerPhoneCtrl.clear();
                  _customerAddressCtrl.clear();
                  _paidAmountCtrl.clear();
                  _notesCtrl.clear();
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم الحفظ بنجاح', style: GoogleFonts.cairo()),
                      backgroundColor: Colors.green,
                    ));
                  }
                }
              },
              child: Text('حفظ الآن', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        title: Text('حاسبة المقاولات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_shared),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LibraryPage())),
            tooltip: 'مكتبة العملاء',
          )
        ],
      ),
      drawer: Drawer(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF1D9E75)),
                child: Center(
                  child: Text(
                    'القائمة الرئيسية',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calculate, color: Color(0xFF1D9E75)),
                title: Text('حاسبة المقاسات', style: GoogleFonts.cairo()),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.architecture, color: Color(0xFF1D9E75)),
                title: Text('تصميم مطبخ 3D', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const KitchenDesignerPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_special, color: Color(0xFF1D9E75)),
                title: Text('مكتبة العملاء', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LibraryPage()));
                },
              ),
            ],
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ModeToggle(mode: _mode, onChanged: (m) { setState(() => _mode = m); _calc(); }),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(icon: Icons.straighten, label: 'أدخل القياسات'),
                    const SizedBox(height: 12),
                    if (_mode == 'sqm') ...[
                      Row(
                        children: [
                          Expanded(child: NumField(label: 'الطول (م)', ctrl: _lengthCtrl, onChanged: (_) => _calc())),
                          const SizedBox(width: 12),
                          Expanded(child: NumField(label: 'العرض (م)', ctrl: _widthCtrl, onChanged: (_) => _calc())),
                        ],
                      ),
                    ] else ...[
                      NumField(label: 'الطول (م.ط)', ctrl: _linearCtrl, onChanged: (_) => _calc()),
                    ],
                    const SizedBox(height: 12),
                    NumField(label: _mode == 'sqm' ? 'السعر (ج / م²)' : 'السعر (ج / م.ط)', ctrl: _priceCtrl, onChanged: (_) => _calc()),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    if (_mode == 'sqm') ...[
                      Row(
                        children: [
                          Expanded(child: ResultTile(label: 'المساحة', value: _sqm.toStringAsFixed(2), unit: 'م²')),
                          const SizedBox(width: 10),
                          Expanded(child: ResultTile(label: 'المحيط', value: _perimeter.toStringAsFixed(2), unit: 'م.خ')),
                        ],
                      ),
                    ] else ...[
                      ResultTile(label: 'الطول الطولي', value: _lm.toStringAsFixed(2), unit: 'م.ط'),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(color: const Color(0xFF1D9E75), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Text('إجمالي البند الحالي', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('${_fmt(_total)} جنيه', style: GoogleFonts.cairo(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم البند (اختياري)',
                        hintText: 'مثال: مطبخ، شباك، غرفة...',
                        hintStyle: GoogleFonts.cairo(fontSize: 13),
                        labelStyle: GoogleFonts.cairo(),
                      ),
                      style: GoogleFonts.cairo(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: Text('أضف للقائمة', style: GoogleFonts.cairo(fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D9E75),
                          side: const BorderSide(color: Color(0xFF1D9E75), width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionTitle(icon: Icons.list_alt, label: 'قائمة البنود'),
                        if (_items.isNotEmpty)
                          TextButton.icon(
                            onPressed: _saveToLibrary,
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: Text('حفظ الكل', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF1D9E75)),
                          )
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('القائمة فارغة', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13))))
                    else ...[
                      ...List.generate(_items.length, (i) {
                        final it = _items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it.name, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500)),
                                    Text('${it.detail} × ${_fmt(it.price)} ج', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Text('${_fmt(it.total)} ج', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1D9E75))),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _items.removeAt(i))),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي الكلي', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('${_fmt(_items.fold(0, (sum, item) => sum + item.total))} جنيه', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1D9E75))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
