import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/note.dart';

class NotesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Note> notes;

  NotesLoaded(this.notes);

  @override
  List<Object?> get props => [notes];
}

class NotesError extends NotesState {
  final String message;

  NotesError(this.message);

  @override
  List<Object?> get props => [message];
}
