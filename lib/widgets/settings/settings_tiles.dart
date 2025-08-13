import 'package:flutter/material.dart';

enum SettingsTilePosition { single, first, middle, last }

BorderRadius _radiusFor(SettingsTilePosition position) {
  const double r = 18;
  switch (position) {
    case SettingsTilePosition.single:
      return BorderRadius.circular(r);
    case SettingsTilePosition.first:
      return const BorderRadius.only(topLeft: Radius.circular(r), topRight: Radius.circular(r));
    case SettingsTilePosition.middle:
      return BorderRadius.zero;
    case SettingsTilePosition.last:
      return const BorderRadius.only(bottomLeft: Radius.circular(r), bottomRight: Radius.circular(r));
  }
}

class SettingsNavTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SettingsTilePosition position;
  const SettingsNavTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailingText,
    this.trailing,
    this.onTap,
    this.position = SettingsTilePosition.middle,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = _radiusFor(position);
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return const Color(0x14000000);
          }
          return null;
        },
      ),
      child: ListTile(
        leading: leadingIcon != null ? Icon(leadingIcon, color: Colors.black87) : null,
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(subtitle!, style: const TextStyle(color: Color(0xFF8E8E93))),
              ),
        trailing: trailing ?? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(trailingText!, style: const TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
              ),
            const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
          ],
        ),
        dense: true,
        isThreeLine: subtitle != null,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final SettingsTilePosition position;
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.position = SettingsTilePosition.middle,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = _radiusFor(position);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: borderRadius,
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return const Color(0x14000000);
          }
          return null;
        },
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.25)),
            ],
          ],
        ),
        activeColor: const Color(0xFF0A84FF),
      ),
    );
  }
}

class SettingsLeadingSwitchRow extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final SettingsTilePosition position;
  const SettingsLeadingSwitchRow({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.position = SettingsTilePosition.middle,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = _radiusFor(position);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: borderRadius,
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return const Color(0x14000000);
          }
          return null;
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(leadingIcon, color: Colors.black87),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(color: Color(0xFF8E8E93))),
                  ],
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF0A84FF)),
          ],
        ),
      ),
    );
  }
} 