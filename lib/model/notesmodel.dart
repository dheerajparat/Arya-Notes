class NotesModel {
  final String id;
  final String title;
  final String content;
  final String date;
  final String time;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSyncedWithFirebase;

  NotesModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.time,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSyncedWithFirebase = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  NotesModel copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? time,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSyncedWithFirebase,
  }) {
    return NotesModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSyncedWithFirebase: isSyncedWithFirebase ?? this.isSyncedWithFirebase,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'time': time,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSyncedWithFirebase': isSyncedWithFirebase,
    };
  }

  factory NotesModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return NotesModel(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      time: (map['time'] ?? '') as String,
      createdAt: _parseDateTime(map['createdAt'], fallback: now),
      updatedAt: _parseDateTime(map['updatedAt'], fallback: now),
      isSyncedWithFirebase: map['isSyncedWithFirebase'] as bool? ?? true,
    );
  }

  static DateTime _parseDateTime(dynamic value, {required DateTime fallback}) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? fallback;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    try {
      final dynamic dynamicValue = value;
      final DateTime parsed = dynamicValue.toDate() as DateTime;
      return parsed;
    } catch (_) {
      return fallback;
    }
  }
}
