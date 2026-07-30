// import 'dart:io';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';

// import '../database/database_helper.dart';
// import '../models/customer.dart';
// import 'customer_event.dart';
// import 'customer_state.dart';

// class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
//   final DatabaseHelper _databaseHelper = DatabaseHelper();
//   static const int _pageSize = 5;
//   int _currentOffset = 0;
//   CustomerBloc() : super(CustomerInitial()) {
//     on<LoadCustomers>(_onLoadCustomers);
//     on<LoadMoreCustomers>(_onLoadMoreCustomers);
//     on<SearchCustomers>(_onSearchCustomers);
//     on<AddCustomer>(_onAddCustomer);
//     on<DeleteCustomer>(_onDeleteCustomer);
//     on<LoadCustomerImages>(_onLoadCustomerImages);
//     on<UpdateCustomer>(_onUpdateCustomer);
//   }

//   Future<void> _onLoadCustomers(
//     LoadCustomers event,
//     Emitter<CustomerState> emit,
//   ) async {
//     emit(CustomerLoading());
//     try {
//       _currentOffset = 0;
//       final customers = await _databaseHelper.getCustomersPaginated(
//         limit: _pageSize,
//         offset: _currentOffset,
//       );

//       _currentOffset += customers.length;
//       final hasMore = customers.length == _pageSize;

//       emit(CustomerLoaded(customers: customers, hasMore: hasMore));
//     } catch (e) {
//       emit(CustomerError('Failed to load customers'));
//     }
//   }

//   Future<void> _onLoadMoreCustomers(
//     LoadMoreCustomers event,
//     Emitter<CustomerState> emit,
//   ) async {
//     final currentState = state;
//     if (currentState is! CustomerLoaded ||
//         currentState.isLoadingMore ||
//         !currentState.hasMore) {
//       return;
//     }

//     emit(currentState.copyWith(isLoadingMore: true));

//     try {
//       final moreCustomers = await _databaseHelper.getCustomersPaginated(
//         limit: _pageSize,
//         offset: _currentOffset,
//       );

//       _currentOffset += moreCustomers.length;
//       final hasMore = moreCustomers.length == _pageSize;

//       final updatedList = List<Customer>.from(currentState.customers)
//         ..addAll(moreCustomers);

//       emit(
//         CustomerLoaded(
//           customers: updatedList,
//           hasMore: hasMore,
//           isLoadingMore: false,
//         ),
//       );
//     } catch (e) {
//       emit(currentState.copyWith(isLoadingMore: false));
//     }
//   }

//   Future<void> _onSearchCustomers(
//     SearchCustomers event,
//     Emitter<CustomerState> emit,
//   ) async {
//     if (event.query.trim().isEmpty) {
//       add(LoadCustomers());
//       return;
//     }

//     // For search, load matching results
//     emit(CustomerLoading());
//     try {
//       final results = await _databaseHelper.searchCustomers(event.query);
//       // emit(CustomerLoaded(customers: results, hasMore: false));
//     } catch (e) {
//       emit(CustomerError('Search failed'));
//     }
//   }

//   // Future<void> _onDeleteCustomer(
//   //   DeleteCustomer event,
//   //   Emitter<CustomerState> emit,
//   // ) async {
//   //   try {
//   //     await _databaseHelper.deleteCustomer(event.customerId);
//   //     add(LoadCustomers()); // Refresh initial page
//   //     emit(CustomerDeleted('Client deleted successfully'));
//   //   } catch (e) {
//   //     emit(CustomerError('Failed to delete client'));
//   //   }
//   // }

//   void _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) async {
//     emit(CustomerLoading());
//     try {
//       // 1. Insert basic customer info into database
//       final customerId = await _databaseHelper.insertCustomer({
//         'name': event.name,
//         'mobile_number': event.mobileNumber,
//         'created_at': DateTime.now().toIso8601String(),
//       });

//       // 2. Emit success state with newly generated customer ID
//       emit(CustomerAdded('Customer added successfully!', customerId));
//       add(LoadCustomers());
//     } catch (e) {
//       emit(CustomerError('Failed to add customer: ${e.toString()}'));
//     }
//   }

