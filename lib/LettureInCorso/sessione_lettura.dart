import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../api.dart';
import 'package:http/http.dart' as http;




class TimerDialog extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  Map libro;
  Map lettura;
  final int idUtente;

  TimerDialog({super.key, required this.authToken, required this.dati, required this.libro, required this.lettura, required this.idUtente });
  @override
  _TimerDialogState createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  bool isVisible = true;


  int secondsElapsed = 0;
  Timer? _timer;
  bool _timerStarted = false;


  void _startTimer() {
    if (!_timerStarted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          secondsElapsed++;
        });
      });
      _timerStarted = true;
    }
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timerStarted = false;
    }
  }

  Future<void> inserisciSessioneLettura(Map lettura, Map libro, int numeroPagina, int tempoInSecondi) async {

    Map<dynamic,dynamic> sessioneLettura = {};
    sessioneLettura['libro'] = libro['id'];
    sessioneLettura['numero_pagine_lette'] = numeroPagina - lettura['numero_pagine_lette'];
    sessioneLettura['tempo_in_secondi'] = tempoInSecondi;
    sessioneLettura['tempo_in_minuti'] = tempoInSecondi ~/ 60;
    sessioneLettura['pagine_al_minuto_lette'] = (((sessioneLettura['numero_pagine_lette'] / sessioneLettura['tempo_in_minuti']) * 100).truncate())/100;


    final start = "${Config.crea_sessione_lettura}${widget.idUtente}/sessione-lettura/";
    final Uri endpoint = Uri.parse(start);
    final risposta = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
        body: jsonEncode(sessioneLettura)
    );
    if(risposta.statusCode == 200 || risposta.statusCode == 201) {
      var sessioneLetturaInserita = jsonDecode(risposta.body);

      widget.dati.value[5].add(sessioneLetturaInserita);



      var letturaTrovata = widget.dati.value[3].firstWhere(
            (elemento) =>
        elemento['libro'] == sessioneLetturaInserita['libro'],
        orElse: () => null,
      );


      var index_1 = widget.dati.value[3].indexOf(letturaTrovata);
      letturaTrovata['numero_pagine_lette'] = numeroPagina;
      letturaTrovata['tempo_di_lettura_secondi'] += tempoInSecondi;
      letturaTrovata['percentuale'] =
          ((letturaTrovata['numero_pagine_lette'] / libro['numero_pagine']) *
              100).toStringAsFixed(2);

      if (letturaTrovata['numero_pagine_lette'] >= libro['numero_pagine']) {
        letturaTrovata['numero_pagine_lette'] = libro['numero_pagine'];
        letturaTrovata['percentuale'] = ("100");
        letturaTrovata['completato'] = true;
        letturaTrovata['data_fine_lettura'] =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        widget.dati.value[2][0]['numero_libri_letti'] += 1;
        String id = widget.idUtente.toString();
        final start_1 = '${Config.profilo_lettoreURL}$id/';
        await http.put(
            Uri.parse(start_1),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            },
            body: jsonEncode(widget.dati.value[2][0])
        );
      }
      setState(() {
        widget.dati.value[3][index_1] = letturaTrovata;
      });

      final start_2 = "${Config.lettura_utente}${widget.idUtente}/" +
          sessioneLetturaInserita['libro'];
      final Uri endpoint_2 = Uri.parse(start_2);
      final risposta_2 = await http.put(
          endpoint_2,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token ${widget.authToken}',
          },
          body: jsonEncode(letturaTrovata)
      );
      if (risposta_2.statusCode == 200 || risposta_2.statusCode == 201) {

      }

      widget.dati.value[2][0]['numero_sessioni_lettura'] += 1;
      widget.dati.value[2][0]['numero_pagine_lette'] +=
      sessioneLettura['numero_pagine_lette'];

      var ore = sessioneLettura['tempo_in_minuti'] / 60;
      widget.dati.value[2][0]['numero_ore_lettura'] += ore;

      var giorni = ore / 24;
      widget.dati.value[2][0]['numero_giorni_lettura'] += giorni;

      var mesi = giorni / 30;
      widget.dati.value[2][0]['numero_mesi_lettura'] += mesi;

      widget.dati.value[2][0]['pagine_al_minuto_lette'] =
          widget.dati.value[2][0]['numero_pagine_lette'] /
              (widget.dati.value[2][0]['numero_ore_lettura'] * 60);

      String id = widget.idUtente.toString();
      final start_3 = '${Config.profilo_lettoreURL}$id/';
      await http.put(
          Uri.parse(start_3),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token ${widget.authToken}',
          },
          body: jsonEncode(widget.dati.value[2][0])
      );

      Navigator.pop(context);
      Navigator.pop(context);
    }






  }


  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }



  void _askPageNumber(BuildContext context, int sessionDuration, Map lettura) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
            canPop: false,
            child: AlertDialog(
          title: const Text("Session Completed", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold , color: Color(0xFF06402B)),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/lottie/Animation - 1736622026338.json',
                repeat: false,
                width: 80,
                height: 100,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Errore nel caricamento dell\'animazione');
                },),

              Text("You have read for ${sessionDuration ~/ 60} minutes"),
              const SizedBox(height: 30),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter the page number reached",
                    labelStyle: TextStyle(color: Color(0xFF06402B),fontSize: 15),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF06402B), width: 2.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
                    ),

                  ),

                ),
              )

            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final pageNumber = int.tryParse(controller.text);
                if (pageNumber != null && pageNumber >  lettura['numero_pagine_lette']) {
                  await inserisciSessioneLettura(widget.lettura, widget.libro, pageNumber, secondsElapsed);
                }  else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Invalid Input"),
                      content: const Text("Please enter a valid number."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text("Save", style: TextStyle(color: Color(0xFF06402B)),),
            ),
          ],
        ));
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
        canPop: false,
        child: Visibility(
        visible: isVisible,
        child: Dialog(

      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reading session time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 30),
            Text(
              "${(secondsElapsed ~/ 3600).toString().padLeft(2, '0')}:${((secondsElapsed % 3600) ~/ 60).toString().padLeft(2, '0')}:${(secondsElapsed % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 35),
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 15,
              width: 250,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: LinearProgressIndicator(
                  value: (secondsElapsed / 1200),
                  minHeight: 15,
                  color: const Color(0xFF06402B),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _stopTimer();
                    Navigator.pop(context);
                  },

                  child: const Text('Cancel', style: TextStyle(color: Colors.red),),
                ),
                const SizedBox(width: 10),

                TextButton(
                  onPressed: (secondsElapsed >=60 ) ? () async {
                    _stopTimer();
                    setState(() {
                      isVisible = false;
                    });
                    _askPageNumber(context, secondsElapsed, widget.lettura);
                  } : null,
                  child: const Text('End session', style: TextStyle(color: Colors.black),),
                ),
              ],
            )
          ],
        ),
      ),
    )
    ));
  }
}

