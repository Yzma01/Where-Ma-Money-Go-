import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/envelop.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/repositories/envelop_repository.dart';
import 'envelop_event.dart';
import 'envelop_state.dart';
import 'package:where_ma_money_go/models/envelop_transaction.dart';

class EnvelopBloc extends Bloc<EnvelopEvent, EnvelopState> {
  final EnvelopRepository repository;
  final BillsBloc billsBloc;

  // Categoría "Sobres" hardcodeada — se usará en los bills registrados
  static final _sobresCat = Categories(
    id: 'sobres',
    name: 'Sobres',
    icon: '✉️',
    subcategories: [],
  );

  EnvelopBloc({required this.repository, required this.billsBloc})
    : super(EnvelopInitial()) {
    on<LoadEnvelops>(_onLoad);
    on<CreateEnvelop>(_onCreate);
    on<UpdateEnvelop>(_onUpdate);
    on<DeleteEnvelop>(_onDelete);
    on<DepositToEnvelop>(_onDeposit);
    on<WithdrawFromEnvelop>(_onWithdraw);
  }

  Future<void> _onLoad(LoadEnvelops event, Emitter<EnvelopState> emit) async {
    emit(EnvelopLoading());
    try {
      final envelops = await repository.getEnvelops();
      emit(EnvelopLoaded(envelops: envelops));
    } catch (e) {
      emit(EnvelopError(message: e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateEnvelop event,
    Emitter<EnvelopState> emit,
  ) async {
    try {
      await repository.createEnvelop(event.envelop);
      add(LoadEnvelops());
    } catch (e) {
      emit(EnvelopError(message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateEnvelop event,
    Emitter<EnvelopState> emit,
  ) async {
    try {
      await repository.updateEnvelop(event.envelop);
      add(LoadEnvelops());
    } catch (e) {
      emit(EnvelopError(message: e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteEnvelop event,
    Emitter<EnvelopState> emit,
  ) async {
    try {
      await repository.deleteEnvelop(event.envelopId);
      add(LoadEnvelops());
    } catch (e) {
      emit(EnvelopError(message: e.toString()));
    }
  }

  /// Depositar al sobre = egreso de cuenta principal (sale de la billetera)
  /// El dinero queda "guardado" en el sobre → NO se cuenta como gasto normal.
  /// Se registra el bill con cashFlow 'expense' para que salga del balance,
  /// pero la categoría "Sobres" debe excluirse del pie chart y del resumen.
  Future<void> _onDeposit(
    DepositToEnvelop event,
    Emitter<EnvelopState> emit,
  ) async {
    try {
      final state = this.state;
      if (state is! EnvelopLoaded) return;

      final envelop = state.envelops.firstWhere((e) => e.id == event.envelopId);
      final now = DateTime.now();
      final tx = EnvelopTransaction(
        id: const Uuid().v4(),
        amount: event.amount,
        type: 'deposit',
        note: event.note,
        date: now,
      );

      final updated = envelop.copyWith(
        amount: envelop.amount + event.amount,
        transactions: [...envelop.transactions, tx],
      );
      await repository.updateEnvelop(updated);

      // Registrar egreso en historial de bills (sale de cuenta principal)
      billsBloc.add(
        AddBill(
          bill: Bill(
            id: const Uuid().v4(),
            category: _sobresCat,
            subcategory: Subcategory(name: envelop.name),
            amount: event.amount,
            date: now,
            month: now.month.toString(),
            type: 'envelope_deposit',
            cashFlow: 'expense', // sale de la cuenta principal
          ),
        ),
      );

      add(LoadEnvelops());
    } catch (e) {
      emit(EnvelopError(message: e.toString()));
    }
  }

  /// Retirar del sobre = ingreso a cuenta principal (vuelve a la billetera)
  Future<void> _onWithdraw(
    WithdrawFromEnvelop event,
    Emitter<EnvelopState> emit,
  ) async {
    try {
      final state = this.state;
      if (state is! EnvelopLoaded) return;

      final envelop = state.envelops.firstWhere((e) => e.id == event.envelopId);
      if (event.amount > envelop.amount) {
        emit(EnvelopError(message: 'Saldo insuficiente en el sobre'));
        return;
      }

      final now = DateTime.now();
      final tx = EnvelopTransaction(
        id: const Uuid().v4(),
        amount: event.amount,
        type: 'withdraw',
        note: event.note,
        date: now,
      );

      final updated = envelop.copyWith(
        amount: envelop.amount - event.amount,
        transactions: [...envelop.transactions, tx],
      );
      await repository.updateEnvelop(updated);

      // Registrar ingreso en historial de bills (vuelve a cuenta principal)
      billsBloc.add(
        AddBill(
          bill: Bill(
            id: const Uuid().v4(),
            category: _sobresCat,
            subcategory: Subcategory(name: envelop.name),
            amount: event.amount,
            date: now,
            month: now.month.toString(),
            type: 'envelope_withdraw',
            cashFlow: 'income', // vuelve a la cuenta principal
          ),
        ),
      );

      add(LoadEnvelops());
    } catch (e) {
      emit(EnvelopError(message: e.toString()));
    }
  }
}
