import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';
//import 'package:shared_preferences/shared_preferences.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_) {
    runApp(HorasApp());
  });
}

class HorasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Horas',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      home: RegistroHorasScreen(),
    );
  }
}

class RegistroHorasScreen extends StatefulWidget {
  @override
  _RegistroHorasScreenState createState() => _RegistroHorasScreenState();
}

class _RegistroHorasScreenState extends State<RegistroHorasScreen> {
  List<Registro> registros = [];
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedStartTime = TimeOfDay.now();
  Duration lunchDuration = Duration();
  TimeOfDay selectedEndTime = TimeOfDay.now();
  Registro? selectedRegistro;
  double valorHora = 0.0;
  Duration totalHorasTrabalhadas = Duration();
  double valorTotal = 0.0;
  int selectedIndex = -1;

@override
void initState() {
  super.initState();
  selectedDate = DateTime.now();
  selectedStartTime = TimeOfDay.now();
  lunchDuration = Duration();
  selectedEndTime = TimeOfDay.now();
  loadRegistros();
}

void saveRegistros() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/registros.json');

  final encodedRegistros = registros.map((registro) {
    return {
      'data': registro.data.toIso8601String(),
      'inicio': registro.inicio.format(context),
      'fim': registro.fim.format(context),
      'intervalo': registro.intervalo.inMinutes,
      'total': registro.total.inMinutes,
    };
  }).toList();

  await file.writeAsString(json.encode(encodedRegistros));
}

void loadRegistros() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/registros.json');

  if (await file.exists()) {
    final encodedRegistros = await file.readAsString();
    final decodedRegistros = json.decode(encodedRegistros);
    setState(() {
      registros = decodedRegistros.map<Registro>((registro) {
        return Registro(
          data: DateTime.parse(registro['data']),
          inicio: _parseTimeOfDay(registro['inicio']),
          fim: _parseTimeOfDay(registro['fim']),
          intervalo: Duration(minutes: registro['intervalo']),
          total: Duration(minutes: registro['total']),
        );
      }).toList();
    });
  }
}

TimeOfDay _parseTimeOfDay(String timeString) {
  final parts = timeString.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return TimeOfDay(hour: hour, minute: minute);
}

  Future<DateTime?> selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2022),
    lastDate: DateTime(2025),
  );
  if (picked != null && picked != selectedDate) {
    setState(() {
      selectedDate = picked;
    });
  }
  return picked; // Retorna o DateTime selecionado ou null
}

  void selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        onTimeSelected(picked);
      });
    }
  }

  void calcularValorTotal() {
    valorTotal = totalHorasTrabalhadas.inHours * valorHora;
  }

  void selectLunchDuration(BuildContext context) async {
    final Duration? picked = await showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duração do intervalo de almoço'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Duration(hours: 1));
                },
                child: const Text('1 hora'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Duration(hours: 2));
                },
                child: const Text('2 horas'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Duration(hours: 3));
                },
                child: const Text('3 horas'),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != lunchDuration) {
      setState(() {
        lunchDuration = picked;
      });
    }
  }

  void addRegistro() {
  final startTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedStartTime.hour,
    selectedStartTime.minute,
  );
  final endTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedEndTime.hour,
    selectedEndTime.minute,
  );
  final totalDuration = endTime.difference(startTime) - lunchDuration;

  // Verificar se já existe um registro para a data selecionada
  final hasDuplicate = registros.any((registro) =>
      registro.data.year == selectedDate.year &&
      registro.data.month == selectedDate.month &&
      registro.data.day == selectedDate.day);

  if (hasDuplicate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Data já registrada'),
          content: Text('Já existe um registro para a data selecionada.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
    return;
  }

  final newRegistro = Registro(
    data: selectedDate,
    inicio: selectedStartTime,
    fim: selectedEndTime,
    intervalo: lunchDuration,
    total: totalDuration,
  );

  setState(() {
    registros.add(newRegistro);
    selectedRegistro = newRegistro;
    totalHorasTrabalhadas += totalDuration;
    calcularValorTotal();
    });
  saveRegistros();
  }

