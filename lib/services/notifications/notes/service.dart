import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/recurrent.dart';
import 'package:where_ma_money_go/models/note_priority.dart';

/// Servicio centralizado de notificaciones locales para notas y recurrentes.
///
/// Canales:
///   - "due_soon"      → recordatorios de vencimiento (notas con dueDate)
///   - "recurrent"     → pagos recurrentes que se acercan
///   - "reactivated"   → recurrente que pasó de Pagado → Pendiente
///
/// IDs de notificación:
///   Los IDs son enteros derivados del hash del note.id para ser únicos y
///   reproducibles (cancelar / reprogramar sin colisiones).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Inicialización ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canales Android
    await _createChannels();

    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'due_soon',
        'Vencimientos de notas',
        description: 'Recordatorios para notas con fecha de vencimiento',
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'recurrent',
        'Pagos recurrentes',
        description: 'Recordatorios de pagos fijos próximos',
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'reactivated',
        'Pagos reactivados',
        description:
            'Notificación cuando un pago recurrente vuelve a estar pendiente',
        importance: Importance.defaultImportance,
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Extensión futura: navegar a la nota por payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ─── Pedir permisos (Android 13+) ─────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool granted = true;
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return granted;
  }

  // ─── Programar / cancelar por nota ────────────────────────────────────────

  /// Reprograma todas las notificaciones de [note].
  /// Cancela las anteriores primero para evitar duplicados.
  Future<void> scheduleForNote(Note note) async {
    await cancelForNote(note.id);

    if (note.isRecurrent) {
      await _scheduleRecurrent(note);
    } else {
      await _scheduleDueSoon(note);
    }
  }

  /// Cancela todas las notificaciones asociadas a [noteId].
  Future<void> cancelForNote(String noteId) async {
    await _plugin.cancel(_dueSoonId(noteId));
    await _plugin.cancel(_recurrentReminderId(noteId));
  }

  /// Cancela y dispara inmediatamente la notificación de "reactivado".
  Future<void> notifyReactivated(Note note) async {
    await _plugin.show(
      _reactivatedId(note.id),
      '🔔 Pago pendiente: ${note.title}',
      note.bill != null
          ? 'Vence pronto · \u20a1${note.bill!.amount.toStringAsFixed(0)}'
          : 'Es momento de registrar este pago recurrente',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reactivated',
          'Pagos reactivados',
          channelDescription:
              'Notificación cuando un pago recurrente vuelve a estar pendiente',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: note.id,
    );
  }

  // ─── Reprogramar lista completa ────────────────────────────────────────────

  /// Llama esto al cargar las notas para sincronizar todas las notificaciones.
  Future<void> syncAll(List<Note> notes) async {
    for (final note in notes) {
      // Solo reprogramar notas activas (no completadas)
      if (note.isCompleted) {
        await cancelForNote(note.id);
      } else {
        await scheduleForNote(note);
      }
    }
  }

  // ─── Lógica interna ────────────────────────────────────────────────────────

  /// Notificación para nota regular con dueDate: dispara 1 día antes a las 9am.
  Future<void> _scheduleDueSoon(Note note) async {
    if (!note.hasDueDate || note.dueDate == null) return;

    final dueDate = note.dueDate!;
    final notifyAt = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1, // 1 día antes
      9,
      0,
    );

    if (notifyAt.isBefore(DateTime.now())) return; // ya pasó

    final tzNotifyAt = tz.TZDateTime.from(notifyAt, tz.local);
    final priorityLabel = note.priority.label.isNotEmpty
        ? ' [${note.priority.emoji} ${note.priority.label}]'
        : '';

    await _plugin.zonedSchedule(
      _dueSoonId(note.id),
      '⏰ Vence mañana: ${note.title}$priorityLabel',
      note.content.isNotEmpty
          ? note.content
          : 'Revisa esta nota antes de que venza',
      tzNotifyAt,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'due_soon',
          'Vencimientos de notas',
          channelDescription:
              'Recordatorios para notas con fecha de vencimiento',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: note.id,
    );
  }

  /// Notificación para nota recurrente: dispara `leadDays` antes del nextDueDate a las 8am.
  Future<void> _scheduleRecurrent(Note note) async {
    final recurrent = note.recurrent;
    if (recurrent == null || recurrent.nextDueDate == null) return;

    final nextDue = recurrent.nextDueDate!;
    final lead = Recurrent.leadDays(recurrent.frequency);

    // Para frecuencia diaria no programamos (lead=0, sería ruido)
    if (recurrent.frequency == 'daily') return;

    final notifyAt = DateTime(
      nextDue.year,
      nextDue.month,
      nextDue.day - lead,
      8,
      0,
    );

    if (notifyAt.isBefore(DateTime.now())) return;

    final tzNotifyAt = tz.TZDateTime.from(notifyAt, tz.local);
    final amountLabel = note.bill != null
        ? ' · \u20a1${note.bill!.amount.toStringAsFixed(0)}'
        : '';
    final freqLabel = _freqLabel(recurrent.frequency);

    await _plugin.zonedSchedule(
      _recurrentReminderId(note.id),
      '💳 Pago próximo: ${note.title}',
      'Vence en $lead días ($freqLabel)$amountLabel',
      tzNotifyAt,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'recurrent',
          'Pagos recurrentes',
          channelDescription: 'Recordatorios de pagos fijos próximos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: note.id,
    );
  }

  // ─── Helpers de ID ────────────────────────────────────────────────────────

  /// IDs únicos por tipo. Usa los primeros 28 bits del hashCode para evitar
  /// colisiones entre tipos distintos del mismo noteId.
  int _dueSoonId(String noteId) => _stableId(noteId, 0);
  int _recurrentReminderId(String noteId) => _stableId(noteId, 1);
  int _reactivatedId(String noteId) => _stableId(noteId, 2);

  int _stableId(String noteId, int slot) {
    // Toma los 28 bits bajos del hashCode y añade el slot en los 2 bits altos
    final base = noteId.hashCode & 0x0FFFFFFF;
    return (slot << 28) | base;
  }

  String _freqLabel(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'semanal';
      case 'monthly':
        return 'mensual';
      case 'yearly':
        return 'anual';
      default:
        return frequency;
    }
  }
}
