import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
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
      // Insert customer
      final customerId = await _databaseHelper.insertCustomer({
        'name': event.name,
        'mobile_number': event.mobileNumber,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Save images to device storage and store paths
      final directory = await getApplicationDocumentsDirectory();
      final customerDir = Directory(
        '${directory.path}/customer_images/customer_$customerId',
      );
      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }

      for (int i = 0; i < event.imagePaths.length; i++) {
        final originalFile = File(event.imagePaths[i]);
        final fileName =
            'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final newPath = path.join(customerDir.path, fileName);

        await originalFile.copy(newPath);

        await _databaseHelper.insertImage({
          'customer_id': customerId,
          'image_path': newPath,
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
        final file = File(imageData['image_path']);
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
