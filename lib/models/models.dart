class ProjectStatus {
  final int? id;
  final String name;
  final String description;
  final bool isActive;

  ProjectStatus({
    this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory ProjectStatus.fromJson(Map<String, dynamic> json) {
    return ProjectStatus(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }
}

class Project {
  final int? id;
  final String title;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double cost;
  final List<ProjectItem> items;

  Project({
    this.id,
    required this.title,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.cost,
    this.items = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      status: ProjectStatus.fromJson(json['status']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      cost: (json['cost'] as num).toDouble(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ProjectItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'status': status.toJson(),
      'startDate': startDate.toIso8601String().split(
        'T',
      )[0], // Format as YYYY-MM-DD
      'endDate': endDate.toIso8601String().split(
        'T',
      )[0], // Format as YYYY-MM-DD
      'cost': cost,
      // Don't include items when sending to backend to avoid circular references
    };
  }
}

class ProjectItem {
  final int? id;
  final DateTime date;
  final String item;
  final double rate;
  final int quantity;
  final double rent;
  final double totalAmount;

  ProjectItem({
    this.id,
    required this.date,
    required this.item,
    required this.rate,
    required this.quantity,
    required this.rent,
    required this.totalAmount,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['id'],
      date: DateTime.parse(json['date']),
      item: json['item'],
      rate: (json['rate'] as num).toDouble(),
      quantity: json['quantity'],
      rent: (json['rent'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'item': item,
      'rate': rate,
      'quantity': quantity,
      'rent': rent,
      'totalAmount': totalAmount,
    };
  }
}
