import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<double?> showSetBalanceDialog(BuildContext context, {double? current}) {
  final controller = TextEditingController(
    text: current == null ? '' : current.toStringAsFixed(2),
  );

  return showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Current bank balance'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: 'Enter amount',
            helperText: 'Monthly balance is calculated from this amount.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null) {
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
