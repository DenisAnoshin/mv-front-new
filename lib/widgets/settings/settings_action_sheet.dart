import 'package:flutter/cupertino.dart';

class SettingsOption<T> {
  final T value;
  final String label;
  final bool destructive;
  const SettingsOption({required this.value, required this.label, this.destructive = false});
}

Future<T?> showSettingsOptionsSheet<T>({
  required BuildContext context,
  required String title,
  required List<SettingsOption<T>> options,
  T? selected,
  String cancelText = 'Отмена',
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final opt in options)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(opt.value),
            isDefaultAction: selected != null && selected == opt.value,
            isDestructiveAction: opt.destructive,
            child: Text(opt.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(cancelText),
      ),
    ),
  );
} 