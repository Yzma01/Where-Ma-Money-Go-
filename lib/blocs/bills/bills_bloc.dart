import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/bills/bills_state.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/repositories/bills_repository.dart';
import 'package:where_ma_money_go/repositories/saving_repository.dart';
import 'package:where_ma_money_go/repositories/envelop_repository.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  final BillsRepository billsRepository;
  final SavingRepository savingRepository;
  final EnvelopRepository envelopRepository;

  BillsBloc({
    required this.billsRepository,
    required this.savingRepository,
    required this.envelopRepository,
  }) : super(BillsInitial()) {
    on<LoadBills>(_onLoadBills);
    on<AddBill>(_onAddBill);
    on<UpdateBill>(_onUpdateBill);
    on<DeleteBill>(_onDeleteBill);
  }

  Future<void> _onLoadBills(LoadBills event, Emitter<BillsState> emit) async {
    try {
      emit(BillsLoading());
      final bills = await billsRepository.getBills();
      emit(BillsLoaded(bills: bills));
    } catch (e) {
      emit(BillsError(message: e.toString()));
    }
  }

  Future<void> _onAddBill(AddBill event, Emitter<BillsState> emit) async {
    try {
      await billsRepository.addBill(event.bill);
      add(LoadBills());
    } catch (e) {
      emit(BillsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateBill(UpdateBill event, Emitter<BillsState> emit) async {
    try {
      await billsRepository.updateBill(event.bill);
      add(LoadBills());
    } catch (e) {
      emit(BillsError(message: e.toString()));
    }
  }

  Future<void> _onDeleteBill(DeleteBill event, Emitter<BillsState> emit) async {
    try {
      // Obtener el bill antes de borrarlo para saber qué revertir
      final currentState = state;
      if (currentState is BillsLoaded) {
        final bill = currentState.bills.firstWhere(
          (b) => b.id == event.id,
          orElse: () => throw Exception('Bill no encontrado'),
        );

        final isIncome = bill.cashFlow == 'income';
        final isExpense = bill.cashFlow == 'expense';

        // ── Revertir ahorro ──────────────────────────────────────────────────
        if (bill.savingId != null && bill.savingId!.isNotEmpty) {
          try {
            final savings = await savingRepository.getSavings();
            final saving = savings.firstWhere(
              (s) => s.id == bill.savingId,
              orElse: () => throw Exception('Saving no encontrado'),
            );
            // Al borrar un depósito de ahorro, restamos del currentAmount
            // Al borrar un retiro de ahorro, sumamos al currentAmount
            final delta = isIncome ? -bill.amount : bill.amount;
            final updated = saving.copyWith(
              currentAmount: (saving.currentAmount + delta).clamp(
                0,
                double.infinity,
              ),
            );
            await savingRepository.updateSaving(updated);
          } catch (_) {
            // Si el saving ya no existe, ignorar
          }
        }

        // ── Revertir sobre ───────────────────────────────────────────────────
        if (bill.category.name == 'Sobres') {
          try {
            final envelops = await envelopRepository.getEnvelops();
            final envelop = envelops.firstWhere(
              (e) => e.name == bill.subcategory.name,
              orElse: () => throw Exception('Sobre no encontrado'),
            );
            // Al borrar un depósito al sobre (expense del balance), restamos del sobre
            // Al borrar un retiro del sobre (income del balance), sumamos al sobre
            final delta = isExpense ? -bill.amount : bill.amount;
            final updated = envelop.copyWith(
              amount: (envelop.amount + delta).clamp(0, double.infinity),
            );
            await envelopRepository.updateEnvelop(updated);
          } catch (_) {
            // Si el sobre ya no existe, ignorar
          }
        }
      }

      // Borrar el bill
      await billsRepository.deleteBill(event.id);
      add(LoadBills());
    } catch (e) {
      emit(BillsError(message: e.toString()));
    }
  }
}
