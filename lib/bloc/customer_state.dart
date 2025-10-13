import '../models/customer.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  CustomerLoaded(this.customers);
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

class CustomerAdded extends CustomerState {
  final String message;
  CustomerAdded(this.message);
}

class CustomerDeleted extends CustomerState {
  final String message;
  CustomerDeleted(this.message);
}

class CustomerImagesLoading extends CustomerState {}

class CustomerImagesLoaded extends CustomerState {
  final List<CustomerImage> images;
  CustomerImagesLoaded(this.images);
}

class CustomerUpdated extends CustomerState {
  final String message;
  CustomerUpdated(this.message);
}