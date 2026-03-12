import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/note.dart';

abstract class NotesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {}

class AddNote extends NotesEvent {
  final Note note;

  AddNote({required this.note});

  @override
  List<Object?> get props => [note];
}

class UpdateNote extends NotesEvent {
  final Note note;

  UpdateNote({required this.note});

  @override
  List<Object?> get props => [note];
}

class DeleteNote extends NotesEvent {
  final String id;

  DeleteNote({required this.id});

  @override
  List<Object?> get props => [id];
}

class ClearNotes extends NotesEvent {}

class SearchNotes extends NotesEvent {
  final String query;

  SearchNotes({required this.query});

  @override
  List<Object?> get props => [query];
}
