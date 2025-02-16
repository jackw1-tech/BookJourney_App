import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bookjourney_app/api.dart';
import 'dart:math';
import 'sessione_lettura.dart';

class SemiCircleProgress extends StatelessWidget {
  final double progress;

  const SemiCircleProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 50),
      painter: SemiCirclePainter(progress),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double progress;

  SemiCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final Paint progressPaint = Paint()
      ..color = const Color(0xFF06402B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height);


    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Lettureincorso extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  int idUtente;

  int secondsElapsed = 0;
  Lettureincorso({super.key, required this.authToken, required this.dati, required this.idUtente });

  @override
  _LettureInCorsoState createState() => _LettureInCorsoState();
}

class _LettureInCorsoState extends State<Lettureincorso> {


  Future<void> interrompiLettura(Map lettura) async {
    lettura['iniziato'] = false;
    lettura['interrotto'] = true;
    final start = "${Config.lettura_utente}${widget.idUtente}/" + lettura['libro'];
    final Uri endpoint = Uri.parse(start);
    final risposta = await http.put(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
        body: jsonEncode(lettura)
    );
    if(risposta.statusCode == 200 || risposta.statusCode == 201)
    {
      for(var lettucecaricature in widget.dati.value[3] )
      {
        if (lettucecaricature['id'] == lettura['id'])
        {
          setState(() {
            lettucecaricature['iniziato'] = false;
            lettucecaricature['interrotto'] = true;
          });
        }
      }


    }


  }



  void showLetturaDialog(Map libro, Map lettura) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () async {
                  await interrompiLettura(lettura);
                  Navigator.pop(context);
                },
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Stop reading', textAlign: TextAlign.center,),
                      SizedBox(width: 5),
                      Icon(Icons.stop_circle_rounded, color: Color(0xFF06402B),)
                    ]
                ),
              ),
              const Divider(),
              SimpleDialogOption(
                onPressed: () async {
                  await showSessioneLetturaDialog(libro, lettura);
                  setState(() {
                    widget.dati;
                  });
                  },
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start reading session', textAlign: TextAlign.center,),
                      SizedBox(width: 5),
                      Icon(Icons.incomplete_circle, color: Color(0xFF06402B),)
                    ]
                ),
              ),
            ],
          );
        }
    );
  }


  Future<void> showSessioneLetturaDialog(Map libro, Map lettura) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TimerDialog(authToken:  widget.authToken,dati: widget.dati, libro: libro, lettura: lettura, idUtente:  widget.idUtente,);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var lettureNotComplete = [];

    for (var lettura in  (widget.dati.value[3])) {
      if (lettura['completato'] == false && lettura['interrotto'] == false) {
        lettureNotComplete.add(lettura);
      }
    }

    return  PopScope(
        canPop: false,
        child: ValueListenableBuilder(
        valueListenable: widget.dati,
        builder: (context, dati, child) {
          return NestedScrollView(
            headerSliverBuilder: (BuildContext context,
                bool innerBoxIsScrolled) {
              return <Widget>[
                const SliverAppBar(
                  title: Text(
                    'BookJourney',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Color(0xFF06402B),
                  centerTitle: true,
                  floating: true,
                ),
              ];
            },
            body: lettureNotComplete.isNotEmpty ?SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.8,
                          child: ListView.builder(
                            itemCount: (lettureNotComplete.length),
                            itemBuilder: (context, index) {
                              var libroTrovato = widget.dati.value[4]
                                  .firstWhere(
                                    (elemento) =>
                                elemento['id'] ==
                                    lettureNotComplete[index]['libro'],
                                orElse: () => null,
                              );
                              var letturaTrovata = widget.dati.value[3]
                                  .firstWhere(
                                      (elemento) =>
                                  elemento['libro'] == libroTrovato['id'],
                                  orElse: () => {'id': "N/A"}
                              );
                              var pagineRimaste = libroTrovato['numero_pagine'] -
                                  lettureNotComplete[index]['numero_pagine_lette'];
                              var tempoLetturaSecondi = lettureNotComplete[index]['tempo_di_lettura_secondi'];
                              var numeroOreLettura = tempoLetturaSecondi ~/
                                  3600;
                              var numeroMinutiLettura = (tempoLetturaSecondi ~/
                                  60) - (numeroOreLettura * 60);
                              return GestureDetector(
                                child: Card(
                                  elevation: 5,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      libroTrovato['copertina_url'].isNotEmpty
                                          ? Image.network(
                                          libroTrovato['copertina_url'])
                                          : const Center(
                                          child: Icon(Icons.image, size: 30)),
                                      const SizedBox(width: 20),
                                      Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 20),
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: SemiCircleProgress(
                                                  progress: (double.parse(
                                                      lettureNotComplete[index]['percentuale']) /
                                                      100)),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text("$pagineRimaste page left",
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          const Text("Booking time:"),
                                          Row(
                                            children: [
                                              Text("$numeroOreLettura hours",
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold)),
                                              const SizedBox(width: 5),
                                              Text(
                                                  "$numeroMinutiLettura minutes",
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold)),
                                            ],
                                          ),
                                          const SizedBox(width: 200, height: 20)
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  showLetturaDialog(
                                      libroTrovato, letturaTrovata);
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ) : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [   Image.asset(
                    'assets/images/empty-folder.png',
                    width: 150,
                    height: 150,
                  ),
                    const Text("No reading in progress", style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),)],
                )

          ]
            ),
          );
        }
      ));
  }
}
