import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final List<WorkModel> _works = [
    WorkModel(
      id: '1',
      title: 'Instalação Ar-Condicionado',
      clientName: 'Roberto Alves',
      value: 850.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Concluído',
      category: 'Climatização',
    ),
    WorkModel(
      id: '2',
      title: 'Manutenção Elétrica Predial',
      clientName: 'Condomínio Solar',
      value: 2400.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Concluído',
      category: 'Elétrica',
    ),
    WorkModel(
      id: '3',
      title: 'Reforma de Banheiro',
      clientName: 'Ana Souza',
      value: 3500.00,
      date: DateTime.now().add(const Duration(days: 10)),
      status: 'Aprovado',
      category: 'Reformas',
    ),
    WorkModel(
      id: '4',
      title: 'Pintura Residencial',
      clientName: 'Carlos Eduardo',
      value: 1800.00,
      date: DateTime.now().add(const Duration(days: 15)),
      status: 'Pendente',
      category: 'Pintura',
    ),
  ];

  double get _totalReceived => _works
      .where((w) => w.status == 'Concluído')
      .fold(0.0, (sum, item) => sum + item.value);

  double get _totalApprovedForecast => _works
      .where((w) => w.status == 'Aprovado')
      .fold(0.0, (sum, item) => sum + item.value);

  double get _totalPendingForecast => _works
      .where((w) => w.status == 'Pendente')
      .fold(0.0, (sum, item) => sum + item.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro & Relatórios'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previsão Financeira',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Recebido (Realizado)',
                    value: _totalReceived,
                    color: Colors.green,
                    icon: Icons.monetization_on,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFinancialCard(
                    title: 'A Receber (Aprovado)',
                    value: _totalApprovedForecast,
                    color: Colors.blue,
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Em Análise (Pendente)',
                    value: _totalPendingForecast,
                    color: Colors.orange,
                    icon: Icons.hourglass_top,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Total Projetado',
                    value: _totalReceived + _totalApprovedForecast,
                    color: Colors.purple,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimos Trabalhos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextChip(
                  label: '${_works.length} Registros',
                  color: Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _works.length,
              itemBuilder: (context, index) {
                final work = _works[index];
                Color statusColor;

                switch (work.status) {
                  case 'Concluído':
                    statusColor = Colors.green;
                    break;
                  case 'Aprovado':
                    statusColor = Colors.blue;
                    break;
                  default:
                    statusColor = Colors.orange;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(Icons.work_outline, color: statusColor),
                    ),
                    title: Text(
                      work.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Cliente: ${work.clientName}\nData: ${DateFormat('dd/MM/yyyy').format(work.date)}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(work.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            work.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TextChip extends StatelessWidget {
  final String label;
  final Color color;

  const TextChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}