void editRegistro(Registro registro, TimeOfDay novoInicio, TimeOfDay novoFim) {
  final totalDuration = DateTime(
    registro.data.year,
    registro.data.month,
    registro.data.day,
    novoFim.hour,
    novoFim.minute,
  ).difference(DateTime(
    registro.data.year,
    registro.data.month,
    registro.data.day,
    novoInicio.hour,
    novoInicio.minute,
  )) - registro.intervalo;

  final updatedRegistro = Registro(
    data: registro.data,
    inicio: novoInicio,
    fim: novoFim,
    intervalo: registro.intervalo,
    total: totalDuration,
  );

  setState(() {
    // Atualize a referência para o novo objeto Registro
    registros[registros.indexOf(registro)] = updatedRegistro;
    selectedRegistro = updatedRegistro;

    totalHorasTrabalhadas = Duration();
    for (var reg in registros) {
      totalHorasTrabalhadas += reg.total;
    }
    calcularValorTotal();
  });
  saveRegistros();
}


void deleteRegistro(Registro registro) {
  setState(() {
    registros.remove(registro);
    totalHorasTrabalhadas -= registro.total;
    selectedRegistro = null;
    totalHorasTrabalhadas -= registro.total;
    calcularValorTotal();
  });
  saveRegistros();
}



  void deleteAllRegistros() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Excluir todos os registros?'),
          content: Text('Tem certeza que deseja apagar todos os registros?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Sim'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Não'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        registros.clear();
        totalHorasTrabalhadas = Duration();
        valorTotal = 0.0;
      });
    }
    saveRegistros();
  }


  void generatePDF(BuildContext context) async {
  DateTime? startDate;
  DateTime? endDate;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Selecionar Período'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Data de Início:'),
            ElevatedButton(
              onPressed: () async {
                final selectedStartDate = await selectDate(context);
                setState(() {
                  startDate = selectedStartDate;
                });
              },
              child: Text(
                startDate != null
                    ? DateFormat('dd/MM/yyyy').format(startDate!)
                    : 'Selecionar Data',
              ),
            ),
            SizedBox(height: 10),
            Text('Data de Fim:'),
            ElevatedButton(
              onPressed: () async {
                final selectedEndDate = await selectDate(context);
                setState(() {
                  endDate = selectedEndDate;
                });
              },
              child: Text(
                endDate != null
                    ? DateFormat('dd/MM/yyyy').format(endDate!)
                    : 'Selecionar Data',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar o AlertDialog
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica para gerar o PDF com os registros do período selecionado
              if (startDate != null && endDate != null) {
                generateReportPDF(startDate!, endDate!);
              }
              Navigator.of(context).pop(); // Fechar o AlertDialog
            },
            child: Text('Gerar Relatório'),
          ),
        ],
      );
    },
  );
}

void generateReportPDF(DateTime startDate, DateTime endDate) async {
  final pdf = pdfWidgets.Document();
  int totalHorasTrabalhadas = 0;

  for (var registro in registros) {
    if (registro.data.isAfter(startDate) || registro.data.isAtSameMomentAs(startDate)) {
      if (registro.data.isBefore(endDate) || registro.data.isAtSameMomentAs(endDate)) {
        totalHorasTrabalhadas += registro.total.inMinutes;
      }
    }
  }

  double valorTotal = totalHorasTrabalhadas.toDouble() / 60 * valorHora;

  pdf.addPage(
    pdfWidgets.Page(
      build: (pdfWidgets.Context pageContext) => pdfWidgets.Column(
        children: [
          pdfWidgets.Header(
            level: 0,
            text: 'Relatório de Horas Trabalhadas',
          ),
          pdfWidgets.Paragraph(
            text: 'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          ),
          pdfWidgets.Paragraph(
            text: 'Valor Hora: R\$${valorHora.toStringAsFixed(2)}',
          ),
          pdfWidgets.Paragraph(
            text: 'Total de Horas Trabalhadas: ${totalHorasTrabalhadas ~/ 60} horas',
          ),
          pdfWidgets.Paragraph(
            text: 'Valor Total: R\$${valorTotal.toStringAsFixed(2)}',
          ),
          pdfWidgets.SizedBox(height: 20),
          pdfWidgets.TableHelper.fromTextArray(
            context: pageContext,
            data: <List<String>>[
              <String>['Data', 'Início', 'Fim', 'Intervalo', 'Total'],
              ...registros
                  .where((registro) =>
                      registro.data.isAfter(startDate) ||
                      registro.data.isAtSameMomentAs(startDate))
                  .where((registro) =>
                      registro.data.isBefore(endDate) ||
                      registro.data.isAtSameMomentAs(endDate))
                  .map((registro) => [
                        DateFormat('dd/MM/yyyy').format(registro.data),
                        registro.inicio.format(context),
                        registro.fim.format(context),
                        registro.intervalo.inHours.toString(),
                        registro.total.inHours.toString(),
                      ]),
            ],
            cellAlignment: pdfWidgets.Alignment.center,
          ),
        ],
      ),
    ),
  );

  final directory = await getExternalStorageDirectory();
  final path = '${directory?.path}/relatorio_horas.pdf';
  final file = File(path);
  await file.writeAsBytes(await pdf.save());

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content:  Text('PDF gerado com sucesso!'),
      action: SnackBarAction(
        label: 'Abrir',
        onPressed: () {
          OpenFile.open(path);
        },
      ),
    ),
  );
}



