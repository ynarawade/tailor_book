abstract class CustomerEvent {}

class LoadCustomers extends CustomerEvent {}

class LoadMoreCustomers extends CustomerEvent {}

class SearchCustomers extends CustomerEvent {
  final String query;
  SearchCustomers(this.query);
}

class AddCustomer extends CustomerEvent {
  final String name;
  final String mobileNumber;

  AddCustomer({required this.name, required this.mobileNumber});
}

class DeleteCustomer extends CustomerEvent {
  final int customerId;
  DeleteCustomer(this.customerId);
}

class LoadCustomerImages extends CustomerEvent {
  final int customerId;
  LoadCustomerImages(this.customerId);
}

class UpdateCustomer extends CustomerEvent {
  final int customerId;
  final String name;
  final String mobileNumber;

  UpdateCustomer({
    required this.customerId,
    required this.name,
    required this.mobileNumber,
  });
}
