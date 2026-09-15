enum KrevzyPaymentStatus {
  draft,
  processing,
  success,
  pending,
  failed,
  cancelled,
}

class KrevzyPayment {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String receiverName;
  final double amount;
  final String currency;
  final KrevzyPaymentStatus status;
  final String note;
  final String transactionRef;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const KrevzyPayment({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.note = '',
    required this.transactionRef,
    required this.createdAt,
    this.updatedAt,
  });

  KrevzyPayment copyWith({
    KrevzyPaymentStatus? status,
    DateTime? updatedAt,
  }) {
    return KrevzyPayment(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      receiverName: receiverName,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      note: note,
      transactionRef: transactionRef,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'note': note,
      'transactionRef': transactionRef,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory KrevzyPayment.fromFirestore(
    Map<String, dynamic> data,
  ) {
    final statusString = data['status']?.toString() ?? 'pending';

    final status = KrevzyPaymentStatus.values.firstWhere(
      (value) => value.name == statusString,
      orElse: () => KrevzyPaymentStatus.pending,
    );

    final amountRaw = data['amount'];

    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '') ?? 0.0;

    return KrevzyPayment(
      id: data['id']?.toString() ?? '',
      chatId: data['chatId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      receiverName: data['receiverName']?.toString() ?? '',
      amount: amount,
      currency: data['currency']?.toString() ?? 'INR',
      status: status,
      note: data['note']?.toString() ?? '',
      transactionRef: data['transactionRef']?.toString() ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readNullableDate(data['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    try {
      // Works with Firestore Timestamp without importing Firestore here.
      final date = value.toDate();

      if (date is DateTime) {
        return date;
      }
    } catch (_) {}

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  static DateTime? _readNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final date = value.toDate();

      if (date is DateTime) {
        return date;
      }
    } catch (_) {}

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}