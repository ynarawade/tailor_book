import '../models/customer.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String activeSearchQuery;

  CustomerLoaded({
    required this.customers,
    required this.totalCount,
    required this.hasMore,
    this.isLoadingMore = false,
    this.activeSearchQuery = '',
  });

  CustomerLoaded copyWith({
    List<Customer>? customers,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
    String? activeSearchQuery,
  }) {
    return CustomerLoaded(
      customers: customers ?? this.customers,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      activeSearchQuery: activeSearchQuery ?? this.activeSearchQuery,
    );
  }

  @override
  List<Object?> get props => [
    customers,
    totalCount,
    hasMore,
    isLoadingMore,
    activeSearchQuery,
  ];
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

class CustomerAdded extends CustomerState {
  final String message;
  final int customerId; // <--- Pass ID back to form for redirect

  CustomerAdded(this.message, this.customerId);
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
