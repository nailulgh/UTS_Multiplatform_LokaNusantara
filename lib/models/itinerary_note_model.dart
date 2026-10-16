class ItineraryNoteModel {
  final String destinationId;
  final String destinationName;
  final String plannedDate;
  final String noteText;
  final String updatedAt;

  const ItineraryNoteModel({
    required this.destinationId,
    required this.destinationName,
    required this.plannedDate,
    required this.noteText,
    required this.updatedAt,
  });

  factory ItineraryNoteModel.fromJson(Map<String, dynamic> json) {
    return ItineraryNoteModel(
      destinationId: json['destination_id'] as String? ?? '',
      destinationName: json['destination_name'] as String? ?? '',
      plannedDate: json['planned_date'] as String? ?? '-',
      noteText: json['note_text'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination_id': destinationId,
      'destination_name': destinationName,
      'planned_date': plannedDate,
      'note_text': noteText,
      'updated_at': updatedAt,
    };
  }

  ItineraryNoteModel copyWith({
    String? destinationId,
    String? destinationName,
    String? plannedDate,
    String? noteText,
    String? updatedAt,
  }) {
    return ItineraryNoteModel(
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      plannedDate: plannedDate ?? this.plannedDate,
      noteText: noteText ?? this.noteText,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
