// lib/models/app_models.dart

class AppointmentModel {
  final String id;
  final String title;
  final String clientName;
  final String phone;
  final DateTime dateTime;
  final String notes;
  String status; // 'Agendado', 'Concluído', 'Cancelado'

  AppointmentModel({
    required this.id,
    required this.title,
    required this.clientName,
    required this.phone,
    required this.dateTime,
    this.notes = '',
    this.status = 'Agendado',
  });
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
}