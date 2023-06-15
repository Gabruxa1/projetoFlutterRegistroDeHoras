import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_) {
    runApp(RegistroDeHorasApp());
  });
}

class RegistroDeHorasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Horas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<WorkDay> workDays = [];
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  final DateFormat timeFormatter = DateFormat('HH:mm', 'pt_BR');
  final TextEditingController entryTimeController = TextEditingController();
  final TextEditingController lunchTimeController = TextEditingController();
  final TextEditingController exitTimeController = TextEditingController();
  double hourlyRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWorkDays();
  }

  Future<void> _loadWorkDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? savedWorkDays = prefs.getStringList('workDays');
    if (savedWorkDays != null) {
      setState(() {
        workDays = savedWorkDays.map((day) => WorkDay.fromJson(jsonDecode(day))).toList();
      });
    }
  }

  Future<void> _saveWorkDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> workDaysJson = workDays.map((day) => jsonEncode(day.toJson())).toList();
    await prefs.setStringList('workDays', workDaysJson);
  }

  void _addWorkDay() {
    final String entryTime = entryTimeController.text;
    final String lunchTime = lunchTimeController.text;
    final String exitTime = exitTimeController.text;

    if (entryTime.isNotEmpty && exitTime.isNotEmpty) {
      final WorkDay workDay = WorkDay(
        entryTime: entryTime,
        lunchTime: lunchTime,
        exitTime: exitTime,
      );

      setState(() {
        workDays.add(workDay);
        entryTimeController.clear();
        lunchTimeController.clear();
        exitTimeController.clear();
        _saveWorkDays();
      });
    }
  }

  void _removeWorkDay(int index) {
    setState(() {
      workDays.removeAt(index);
      _saveWorkDays();
    });
  }

  double _calculateTotalHours() {
    double totalHours = 0;
    for (var workDay in workDays) {
      final double workDuration = workDay.calculateWorkDuration();
      totalHours += workDuration;
    }
    return totalHours;
  }

  double _calculateTotalSalary() {
    double totalSalary = 0;
    double totalHours = _calculateTotalHours();
    totalSalary = totalHours * hourlyRate;
    return totalSalary;
  }

  void _generateMonthlyReport() {
    double totalHours = _calculateTotalHours();
    double totalSalary = _calculateTotalSalary();
    String report = 'Relatorio Mensal:\n\n';
    report += 'Total Hours: ${totalHours.toStringAsFixed(2)}\n';
    report += 'Total Salary: ${totalSalary.toStringAsFixed(2)}\n\n';
    report += 'Work Days:\n';
    for (var workDay in workDays) {
      report +=
          '${workDay.date}: ${workDay.entryTime} - ${workDay.exitTime}, Lunch: ${workDay.lunchTime} hours\n';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Relatorio Mensal'),
          content: Text(report),
          actions: <Widget>[
            TextButton(
              child: Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Horas'),
      ),
      body: ListView.builder(
        itemCount: workDays.length,
        itemBuilder: (BuildContext context, int index) {
          final WorkDay workDay = workDays[index];
          return ListTile(
            title: Text(workDay.date),
            subtitle:
                Text('Horas Trabalhadas: ${workDay.calculateWorkDuration().toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _removeWorkDay(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _showAddWorkDayDialog();
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Total Hours: ${_calculateTotalHours().toStringAsFixed(2)}'),
              ElevatedButton(
                child: Text('Relatorio Geral'),
                onPressed: () {
                  _generateMonthlyReport();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddWorkDayDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Dia de Trabalho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: entryTimeController,
                decoration: InputDecoration(labelText: 'Hora de Entrada'),
              ),
              TextField(
                controller: lunchTimeController,
                decoration: InputDecoration(labelText: 'Tempo de Pausa'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: exitTimeController,
                decoration: InputDecoration(labelText: 'Hora de Saída'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Adicionar'),
              onPressed: () {
                _addWorkDay();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class WorkDay {
  String entryTime;
  String lunchTime;
  String exitTime;

  WorkDay({
    required this.entryTime,
    required this.lunchTime,
    required this.exitTime,
  });

  String get date {
    final DateTime now = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  double calculateWorkDuration() {
    final DateTime entry = DateTime.parse('2000-01-01 ${this.entryTime}');
    final DateTime exit = DateTime.parse('2000-01-01 ${this.exitTime}');
    final int lunchMinutes = int.parse(this.lunchTime);

    Duration workDuration = exit.difference(entry);
    workDuration -= Duration(minutes: lunchMinutes);

    return workDuration.inMinutes / 60.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'entryTime': entryTime,
      'lunchTime': lunchTime,
      'exitTime': exitTime,
    };
  }

  factory WorkDay.fromJson(Map<String, dynamic> json) {
    return WorkDay(
      entryTime: json['entryTime'],
      lunchTime: json['lunchTime'],
      exitTime: json['exitTime'],
    );
  }
}
