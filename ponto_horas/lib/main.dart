import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';

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

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedStartTime = TimeOfDay.now();
    lunchDuration = Duration();
    selectedEndTime = TimeOfDay.now();
  }

  void selectDate(BuildContext context) async {
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
      valorTotal = totalHorasTrabalhadas.inHours * valorHora;
    });
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
  }

  void generatePDF(BuildContext context) async {
  final pdf = pdfWidgets.Document();

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
            text: 'Total de Horas Trabalhadas: ${totalHorasTrabalhadas.inHours} horas',
          ),
          pdfWidgets.Paragraph(
            text: 'Valor Total: R\$${valorTotal.toStringAsFixed(2)}',
          ),
          pdfWidgets.SizedBox(height: 20),
          pdfWidgets.TableHelper.fromTextArray(
            data: <List<String>>[
              <String>['Data', 'Início', 'Fim', 'Intervalo', 'Total'],
              ...registros.map((registro) => [
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
      content: Text('PDF gerado com sucesso!'),
      action: SnackBarAction(
        label: 'Abrir',
        onPressed: () {
          OpenFile.open(path);
        },
      ),
    ),
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
                  'Valor Hora:',
                  style: TextStyle(fontSize: 16),
                ),
                Container(
                  width: 120,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    onChanged: (value) {
                      setState(() {
                        valorHora = double.parse(value);
                        valorTotal = totalHorasTrabalhadas.inHours * valorHora;
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
                          title: Text(
                            DateFormat('dd/MM/yyyy').format(registro.data),
                          ),
                          subtitle: Text(
                            'Total: ${registro.total.inHours} horas',
                          ),
                          onTap: () {
                            setState(() {
                              selectedRegistro = registro;
                            });
                          },
                          selected: selectedRegistro == registro,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  if (selectedRegistro != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(selectedRegistro!.data)}',
                        ),
                        Text(
                          'Início: ${selectedRegistro!.inicio.format(context)}',
                        ),
                        Text(
                          'Fim: ${selectedRegistro!.fim.format(context)}',
                        ),
                        Text(
                          'Intervalo: ${selectedRegistro!.intervalo.inHours} horas',
                        ),
                        Text(
                          'Total: ${selectedRegistro!.total.inHours} horas',
                        ),
                      ],
                    ),
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
