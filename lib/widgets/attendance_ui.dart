import 'package:flutter/material.dart';

class AttendanceUI {
  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color darkNavy = Color(0xFF052B52);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color green = Color(0xFF159957);
  static const Color orange = Color(0xFFF39A23);
  static const Color red = Color(0xFFE94B4B);
  static const Color background = Color(0xFFF6F9FC);

  static const Color textDark = Color(0xFF102A43);
  static const Color textGrey = Color(0xFF6B7C93);
  static const Color border = Color(0xFFE4ECF3);

  static const double radius = 14;

  static BoxDecoration cardDecoration({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  static TextStyle title = const TextStyle(
    color: darkNavy,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle sectionTitle = const TextStyle(
    color: darkNavy,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static TextStyle body = const TextStyle(
    color: textGrey,
    fontSize: 12,
  );

  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: primaryBlue,
        size: 20,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),
    );
  }

  static Widget backButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new,
        size: 20,
        color: darkNavy,
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  static Widget dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    String Function(T)? labelBuilder,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: inputDecoration(
        label: label,
        icon: icon,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            labelBuilder == null
                ? item.toString()
                : labelBuilder(item),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  static Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = primaryBlue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: body,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: textGrey,
            ),
          ],
        ),
      ),
    );
  }
}