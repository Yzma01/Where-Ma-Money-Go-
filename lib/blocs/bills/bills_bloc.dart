import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/bills/bills_state.dart';
import 'package:where_ma_money_go/repositories/bills_repository.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  final BillsRepository billsRepository;

  BillsBloc(this.billsRepository) : super(BillsInitial()) {
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
      await billsRepository.deleteBill(event.id);
      add(LoadBills());
    } catch (e) {
      emit(BillsError(message: e.toString()));
    }
  }
}
