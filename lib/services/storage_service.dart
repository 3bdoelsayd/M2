import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_record.dart';
import '../models/kitchen_design.dart';

class StorageService {
  static const String _customerKey = 'customer_records';
  static const String _kitchenKey = 'kitchen_designs_map';

  // --- حفظ سجلات العملاء ---
  static Future<void> saveRecord(CustomerRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CustomerRecord> records = await loadRecords();
    final int existingIndex = records.indexWhere((r) => r.id == record.id);
    if (existingIndex != -1) {
      records[existingIndex] = record;
    } else {
      records.add(record);
    }
    final String encoded = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_customerKey, encoded);
  }

  static Future<List<CustomerRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_customerKey);
    if (encoded == null) return [];
    try {
      final List decoded = jsonDecode(encoded);
      return decoded.map((e) => CustomerRecord.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CustomerRecord> records = await loadRecords();
    records.removeWhere((element) => element.id == id);
    final String encoded = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_customerKey, encoded);
  }

  // --- حفظ وحذف تصاميم المطابخ ---
  static Future<void> saveKitchenDesign(String name, List<KitchenComponent> components) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_kitchenKey);
    Map<String, dynamic> designs = encoded != null ? jsonDecode(encoded) : {};
    designs[name] = components.map((e) => e.toJson()).toList();
    await prefs.setString(_kitchenKey, jsonEncode(designs));
  }

  static Future<void> deleteKitchenDesign(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_kitchenKey);
    if (encoded != null) {
      Map<String, dynamic> designs = jsonDecode(encoded);
      designs.remove(name);
      await prefs.setString(_kitchenKey, jsonEncode(designs));
    }
  }

  static Future<List<KitchenComponent>?> loadKitchenDesign(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_kitchenKey);
    if (encoded == null) return null;
    try {
      Map<String, dynamic> designs = jsonDecode(encoded);
      if (designs.containsKey(name)) {
        return (designs[name] as List).map((e) => KitchenComponent.fromJson(e)).toList();
      }
    } catch (e) {}
    return null;
  }

  static Future<List<String>> getAllDesignNames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_kitchenKey);
    if (encoded == null) return [];
    try {
      Map<String, dynamic> designs = jsonDecode(encoded);
      return designs.keys.where((key) => key != "last_work").toList();
    } catch (e) {
      return [];
    }
  }
}
