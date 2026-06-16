import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  CustomerBloc() : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<LoadCustomerImages>(_onLoadCustomerImages);
    on<UpdateCustomer>(_onUpdateCustomer);
  }

  void _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customersData = await _databaseHelper.getAllCustomers();
      final customers = customersData
          .map((data) => Customer.fromMap(data))
          .toList();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError('Failed to load customers: ${e.toString()}'));
    }
  }

  void _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customersData = event.query.isEmpty
          ? await _databaseHelper.getAllCustomers()
          : await _databaseHelper.searchCustomers(event.query);
      final customers = customersData
          .map((data) => Customer.fromMap(data))
          .toList();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError('Failed to search customers: ${e.toString()}'));
    }
  }

  void _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      // 1. Insert customer metadata into database
      final customerId = await _databaseHelper.insertCustomer({
        'name': event.name,
        'mobile_number': event.mobileNumber,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Setup the permanent directory path
      final directory = await getApplicationDocumentsDirectory();
      final customerDirSubPath = 'customer_images/customer_$customerId';
      final customerDir = Directory(
        path.join(directory.path, customerDirSubPath),
      );

      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }

      // 3. Process and move each compressed image
      for (int i = 0; i < event.imagePaths.length; i++) {
        final fileName =
            'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        // This is where the file will physically live
        final absoluteNewPath = path.join(customerDir.path, fileName);

        // This safe relative string is what we store in SQLite
        final relativeDatabasePath = path.join(customerDirSubPath, fileName);

        // PHYSICAL FILE MOVE: Relocate from the compressor's destination
        final sourceFile = File(event.imagePaths[i]);
        if (await sourceFile.exists()) {
          await sourceFile.rename(absoluteNewPath);
        }

        // 4. Save the RELATIVE path to the database
        await _databaseHelper.insertImage({
          'customer_id': customerId,
          'image_path': relativeDatabasePath, // Safe for iOS updates!
          'image_type': 'general',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      emit(CustomerAdded('Customer added successfully!'));
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
      // Delete customer images from file system
      final images = await _databaseHelper.getCustomerImages(event.customerId);
      for (final imageData in images) {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File(path.join(appDir.path, imageData['image_path']));

        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete customer directory
      final directory = await getApplicationDocumentsDirectory();
      final customerDir = Directory(
        '${directory.path}/customer_images/customer_${event.customerId}',
      );
      if (await customerDir.exists()) {
        await customerDir.delete(recursive: true);
      }

      await _databaseHelper.deleteCustomer(event.customerId);
      emit(CustomerDeleted('Customer deleted successfully!'));
      add(LoadCustomers());
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