//   void _onDeleteCustomer(
//     DeleteCustomer event,
//     Emitter<CustomerState> emit,
//   ) async {
//     try {
//       // Delete customer images from file system
//       final images = await _databaseHelper.getCustomerImages(event.customerId);
//       for (final imageData in images) {
//         final appDir = await getApplicationDocumentsDirectory();
//         final file = File(path.join(appDir.path, imageData['image_path']));

//         if (await file.exists()) {
//           await file.delete();
//         }
//       }

//       // Delete customer directory
//       final directory = await getApplicationDocumentsDirectory();
//       final customerDir = Directory(
//         '${directory.path}/customer_images/customer_${event.customerId}',
//       );
//       if (await customerDir.exists()) {
//         await customerDir.delete(recursive: true);
//       }

//       await _databaseHelper.deleteCustomer(event.customerId);
//       emit(CustomerDeleted('Customer deleted successfully!'));
//       add(LoadCustomers());
//     } catch (e) {
//       emit(CustomerError('Failed to delete customer: ${e.toString()}'));
//     }
//   }

//   void _onLoadCustomerImages(
//     LoadCustomerImages event,
//     Emitter<CustomerState> emit,
//   ) async {
//     emit(CustomerImagesLoading());
//     try {
//       final imagesData = await _databaseHelper.getCustomerImages(
//         event.customerId,
//       );
//       final images = imagesData
//           .map((data) => CustomerImage.fromMap(data))
//           .toList();
//       emit(CustomerImagesLoaded(images));
//     } catch (e) {
//       emit(CustomerError('Failed to load images: ${e.toString()}'));
//     }
//   }

//   void _onUpdateCustomer(
//     UpdateCustomer event,
//     Emitter<CustomerState> emit,
//   ) async {
//     try {
//       await _databaseHelper.updateCustomer(event.customerId, {
//         'name': event.name,
//         'mobile_number': event.mobileNumber,
//       });

//       emit(CustomerUpdated('Customer updated successfully!'));
//       add(LoadCustomers());
//     } catch (e) {
//       emit(CustomerError('Failed to update customer: ${e.toString()}'));
//     }
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import 'customer_event.dart';
import 'customer_state.dart';

// Event transformer helper for 500ms debounce + query cancellation (switchMap)
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) {
    return events.transform(_DebounceRestartableTransformer(duration, mapper));
  };
}

