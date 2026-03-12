import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/blocs/envelop/envelop_bloc.dart';
import 'package:where_ma_money_go/blocs/envelop/envelop_event.dart';
import 'package:where_ma_money_go/blocs/envelop/envelop_state.dart';
import 'package:where_ma_money_go/models/envelop.dart';
import 'package:where_ma_money_go/models/envelop_transaction.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

class DigitalEnvelopScreen extends StatefulWidget {
  const DigitalEnvelopScreen({super.key});

  @override
  State<DigitalEnvelopScreen> createState() => _DigitalEnvelopScreenState();
}

class _DigitalEnvelopScreenState extends State<DigitalEnvelopScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EnvelopBloc>().add(LoadEnvelops());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<EnvelopBloc, EnvelopState>(
          builder: (context, state) {
            if (state is EnvelopLoading || state is EnvelopInitial) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.primary,
                ),
              );
            }
            if (state is EnvelopError) {
              return _ErrorView(
                colors: colors,
                message: state.message,
                onRetry: () => context.read<EnvelopBloc>().add(LoadEnvelops()),
              );
            }

            final envelops = state is EnvelopLoaded
                ? state.envelops
                : <Envelop>[];
            final totalInSobres = envelops.fold<double>(
              0,
              (s, e) => s + e.amount,
            );

            return Column(
              children: [
                _Header(
                  colors: colors,
                  total: totalInSobres,
                  onAdd: () => _openCreateSheet(context, colors),
                ),
                Expanded(
                  child: envelops.isEmpty
                      ? _EmptyState(
                          colors: colors,
                          onAdd: () => _openCreateSheet(context, colors),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: envelops.length,
                          itemBuilder: (_, i) => _EnvelopCard(
                            envelop: envelops[i],
                            colors: colors,
                            onDeposit: () => _openTransactionSheet(
                              context,
                              colors,
                              envelops[i],
                              isDeposit: true,
                            ),
                            onWithdraw: () => _openTransactionSheet(
                              context,
                              colors,
                              envelops[i],
                              isDeposit: false,
                            ),
                            onHistory: () =>
                                _openHistory(context, colors, envelops[i]),
                            onDelete: () =>
                                _confirmDelete(context, colors, envelops[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, colors),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        heroTag: 'envelop_fab',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Nuevo sobre',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  void _openCreateSheet(
    BuildContext context,
    AppThemeColors colors, [
    Envelop? envelop,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<EnvelopBloc>(),
        child: _CreateEnvelopSheet(colors: colors, envelop: envelop),
      ),
    );
  }

  void _openTransactionSheet(
    BuildContext context,
    AppThemeColors colors,
    Envelop envelop, {
    required bool isDeposit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<EnvelopBloc>(),
        child: _TransactionSheet(
          colors: colors,
          envelop: envelop,
          isDeposit: isDeposit,
        ),
      ),
    );
  }

  void _openHistory(
    BuildContext context,
    AppThemeColors colors,
    Envelop envelop,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(colors: colors, envelop: envelop),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppThemeColors colors,
    Envelop envelop,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar sobre',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '¿Eliminar "${envelop.name}"?\nSaldo actual: \u20a1${envelop.amount.toStringAsFixed(0)}',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<EnvelopBloc>().add(DeleteEnvelop(envelopId: envelop.id));
    }
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppThemeColors colors;
  final double total;
  final VoidCallback onAdd;

  const _Header({
    required this.colors,
    required this.total,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('✉️', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                'Sobres',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.primary.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total en sobres',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\u20a1${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este dinero está separado de tu cuenta principal',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Envelop Card ─────────────────────────────────────────────────────────────

class _EnvelopCard extends StatelessWidget {
  final Envelop envelop;
  final AppThemeColors colors;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const _EnvelopCard({
    required this.envelop,
    required this.colors,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasBalance = envelop.amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('✉️', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        envelop.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${envelop.transactions.length} transacciones',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\u20a1${envelop.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: hasBalance
                            ? colors.primary
                            : colors.textSecondary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'disponible',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    colors: colors,
                    label: 'Meter',
                    icon: Icons.arrow_downward_rounded,
                    color: colors.success,
                    onTap: onDeposit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    colors: colors,
                    label: 'Sacar',
                    icon: Icons.arrow_upward_rounded,
                    color: colors.error,
                    onTap: onWithdraw,
                    enabled: hasBalance,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    colors: colors,
                    label: 'Historial',
                    icon: Icons.history_rounded,
                    color: colors.textSecondary,
                    onTap: onHistory,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final AppThemeColors colors;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionBtn({
    required this.colors,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Create / Edit Sheet ──────────────────────────────────────────────────────

class _CreateEnvelopSheet extends StatefulWidget {
  final AppThemeColors colors;
  final Envelop? envelop;

  const _CreateEnvelopSheet({required this.colors, this.envelop});

  @override
  State<_CreateEnvelopSheet> createState() => _CreateEnvelopSheetState();
}

class _CreateEnvelopSheetState extends State<_CreateEnvelopSheet> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.envelop?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (widget.envelop != null) {
      context.read<EnvelopBloc>().add(
        UpdateEnvelop(envelop: widget.envelop!.copyWith(name: name)),
      );
    } else {
      context.read<EnvelopBloc>().add(
        CreateEnvelop(
          envelop: Envelop(
            id: const Uuid().v4(),
            name: name,
            amount: 0,
            transactions: [],
            createdAt: DateTime.now(),
          ),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isEditing = widget.envelop != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEditing ? 'Editar sobre' : 'Nuevo sobre ✉️',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NOMBRE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: Comida, Gasolina, Vacaciones...',
                hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isEditing ? 'Guardar cambios' : 'Crear sobre',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Sheet (Meter / Sacar) ────────────────────────────────────────

class _TransactionSheet extends StatefulWidget {
  final AppThemeColors colors;
  final Envelop envelop;
  final bool isDeposit;

  const _TransactionSheet({
    required this.colors,
    required this.envelop,
    required this.isDeposit,
  });

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    final note = _noteCtrl.text.trim();

    if (widget.isDeposit) {
      context.read<EnvelopBloc>().add(
        DepositToEnvelop(
          envelopId: widget.envelop.id,
          amount: amount,
          note: note,
        ),
      );
    } else {
      context.read<EnvelopBloc>().add(
        WithdrawFromEnvelop(
          envelopId: widget.envelop.id,
          amount: amount,
          note: note,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDeposit = widget.isDeposit;
    final accentColor = isDeposit ? colors.success : colors.error;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDeposit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDeposit ? 'Meter al sobre' : 'Sacar del sobre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.envelop.name,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (!isDeposit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: colors.warning,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Disponible: \u20a1${widget.envelop.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'MONTO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
            ),
            child: TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: accentColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: accentColor.withOpacity(0.3),
                  fontSize: 28,
                ),
                prefixText: '\u20a1 ',
                prefixStyle: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'NOTA (opcional)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: TextField(
              controller: _noteCtrl,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej: Supermercado semanal...',
                hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isDeposit ? 'Meter dinero' : 'Sacar dinero',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Sheet ────────────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  final AppThemeColors colors;
  final Envelop envelop;

  const _HistorySheet({required this.colors, required this.envelop});

  @override
  Widget build(BuildContext context) {
    final sorted = List<EnvelopTransaction>.from(envelop.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial · ${envelop.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Saldo: \u20a1${envelop.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Totales rápidos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniStat(
                      label: '↓ Metido',
                      amount: sorted
                          .where((t) => t.isDeposit)
                          .fold(0.0, (s, t) => s + t.amount),
                      color: colors.success,
                    ),
                    const SizedBox(height: 4),
                    _MiniStat(
                      label: '↑ Sacado',
                      amount: sorted
                          .where((t) => !t.isDeposit)
                          .fold(0.0, (s, t) => s + t.amount),
                      color: colors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          // List
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📭', style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'Sin transacciones aún',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => Divider(
                      color: colors.border.withOpacity(0.5),
                      height: 1,
                    ),
                    itemBuilder: (_, i) =>
                        _TxTile(tx: sorted[i], colors: colors),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '\u20a1${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TxTile extends StatelessWidget {
  final EnvelopTransaction tx;
  final AppThemeColors colors;

  const _TxTile({required this.tx, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isDeposit = tx.isDeposit;
    final color = isDeposit ? colors.success : colors.error;
    final months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final dateLabel = '${tx.date.day} ${months[tx.date.month]} ${tx.date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeposit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note.isNotEmpty
                      ? tx.note
                      : (isDeposit ? 'Depósito' : 'Retiro'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'}\u20a1${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state & Error ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onAdd;

  const _EmptyState({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✉️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Sin sobres',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un sobre para separar dinero\npor categorías y controlarlo mejor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Crear primer sobre',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final AppThemeColors colors;
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.colors,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
