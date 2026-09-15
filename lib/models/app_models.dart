// lib/models/app_models.dart

class UserAccountInfo {
  final String email;
  final String displayName;
  UserAccountInfo({required this.email, required this.displayName});
}

class AppointmentModel {
  final String id;
  final String title;
  final String clientName;
  final String phone;
  final DateTime dateTime;
  final String notes;
  String status; // 'Agendado', 'Concluído', 'Cancelado'
  String? budgetId;

  AppointmentModel({
    required this.id,
    required this.title,
    required this.clientName,
    this.phone = '',
    required this.dateTime,
    this.notes = '',
    this.status = 'Agendado',
    this.budgetId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'clientName': clientName,
        'phone': phone,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
        'status': status,
        'budgetId': budgetId,
      };

  factory AppointmentModel.fromJson(Map<String, dynamic> json) => AppointmentModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        clientName: json['clientName'] ?? '',
        phone: json['phone'] ?? '',
        dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
        notes: json['notes'] ?? '',
        status: json['status'] ?? 'Agendado',
        budgetId: json['budgetId'],
      );
}

class WorkModel {
  final String id;
  final String title;
  final String clientName;
  final double value;
  final DateTime date;
  final String status; // 'Concluído', 'Aprovado', 'Pendente'
  final String category;

  WorkModel({
    required this.id,
    required this.title,
    required this.clientName,
    required this.value,
    required this.date,
    required this.status,
    this.category = 'Geral',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'clientName': clientName,
        'value': value,
        'date': date.toIso8601String(),
        'status': status,
        'category': category,
      };

  factory WorkModel.fromJson(Map<String, dynamic> json) => WorkModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        clientName: json['clientName'] ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'Pendente',
        category: json['category'] ?? 'Geral',
      );
}