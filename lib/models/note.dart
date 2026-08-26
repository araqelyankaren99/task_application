import 'package:flutter/foundation.dart';

/// A single note. Title and body are always plain strings — this app has
/// no rich text or markdown model anywhere, by design.
@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a brand-new note with a timestamp-based id.
  factory Note.create({String title = '', String body = ''}) {
    final now = DateTime.now();
    return Note(
      id: '${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String title;
  final String body;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A note with no title and no body — nothing worth persisting.
  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  Note copyWith({
    String? title,
    String? body,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == id &&
          other.title == title &&
          other.body == body &&
          other.isFavorite == isFavorite &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode =>
      Object.hash(id, title, body, isFavorite, createdAt, updatedAt);
}
