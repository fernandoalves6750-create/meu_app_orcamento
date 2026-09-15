import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appointment {
  String id;
  String title;
  String clientName;
  DateTime date;
  String notes;
  String? budgetId;

  Appointment({
    required this.id,
    required this.title,
    required this.clientName,
    required this.date,
    this.notes = '',
    this.budgetId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'clientName': clientName,
        'date': date.toIso8601String(),
        'notes': notes,
        'budgetId': budgetId,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        clientName: json['clientName'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        notes: json['notes'] ?? '',
        budgetId: json['budgetId'],
      );
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<Appointment> _appointments = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('appointments_list');
    if (dataStr != null) {
      final List<dynamic> listJson = jsonDecode(dataStr);
      setState(() {
        _appointments = listJson.map((e) => Appointment.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_appointments.map((a) => a.toJson()).toList());
    await prefs.setString('appointments_list', jsonStr);
  }

  void _openAppointmentForm([Appointment? appointment]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentFormScreen(
          appointment: appointment,
          onSave: (savedAppt) async {
            setState(() {
              final index = _appointments.indexWhere((a) => a.id == savedAppt.id);
              if (index >= 0) {
                _appointments[index] = savedAppt;
              } else {
                _appointments.add(savedAppt);
              }
            });
            await _saveAppointments();
          },
        ),
      ),
    );
  }

  void _deleteAppointment(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Agendamento?'),
        content: const Text('Deseja remover este compromisso da agenda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              setState(() => _appointments.removeWhere((a) => a.id == id));
              await _saveAppointments();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _appointments.where((a) {
      return a.date.year == _selectedDate.year &&
          a.date.month == _selectedDate.month &&
          a.date.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda & Compromissos')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2023),
            lastDate: DateTime(2030),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Nenhum compromisso agendado para esta data.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.event, color: Colors.white),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cliente: ${item.clientName}'),
                              Text('Horário: ${DateFormat('HH:mm').format(item.date)}'),
                              if (item.notes.isNotEmpty) Text('Obs: ${item.notes}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAppointment(item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAppointmentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento'),
      ),
    );
  }
}

class AppointmentFormScreen extends StatefulWidget {
  final Appointment? appointment;
  final Function(Appointment) onSave;

  const AppointmentFormScreen({super.key, this.appointment, required this.onSave});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<Map<String, dynamic>> _pendingBudgets = [];
  String? _selectedBudgetId;

  @override
  void initState() {
    super.initState();
    _loadPendingBudgets();

    if (widget.appointment != null) {
      _titleController.text = widget.appointment!.title;
      _clientController.text = widget.appointment!.clientName;
      _notesController.text = widget.appointment!.notes;
      _selectedDate = widget.appointment!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment!.date);
      _selectedBudgetId = widget.appointment!.budgetId;
    }
  }

  Future<void> _loadPendingBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsStr = prefs.getString('budgets_list');
    if (budgetsStr != null) {
      final List<dynamic> listJson = jsonDecode(budgetsStr);
      setState(() {
        _pendingBudgets = listJson
            .map((e) => e as Map<String, dynamic>)
            .where((b) => b['status'] == 'Pendente' || b['id'] == widget.appointment?.budgetId)
            .toList();
      });
    }
  }

  Future<void> _updateBudgetStatusToApproved(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsStr = prefs.getString('budgets_list');
    if (budgetsStr != null) {
      final List<dynamic> listJson = jsonDecode(budgetsStr);
      final updatedList = listJson.map((e) {
        if (e['id'] == budgetId) {
          e['status'] = 'Aprovado';
        }
        return e;
      }).toList();
      await prefs.setString('budgets_list', jsonEncode(updatedList));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedBudgetId,
              decoration: const InputDecoration(
                labelText: 'Vincular Orçamento Pendente (Opcional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Nenhum orçamento vinculado'),
                ),
                ..._pendingBudgets.map((b) {
                  return DropdownMenuItem<String>(
                    value: b['id'],
                    child: Text('Orçamento #${b['number'].toString().padLeft(3, '0')} - ${b['clientName']}'),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedBudgetId = val;
                  if (val != null) {
                    final selected = _pendingBudgets.firstWhere((b) => b['id'] == val);
                    _clientController.text = selected['clientName'];
                    if (_titleController.text.isEmpty) {
                      _titleController.text = 'Serviço - Orçamento #${selected['number'].toString().padLeft(3, '0')}';
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título do Compromisso *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: 'Nome do Cliente *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observações / Endereço', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_titleController.text.isEmpty || _clientController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha os campos obrigatórios (*).')),
                    );
                    return;
                  }

                  final finalDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );

                  if (_selectedBudgetId != null) {
                    await _updateBudgetStatusToApproved(_selectedBudgetId!);
                  }

                  widget.onSave(Appointment(
                    id: widget.appointment?.id ?? DateTime.now().toString(),
                    title: _titleController.text,
                    clientName: _clientController.text,
                    date: finalDateTime,
                    notes: _notesController.text,
                    budgetId: _selectedBudgetId,
                  ));

                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text('SALVAR AGENDAMENTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}