import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/phone_utils.dart';
import 'package:vyzi/core/widgets/phone_filled.dart';


class RequestCallBackScreen extends StatefulWidget {
  const RequestCallBackScreen({super.key});

  @override
  State<RequestCallBackScreen> createState() => _RequestCallBackScreenState();
}

class _RequestCallBackScreenState extends State<RequestCallBackScreen> {
  // ── Design Tokens ──
  static const _textDark = Color(0xFF1A1A2E);
  static const _textMid = Color(0xFF636E72);
  static const _bg = Colors.white;
  static const _inputBg = Color(0xFFF4F5F7);
  static const _infoBg = Color(0xFFEEEAFB);
  static const _infoText = Color(0xFF9400D3);
  static const _btnBg = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFFE8E8E8);

  static const _timeSlotKeys = [
    'support.callback.morning',
    'support.callback.afternoon',
    'support.callback.evening',
  ];

  final _phoneCtrl = TextEditingController();
  String _phoneDialCode = '+39';
  String? _selectedTime;
  bool _dropdownOpen = false;
  final _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_dropdownOpen) {
      _removeOverlay();
      setState(() => _dropdownOpen = false);
    } else {
      _showDropdown();
      setState(() => _dropdownOpen = true);
    }
  }

  void _showDropdown() {
    final renderBox =
    _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
          setState(() => _dropdownOpen = false);
        },
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 4,
              width: size.width,
              child: _DropdownMenu(
                items: _timeSlotKeys,
                selectedItem: _selectedTime,
                onSelect: (val) {
                  setState(() {
                    _selectedTime = val;
                    _dropdownOpen = false;
                  });
                  _removeOverlay();
                },
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'support.callback.intro_text'.tr,
              style: const TextStyle(
                color: _textMid,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),

            // ── Phone Number ──
            PhoneTextField(
              labelText: 'support.callback.phone_label'.tr,
              controller: _phoneCtrl,
              hintText: 'support.callback.phone_hint'.tr,
              validator: validatePhone,
              externalLabel: true,
              fillColor: _inputBg,
              borderRadius: 10,
              showBorder: false,
              labelStyle: const TextStyle(
                color: _textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              onCountryChanged: (CountryCode code) {
                _phoneDialCode = code.dialCode ?? '+39';
              },
            ),
            const SizedBox(height: 20),

            // ── Preferred Time Slot ──
            Text('support.callback.time_slot_label'.tr,
                style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              key: _dropdownKey,
              onTap: _toggleDropdown,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: _dropdownOpen
                      ? const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  )
                      : BorderRadius.circular(10),
                  border: _dropdownOpen
                      ? Border.all(color: const Color(0xFF9400D3), width: 1.5)
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTime?.tr ?? 'support.callback.select_time'.tr,
                      style: TextStyle(
                        color: _selectedTime != null
                            ? _textDark
                            : const Color(0xFFB2BEC3),
                        fontSize: 14,
                        fontWeight: _selectedTime != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _dropdownOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFFB2BEC3), size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Note Box ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _infoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'support.callback.note'.tr,
                style: const TextStyle(
                  color: _infoText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnBg,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('support.callback.request_button'.tr,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E), size: 22),
        ),
      ),
      title: Text(
        'support.callback.title'.tr,
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Dropdown Menu Widget (Overlay)
// ─────────────────────────────────────────────
class _DropdownMenu extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelect;

  const _DropdownMenu({
    required this.items,
    required this.selectedItem,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = item == selectedItem;
            final isLast = i == items.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: () => onSelect(item),
                  borderRadius: i == 0
                      ? const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4))
                      : isLast
                      ? const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12))
                      : BorderRadius.zero,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD6E4FF)
                          : Colors.transparent,
                    ),
                    child: Text(
                      item.tr,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF2D3436)
                            : const Color(0xFF2D3436),
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFD0D8F8),
                      indent: 18,
                      endIndent: 18),
              ],
            );
          }),
        ),
      ),
    );
  }
}

