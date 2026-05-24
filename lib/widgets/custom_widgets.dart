import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;
  const ModeToggle({super.key, required this.mode, required this.onChanged});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'متر مربع (م²)', 
            active: mode == 'sqm', 
            onTap: () => onChanged('sqm'),
          ),
          _ToggleBtn(
            label: 'متر طولي (م.ط)', 
            active: mode == 'lm', 
            onTap: () => onChanged('lm'),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1D9E75) : Colors.transparent, 
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.cairo(
              fontSize: 14, 
              fontWeight: FontWeight.w500, 
              color: active ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final Widget child;
  const CustomCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ), 
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const SectionTitle({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1D9E75)), 
        const SizedBox(width: 6), 
        Text(
          label, 
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class NumField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const NumField({super.key, required this.label, required this.ctrl, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: GoogleFonts.cairo(fontSize: 13),
      ),
      style: GoogleFonts.cairo(fontSize: 16),
    );
  }
}

class ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const ResultTile({super.key, required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w600)),
          Text(unit, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
