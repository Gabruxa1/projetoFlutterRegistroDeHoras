import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(RegistroPontoApp());
}

class RegistroPontoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Ponto',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      supportedLocales: [
        const Locale('en', 'US'), // Adicione outras localizações, se necessário
      ],
      home: RegistroPontoScreen(),
    );
  }
}

class RegistroPontoScreen extends StatelessWidget {
  final TextEditingController entradaController = TextEditingController();
  final TextEditingController saidaController = TextEditingController();
  final TextEditingController almocoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Ponto'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: entradaController,
              decoration: InputDecoration(
                labelText: 'Hora de Entrada',
              ),
            ),
            TextField(
              controller: saidaController,
              decoration: InputDecoration(
                labelText: 'Hora de Saída',
              ),
            ),
            TextField(
              controller: almocoController,
              decoration: InputDecoration(
                labelText: 'Horas de Almoço',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Lógica para registrar as horas trabalhadas
                String entrada = entradaController.text;
                String saida = saidaController.text;
                String almoco = almocoController.text;

                // Fazer os cálculos e a lógica necessária para registrar as horas trabalhadas
              },
              child: Text('Registrar'),
            ),
            ElevatedButton(
              onPressed: () {
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2021),
                  lastDate: DateTime(2025),
                  locale: Locale('pt', 'BR'), // Defina a localização desejada como 'pt_BR'
                ).then((selectedDate) {
                  if (selectedDate != null) {
                    String formattedDate =
                        DateFormat.yMMMMd('pt_BR').format(selectedDate);
                    // Use formattedDate conforme necessário
                    print(formattedDate);
                  }
                });
              },
              child: Text('Selecionar Data'),
            ),
          ],
        ),
      ),
    );
  }
}
