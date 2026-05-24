import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer_record.dart';
import '../services/storage_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<CustomerRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final data = await StorageService.loadRecords();
    setState(() {
      _records = data.reversed.toList(); // الأحدث أولاً
      _loading = false;
    });
  }

  void _delete(String id) async {
    await StorageService.deleteRecord(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('مكتبة العملاء', style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
            : _records.isEmpty
            ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('لا يوجد سجلات محفوظة حالياً', style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _records.length,
          itemBuilder: (c, i) {
            final r = _records[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(r.customerName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF2E3E5C))),
                subtitle: Text('${r.date.day}/${r.date.month}/${r.date.year}  •  الإجمالي: ${r.totalAmount.toStringAsFixed(0)} ج', style: GoogleFonts.cairo(fontSize: 12)),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _delete(r.id)),
                onTap: () => _showDetails(r),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDetails(CustomerRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('تفاصيل: ${record.customerName}', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(c);
                          _showEditDialog(record);
                        },
                      ),
                      IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)),
                    ],
                  ),
                ],
              ),
              Text('تاريخ الحفظ: ${record.date.day}/${record.date.month}/${record.date.year}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
              if (record.phoneNumber.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(record.phoneNumber, style: GoogleFonts.cairo(fontSize: 14)),
                    ],
                  ),
                ),
              if (record.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(record.address, style: GoogleFonts.cairo(fontSize: 14))),
                    ],
                  ),
                ),
              if (record.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text('ملاحظات: ${record.notes}', style: GoogleFonts.cairo(fontSize: 13, color: Colors.orange.shade900))),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 30),
              Expanded(
                child: ListView.separated(
                  itemCount: record.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final it = record.items[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.name, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(it.detail, style: GoogleFonts.cairo(fontSize: 12)),
                      trailing: Text('${it.total.toStringAsFixed(0)} ج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF1D9E75))),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1D9E75).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الإجمالي:', style: GoogleFonts.cairo(fontSize: 14)),
                        Text('${record.totalAmount.toStringAsFixed(0)} ج', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('المدفوع (العربون):', style: GoogleFonts.cairo(fontSize: 14, color: Colors.blue.shade700)),
                        Text('${record.paidAmount.toStringAsFixed(0)} ج', style: GoogleFonts.cairo(fontSize: 16, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('المتبقي:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                        Text('${record.remainingAmount.toStringAsFixed(0)} جنيه', style: GoogleFonts.cairo(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(CustomerRecord record) {
    final paidCtrl = TextEditingController(text: record.paidAmount.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: record.notes);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل البيانات المادية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: paidCtrl,
                  decoration: const InputDecoration(labelText: 'المبلغ المدفوع (العربون)', suffixText: 'ج'),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'الملاحظات'),
                  maxLines: 3,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 15),
                Text('ملاحظة: لتعديل المقاسات، يفضل عمل فاتورة جديدة أو حذف هذا السجل.', 
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white),
              onPressed: () async {
                final updatedRecord = CustomerRecord(
                  id: record.id,
                  customerName: record.customerName,
                  phoneNumber: record.phoneNumber,
                  address: record.address,
                  paidAmount: double.tryParse(paidCtrl.text) ?? 0,
                  notes: notesCtrl.text,
                  date: record.date,
                  items: record.items,
                );
                await StorageService.saveRecord(updatedRecord);
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم تحديث البيانات بنجاح', style: GoogleFonts.cairo()),
                  backgroundColor: Colors.blue,
                ));
              },
              child: Text('تحديث الآن', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}
