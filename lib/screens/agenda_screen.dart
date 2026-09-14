// lib/screens/agenda_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  // Lista simulada de agendamentos
  final List<AppointmentModel> _appointments = [
    AppointmentModel(
      id: '1',
      title: 'Visita Técnica - Orçamento de Iluminação',
      clientName: 'João Silva',
      phone: '(11) 98765-4321',
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      notes: 'Verificar quadro elétrico e pontos de LED.',
      status: 'Agendado',
    ),
    AppointmentModel(
      id: '2',
      title: 'Execução de Serviço - Pintura da Fachada',
      clientName: 'Maria Oliveira',
      phone: '(11) 91234-5678',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
      notes: 'Levar tintas e andaime.',
      status: 'Agendado',
    ),
  ];

  List<AppointmentModel> get _filteredAppointments {
    return _appointments.where((app) {
      return app.dateTime.year == _selectedDate.year &&
          app.dateTime.month == _selectedDate.month &&
          app.dateTime.day == _selectedDate.day;
    }).toList();
  }

  void _openNewAppointmentModal(BuildContext context) {
    final titleController = TextEditingController();
    final clientController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = _selectedDate;
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo Agendamento',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Agendamento / Serviço',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: clientController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Cliente',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (pickedDate != null) {
                                setModalState(() => selectedDate = pickedDate);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(selectedTime.format(context)),
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (pickedTime != null) {
                                setModalState(() => selectedTime = pickedTime);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observações / Detalhes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('SALVAR AGENDAMENTO'),
                        onPressed: () {
                          if (titleController.text.isEmpty ||
                              clientController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preencha os campos principais.'),
                              ),
                            );
                            return;
                          }

                          final dt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          setState(() {
                            _appointments.add(
                              AppointmentModel(
                                id: DateTime.now().toString(),
                                title: titleController.text,
                                clientName: clientController.text,
                                phone: phoneController.text,
                                dateTime: dt,
                                notes: notesController.text,
                              ),
                            );
                          });

                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyAppointments = _filteredAppointments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Serviços'),
      ),
      body: Column(
        children: [
          // Seletor de Data Superior
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat("EEEE, d 'de' MMMM", 'pt_BR')
                          .format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),

          // Lista de Compromissos do Dia
          Expanded(
            child: dailyAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum agendamento para este dia.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: dailyAppointments.length,
                    itemBuilder: (context, index) {
                      final item = dailyAppointments[index];
                      final horaFormatada =
                          DateFormat('HH:mm').format(item.dateTime);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              horaFormatada,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Cliente: ${item.clientName} | ${item.phone}'),
                              if (item.notes.isNotEmpty)
                                Text(
                                  'Obs: ${item.notes}',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              setState(() {
                                item.status = val;
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Concluído',
                                child: Text('Marcar como Concluído'),
                              ),
                              const PopupMenuItem(
                                value: 'Cancelado',
                                child: Text('Marcar como Cancelado'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewAppointmentModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento'),
      ),
    );
  }
}