void _openEditModal(Registro registro) {
  DateTime editedDate = registro.data;
  DateTime editedStartTime = DateTime(
    editedDate.year,
    editedDate.month,
    editedDate.day,
    registro.inicio.hour,
    registro.inicio.minute,
  );
  DateTime editedEndTime = DateTime(
    editedDate.year,
    editedDate.month,
    editedDate.day,
    registro.fim.hour,
    registro.fim.minute,
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(editedStartTime);
      TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(editedEndTime);

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Editar Registro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data: ${DateFormat('dd/MM/yyyy').format(editedDate)}'),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => selectTime(context, selectedStartTime, (time) {
                    setState(() {
                      selectedStartTime = time;
                    });
                  }),
                  child: Text('Hora de Entrada: ${selectedStartTime.format(context)}'),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => selectTime(context, selectedEndTime, (time) {
                    setState(() {
                      selectedEndTime = time;
                    });
                  }),
                  child: Text('Hora de Saída: ${selectedEndTime.format(context)}'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  editRegistro(
                    registro,
                    selectedStartTime,
                    selectedEndTime,
                  );
                  Navigator.of(context).pop(); // Fechar o AlertDialog
                },
                child: Text('Salvar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fechar o AlertDialog
                },
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      );
    },
  );
}


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Horas'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => generatePDF(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valor Hora em Reais:',
                  style: TextStyle(fontSize: 16),
                ),
                Container(
                  width: 120,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    onChanged: (value) {
                      // Substituir vírgula por ponto
                      value = value.replaceAll(',', '.');

                      setState(() {
                        valorHora = double.parse(value);
                        //valorTotal = totalHorasTrabalhadas.inHours * valorHora;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Data:',
              style: TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () => selectDate(context),
              child: Text(
                DateFormat('dd/MM/yyyy').format(selectedDate),
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Início:',
              style: TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () => selectTime(context, selectedStartTime, (time) => selectedStartTime = time),
              child: Text(
                selectedStartTime.format(context),
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Intervalo de Almoço:',
              style: TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () => selectLunchDuration(context),
              child: Text(
                '${lunchDuration.inHours} horas',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Fim:',
              style: TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () => selectTime(context, selectedEndTime, (time) => selectedEndTime = time),
              child: Text(
                selectedEndTime.format(context),
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addRegistro,
              child: Text('Adicionar Registro'),
            ),
            SizedBox(height: 20),
            if (registros.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registros:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 300,
                    child: ListView.builder(
                      itemCount: registros.length,
                      itemBuilder: (BuildContext context, int index) {
                        final registro = registros[index];
                        return ListTile(
                          key: Key(registro.data.toString()),
                          title: Text(
                            DateFormat('dd/MM/yyyy').format(registro.data),
                          ),
                          subtitle: Text(
                            'Total: ${registro.total.inHours} horas',
                          ),
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          selected: selectedIndex == index,
                          trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _openEditModal(registro);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Confirmação'),
                                      content: Text('Tem certeza que deseja excluir esse registro?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Fechar o AlertDialog
                                          },
                                          child: Text('Não'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            deleteRegistro(registro);
                                            Navigator.of(context).pop(); // Fechar o AlertDialog
                                          },
                                          child: Text('Sim'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: deleteAllRegistros,
        label: Text('Excluir Registros'),
        icon: Icon(Icons.delete),
        backgroundColor: Colors.red,
      ),
    );
  }
}
class Registro {
  final DateTime data;
  final TimeOfDay inicio;
  final TimeOfDay fim;
  final Duration intervalo;
  final Duration total;

  Registro({
    required this.data,
    required this.inicio,
    required this.fim,
    required this.intervalo,
    required this.total,
  });
}
