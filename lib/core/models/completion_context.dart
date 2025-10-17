/// Data model representing the context of a completed reminder
/// Used to display contextual information in the completion celebration screen
class CompletionContext {
  final String reminderTitle;
  final String reminderCategory;
  final DateTime completionTime;
  final String? completionNotes;
  final int? reminderId;
  final Duration? actualDuration;

  const CompletionContext({
    required this.reminderTitle,
    required this.reminderCategory,
    required this.completionTime,
    this.completionNotes,
    this.reminderId,
    this.actualDuration,
  });

  /// Factory constructor to create CompletionContext from a reminder map
  factory CompletionContext.fromReminder(Map<String, dynamic> reminder) {
    return CompletionContext(
      reminderTitle: reminder['title'] ?? reminder['name'] ?? 'Reminder',
      reminderCategory: reminder['category'] ?? reminder['type'] ?? 'General',
      completionTime: DateTime.now(),
      completionNotes: reminder['notes'],
      reminderId: reminder['id'],
      actualDuration: reminder['duration'] != null 
          ? Duration(minutes: reminder['duration']) 
          : null,
    );
  }

  /// Factory constructor to create CompletionContext from navigation arguments
  factory CompletionContext.fromNavigation(Map<String, dynamic> args) {
    return CompletionContext(
      reminderTitle: args['reminderTitle'] ?? args['title'] ?? 'Reminder',
      reminderCategory: args['reminderCategory'] ?? args['category'] ?? 'General',
      completionTime: args['completionTime'] != null 
          ? DateTime.parse(args['completionTime']) 
          : DateTime.now(),
      completionNotes: args['completionNotes'],
      reminderId: args['reminderId'],
      actualDuration: args['actualDuration'] != null 
          ? Duration(milliseconds: args['actualDuration']) 
          : null,
    );
  }

  /// Factory constructor to create a default CompletionContext when no data is available
  factory CompletionContext.defaultContext() {
    return CompletionContext(
      reminderTitle: 'Your Achievement',
      reminderCategory: 'General',
      completionTime: DateTime.now(),
    );
  }

  /// Convert CompletionContext to a map for navigation or storage
  Map<String, dynamic> toMap() {
    return {
      'reminderTitle': reminderTitle,
      'reminderCategory': reminderCategory,
      'completionTime': completionTime.toIso8601String(),
      'completionNotes': completionNotes,
      'reminderId': reminderId,
      'actualDuration': actualDuration?.inMilliseconds,
    };
  }

  /// Create a copy of this CompletionContext with updated values
  CompletionContext copyWith({
    String? reminderTitle,
    String? reminderCategory,
    DateTime? completionTime,
    String? completionNotes,
    int? reminderId,
    Duration? actualDuration,
  }) {
    return CompletionContext(
      reminderTitle: reminderTitle ?? this.reminderTitle,
      reminderCategory: reminderCategory ?? this.reminderCategory,
      completionTime: completionTime ?? this.completionTime,
      completionNotes: completionNotes ?? this.completionNotes,
      reminderId: reminderId ?? this.reminderId,
      actualDuration: actualDuration ?? this.actualDuration,
    );
  }

  /// Check if this context has complete information
  bool get hasCompleteInfo {
    return reminderTitle.isNotEmpty && 
           reminderCategory.isNotEmpty;
  }

  /// Get a formatted completion time string
  String get formattedCompletionTime {
    final now = DateTime.now();
    final difference = now.difference(completionTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CompletionContext &&
        other.reminderTitle == reminderTitle &&
        other.reminderCategory == reminderCategory &&
        other.completionTime == completionTime &&
        other.completionNotes == completionNotes &&
        other.reminderId == reminderId &&
        other.actualDuration == actualDuration;
  }

  @override
  int get hashCode {
    return reminderTitle.hashCode ^
        reminderCategory.hashCode ^
        completionTime.hashCode ^
        completionNotes.hashCode ^
        reminderId.hashCode ^
        actualDuration.hashCode;
  }

  @override
  String toString() {
    return 'CompletionContext(reminderTitle: $reminderTitle, reminderCategory: $reminderCategory, completionTime: $completionTime, completionNotes: $completionNotes, reminderId: $reminderId, actualDuration: $actualDuration)';
  }
}