class _DebounceRestartableTransformer<E, SS>
    extends StreamTransformerBase<E, SS> {
  final Duration _duration;
  final Stream<SS> Function(E) _mapper;

  _DebounceRestartableTransformer(this._duration, this._mapper);

  @override
  Stream<SS> bind(Stream<E> stream) {
    Timer? timer;
    StreamSubscription<SS>? mapperSubscription;

    return Stream<SS>.eventTransformed(stream, (sink) {
      return StreamController<E>(
          sync: true,
          onCancel: () {
            timer?.cancel();
            mapperSubscription?.cancel();
          },
        )
        ..stream.listen((event) {
          timer?.cancel();
          timer = Timer(_duration, () {
            mapperSubscription?.cancel();
            mapperSubscription = _mapper(
              event,
            ).listen(sink.add, onError: sink.addError, onDone: () {});
          });
        });
    });
  }
}

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const int _pageSize = 50;
  int _currentOffset = 0;

  CustomerBloc() : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<LoadMoreCustomers>(_onLoadMoreCustomers);
    // Applying 500ms debounce to search event
    on<SearchCustomers>(
      _onSearchCustomers,
      transformer: debounceRestartable(const Duration(milliseconds: 500)),
    );
    on<AddCustomer>(_onAddCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<LoadCustomerImages>(_onLoadCustomerImages);
    on<UpdateCustomer>(_onUpdateCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      _currentOffset = 0;
      final rawCustomers = await _databaseHelper.getCustomersPaginated(
        limit: _pageSize,
        offset: _currentOffset,
      );
      final totalCount = await _databaseHelper.getTotalCustomerCount();

      final customers = rawCustomers
          .map((map) => Customer.fromMap(map))
          .toList();

      _currentOffset += customers.length;
      final hasMore = _currentOffset < totalCount;

      emit(
        CustomerLoaded(
          customers: customers,
          hasMore: hasMore,
          totalCount: totalCount,
          activeSearchQuery: '',
        ),
      );
    } catch (e) {
      emit(CustomerError('Failed to load customers: ${e.toString()}'));
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      add(LoadCustomers());
      return;
    }

    emit(CustomerLoading());
    try {
      _currentOffset = 0;
      final totalCount = await _databaseHelper.getTotalCustomerCount(
        searchQuery: query,
      );
      final rawCustomers = await _databaseHelper.getCustomersPaginated(
        limit: _pageSize,
        offset: _currentOffset,
        searchQuery: query,
      );

      final customers = rawCustomers
          .map((map) => Customer.fromMap(map))
          .toList();

      _currentOffset += customers.length;
      final hasMore = _currentOffset < totalCount;

      emit(
        CustomerLoaded(
          customers: customers,
          hasMore: hasMore,
          totalCount: totalCount,
          activeSearchQuery: query,
        ),
      );
    } catch (e) {
      emit(CustomerError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreCustomers(
    LoadMoreCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CustomerLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final query = currentState.activeSearchQuery;
      // Align offset directly with currently loaded list size
      final offsetToFetch = currentState.customers.length;

      final rawCustomers = await _databaseHelper.getCustomersPaginated(
        limit: _pageSize,
        offset: offsetToFetch,
        searchQuery: query.isNotEmpty ? query : null,
      );

      final moreCustomers = rawCustomers
          .map((map) => Customer.fromMap(map))
          .toList();

      final updatedList = List<Customer>.from(currentState.customers)
        ..addAll(moreCustomers);

      _currentOffset = updatedList.length;
      final hasMore = _currentOffset < currentState.totalCount;

      emit(
        CustomerLoaded(
          customers: updatedList,
          hasMore: hasMore,
          isLoadingMore: false,
          totalCount: currentState.totalCount,
          activeSearchQuery: query,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customerId = await _databaseHelper.insertCustomer({
        'name': event.name,
        'mobile_number': event.mobileNumber,
        'created_at': DateTime.now().toIso8601String(),
      });

      emit(CustomerAdded('Customer added successfully!', customerId));
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError('Failed to add customer: ${e.toString()}'));
    }
  }

  void _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final images = await _databaseHelper.getCustomerImages(event.customerId);
      for (final imageData in images) {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File(path.join(appDir.path, imageData['image_path']));

        if (await file.exists()) {
          await file.delete();
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final customerDir = Directory(
        '${directory.path}/customer_images/customer_${event.customerId}',
      );
      if (await customerDir.exists()) {
        await customerDir.delete(recursive: true);
      }

      await _databaseHelper.deleteCustomer(event.customerId);
      emit(CustomerDeleted('Customer deleted successfully!'));

      if (state is CustomerLoaded) {
        final query = (state as CustomerLoaded).activeSearchQuery;
        if (query.isNotEmpty) {
          add(SearchCustomers(query));
        } else {
          add(LoadCustomers());
        }
      } else {
        add(LoadCustomers());
      }
    } catch (e) {
      emit(CustomerError('Failed to delete customer: ${e.toString()}'));
    }
  }

  void _onLoadCustomerImages(
    LoadCustomerImages event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerImagesLoading());
    try {
      final imagesData = await _databaseHelper.getCustomerImages(
        event.customerId,
      );
      final images = imagesData
          .map((data) => CustomerImage.fromMap(data))
          .toList();
      emit(CustomerImagesLoaded(images));
    } catch (e) {
      emit(CustomerError('Failed to load images: ${e.toString()}'));
    }
  }

  void _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _databaseHelper.updateCustomer(event.customerId, {
        'name': event.name,
        'mobile_number': event.mobileNumber,
      });

      emit(CustomerUpdated('Customer updated successfully!'));
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError('Failed to update customer: ${e.toString()}'));
    }
  }
}
