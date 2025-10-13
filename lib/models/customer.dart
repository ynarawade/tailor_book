class Customer {
  final int? id;
  final String name;
  final String mobileNumber;
  final String createdAt;
  final int imageCount;

  Customer({
    this.id,
    required this.name,
    required this.mobileNumber,
    required this.createdAt,
    this.imageCount = 0,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      mobileNumber: map['mobile_number'],
      createdAt: map['created_at'],
      imageCount: map['image_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile_number': mobileNumber,
      'created_at': createdAt,
    };
  }
}

class CustomerImage {
  final int? id;
  final int customerId;
  final String imagePath;
  final String imageType;
  final String createdAt;

  CustomerImage({
    this.id,
    required this.customerId,
    required this.imagePath,
    required this.imageType,
    required this.createdAt,
  });

  factory CustomerImage.fromMap(Map<String, dynamic> map) {
    return CustomerImage(
      id: map['id'],
      customerId: map['customer_id'],
      imagePath: map['image_path'],
      imageType: map['image_type'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'image_path': imagePath,
      'image_type': imageType,
      'created_at': createdAt,
    };
  }
}