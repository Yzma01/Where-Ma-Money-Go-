enum NotePriority { none, low, medium, high }

extension NotePriorityExt on NotePriority {
  String get label {
    switch (this) {
      case NotePriority.none:
        return 'Sin prioridad';
      case NotePriority.low:
        return 'Baja';
      case NotePriority.medium:
        return 'Media';
      case NotePriority.high:
        return 'Alta';
    }
  }

  String get emoji {
    switch (this) {
      case NotePriority.none:
        return '';
      case NotePriority.low:
        return '🟢';
      case NotePriority.medium:
        return '🟡';
      case NotePriority.high:
        return '🔴';
    }
  }

  static NotePriority fromInt(int? v) {
    switch (v) {
      case 1:
        return NotePriority.low;
      case 2:
        return NotePriority.medium;
      case 3:
        return NotePriority.high;
      default:
        return NotePriority.none;
    }
  }

  int get value {
    switch (this) {
      case NotePriority.none:
        return 0;
      case NotePriority.low:
        return 1;
      case NotePriority.medium:
        return 2;
      case NotePriority.high:
        return 3;
    }
  }
}
