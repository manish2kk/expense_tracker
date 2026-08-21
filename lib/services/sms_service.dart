import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/bank_transaction.dart';
import 'sms_parser.dart';

enum SmsAccessState { unsupported, denied, granted }

class SmsReadResult {
  const SmsReadResult({
    required this.state,
    required this.transactions,
  });

  final SmsAccessState state;
  final List<BankTransaction> transactions;
}

class SmsService {
  SmsService({SmsQuery? query}) : _query = query ?? SmsQuery();

  final SmsQuery _query;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<SmsReadResult> readBankSms() async {
    if (!isSupported) {
      return const SmsReadResult(
        state: SmsAccessState.unsupported,
        transactions: [],
      );
    }

    final status = await Permission.sms.request();
    if (!status.isGranted) {
      return const SmsReadResult(
        state: SmsAccessState.denied,
        transactions: [],
      );
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 2000,
    );

    final transactions = <BankTransaction>[];
    for (final message in messages) {
      final body = message.body;
      final date = message.date;
      if (body == null || date == null || !SmsParser.isAllowedSender(message.address)) {
        continue;
      }
      final parsed = SmsParser.parse(
        body: body,
        date: date,
        sender: message.address,
      );
      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return SmsReadResult(
      state: SmsAccessState.granted,
      transactions: transactions,
    );
  }
}
