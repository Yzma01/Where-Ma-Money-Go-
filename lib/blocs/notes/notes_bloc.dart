import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_event.dart';
import 'package:where_ma_money_go/blocs/notes/notes_state.dart';
import 'package:where_ma_money_go/repositories/notes_repository.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository noteRepository;

  NotesBloc({required this.noteRepository}) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
    on<DeleteNote>(_onDeleteNote);
    on<UpdateNote>(_onUpdateNote);
    on<ClearNotes>(_onClearNotes);
    on<SearchNotes>(_onSearchNotes);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    try {
      final notes = await noteRepository.getNotes();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError('Error al cargar las notas: $e'));
    }
  }

  Future<void> _onAddNote(AddNote event, Emitter<NotesState> emit) async {
    try {
      await noteRepository.addNote(event.note);
      add(LoadNotes());
    } catch (e) {
      emit(NotesError('Error al agregar la nota: $e'));
    }
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    try {
      await noteRepository.deleteNote(event.id);
      add(LoadNotes());
    } catch (e) {
      emit(NotesError('Error al eliminar la nota: $e'));
    }
  }

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NotesState> emit) async {
    try {
      await noteRepository.updateNote(event.note);
      add(LoadNotes());
    } catch (e) {
      emit(NotesError('Error al actualizar la nota: $e'));
    }
  }

  Future<void> _onClearNotes(ClearNotes event, Emitter<NotesState> emit) async {
    try {
      await noteRepository.clearNotes();
      add(LoadNotes());
    } catch (e) {
      emit(NotesError('Error al limpiar las notas: $e'));
    }
  }

  Future<void> _onSearchNotes(
    SearchNotes event,
    Emitter<NotesState> emit,
  ) async {
    emit(NotesLoading());
    try {
      final notes = await noteRepository.searchNotes(event.query);
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError('Error al buscar las notas: $e'));
    }
  }
}
