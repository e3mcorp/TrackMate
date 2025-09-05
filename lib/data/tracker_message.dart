/// Direction of a SMS exchanged with a tracker.
enum MessageDirection {
  SENT,
  RECEIVED
}

/// Message received or sent by the tracker
class TrackerMessage {
  /// ID of the tracker message
  int id = -1;

  /// Timestamp of the message
  DateTime timestamp;

  /// Direction of the message
  MessageDirection direction;

  /// The content of the message
  String data;

  TrackerMessage(this.direction, this.data, this.timestamp);

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'direction': direction.name,
      'data': data,
    };
  }

  /// Create from Map for database loading
  factory TrackerMessage.fromMap(Map<String, dynamic> map) {
    return TrackerMessage(
      MessageDirection.values.firstWhere(
            (e) => e.name == map['direction'],
        orElse: () => MessageDirection.RECEIVED,
      ),
      map['data'] ?? '',
      DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    )..id = map['id'] ?? -1;
  }

  /// Create a copy of this message
  TrackerMessage copyWith({
    int? id,
    DateTime? timestamp,
    MessageDirection? direction,
    String? data,
  }) {
    return TrackerMessage(
      direction ?? this.direction,
      data ?? this.data,
      timestamp ?? this.timestamp,
    )..id = id ?? this.id;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackerMessage &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.direction == direction &&
        other.data == data;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    timestamp.hashCode ^
    direction.hashCode ^
    data.hashCode;
  }

  @override
  String toString() {
    return 'TrackerMessage{id: $id, timestamp: $timestamp, direction: $direction, data: $data}';
  }
}
