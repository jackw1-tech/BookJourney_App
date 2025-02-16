import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bookjourney_app/api.dart';
import 'package:intl/intl.dart';
import '../funzioni.dart';

class Profilo extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  final int idUtente;
  Profilo({super.key, required this.authToken, required this.dati, required this.idUtente });

  @override
  _ProfiloState createState() => _ProfiloState();
}

class _ProfiloState extends State<Profilo> {

  var utils = Utils();

  Color _getColorForStato(String stato) {

    if (stato == "completato") {
      return const Color(0xFF06402B);
    } else if (stato == "interrotto") {
      return const Color(0xFFFF0000);
    } else {
      return Colors.amber;
    }
  }


  Future<void> eliminaPreferito(String bookISBN, Map bookData) async {
    try {
      final response = await http.get(
        Uri.parse(Config.libroUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final listaLibri = json.decode(response.body) as List<dynamic>;
        for (var libro in listaLibri) {
          if (libro['isbn'] == bookISBN) {
            String idLibro = libro['id'];
            String fullUrlDettagliLibro = '${Config.libroUrl}$idLibro';
            final response2 = await http.get(
              Uri.parse(fullUrlDettagliLibro),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },);
            if (response2.statusCode == 200 || response2.statusCode == 201) {
              final libroSingolo = json.decode(response2.body);
              final response3 = await http.get(Uri.parse(Config.preferitiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },);
              if (response3.statusCode == 200 || response3.statusCode == 201) {
                final listaPreferiti = json.decode(response3.body);

                for (var pref in listaPreferiti) {
                  if (pref['libro'] == libroSingolo['id']) {
                    String idPref = pref['id'];
                    String fullUrlEliminaPref = '${Config.preferitiUrl}$idPref/';

                    final response4 = await http.delete(
                      Uri.parse(fullUrlEliminaPref),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Token ${widget.authToken}',
                      },
                    );

                    if (response4.statusCode == 200 ||
                        response4.statusCode == 204) {
                      setState(() {
                        widget.dati.value[1].removeWhere((book) {
                          bool shouldRemove = book['isbn'] == bookData['isbn'];
                          return shouldRemove;
                        });
                        widget.dati.value[0].removeWhere((preferito) {
                          bool shouldRemove = preferito['id'] == idPref;
                          return shouldRemove;
                        });
                      });
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    catch (e) {
      return;
    }
  }

  Future<void> markAsDoneBook(Map libro, bool iniziato, {Map? lettura}) async {
    List<dynamic> datiAttuali = widget.dati.value[2];


    num numeroPagineGiaLette = 0;
    if(iniziato)
      {
        for(var sessionlettuce in widget.dati.value[5])
          {
            if(sessionlettuce['libro'] == libro['id'])
              {
                numeroPagineGiaLette += sessionlettuce['numero_pagine_lette'].toInt();
              }
          }
      }

    datiAttuali[0]['numero_libri_letti'] += 1;

    var pagineAlMinutoLetteFixed =  datiAttuali[0]['pagine_al_minuto_lette'] == 0 ? 0.8 :  datiAttuali[0]['pagine_al_minuto_lette'];
    if(lettura != null) {
      datiAttuali[0]['numero_pagine_lette'] += lettura['numero_pagine_lette'] - numeroPagineGiaLette;
    } else {
      datiAttuali[0]['numero_pagine_lette'] +=  (libro['numero_pagine']);
    }

    datiAttuali[0]['numero_ore_lettura'] =
        (datiAttuali[0]['numero_pagine_lette'] /
            pagineAlMinutoLetteFixed) / 60;
    datiAttuali[0]['numero_giorni_lettura'] =
        datiAttuali[0]['numero_ore_lettura']  / 24;
    datiAttuali[0]['numero_mesi_lettura'] =
        datiAttuali[0]['numero_giorni_lettura'] / 30;



    setState(() {
      widget.dati.value[2][0] = datiAttuali[0];
    });

    String id = widget.idUtente.toString();
    String profiloLettoreUrl = '${Config.profilo_lettoreURL}$id/';

    final response = await http.put(Uri.parse(profiloLettoreUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token ${widget.authToken}',
          },
          body: jsonEncode(widget.dati.value[2][0]),

        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if(!iniziato) {
            startReading(libro, true, pagineAlMinutoLetteFixed);
          }

        }


  }

  Future<void> startReading(Map libro, bool completato, double pagineAlMinutoLette) async {

    final Map<String, dynamic> data = utils.componiJsonPrimaLettura(libro, completato, pagineAlMinutoLette);
    final Uri endpoint = Uri.parse("${Config.crea_lettura_utente}${widget.idUtente}/lettura/");
    try {
     final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
        body: jsonEncode(data),
     );
         if (response.statusCode == 200 || response.statusCode == 201){
           setState(() {
             widget.dati.value[3].add(jsonDecode(response.body));
           });
    }


    } catch (e) {
    }
  }

  Future<void> eliminaLettura(Map lettura) async {
    final start = "${Config.lettura_utente}${widget.idUtente}/" + lettura['libro'];
    final Uri endpoint = Uri.parse(start);

    final risposta = await http.delete(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${widget.authToken}',
      },
    );

    if (risposta.statusCode == 204)
      {
        setState(() {
          widget.dati.value[3].remove(lettura);
        });
      }


  }

  Future<void> interrompiLettura(Map lettura) async {
    lettura['iniziato'] = false;
    lettura['interrotto'] = true;
    final start = "${Config.lettura_utente}${widget.idUtente}/" +lettura['libro'];
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

  Future<void> riprendiLettura(Map lettura) async {
    lettura['iniziato'] = true;
    lettura['interrotto'] = false;
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
                  lettucecaricature['iniziato'] = true;
                  lettucecaricature['interrotto'] = false;
                });
              }
        }





    }


  }

  Future<void> completaLettura(Map lettura, Map libro, double pagineLetteAlMinuto) async {
    lettura['interrotto'] = false;
    lettura['interrotto'] = false;
    lettura['completato'] = true;
    lettura['data_fine_lettura'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    lettura['numero_pagine_lette'] = libro['numero_pagine'];
    lettura['percentuale'] = "100";
    lettura['tempo_di_lettura_secondi'] = (lettura['numero_pagine_lette'] * pagineLetteAlMinuto * 60).toInt();

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
            lettucecaricature['interrotto'] = false;
            lettucecaricature['iniziato'] = false;
            lettucecaricature['completato'] = true;
            lettucecaricature['data_fine_lettura'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
            lettucecaricature['numero_pagine_lette'] = libro['numero_pagine'];
            lettucecaricature['percentuale'] = "100";
            lettucecaricature['tempo_di_lettura_secondi'] = (lettucecaricature['numero_pagine_lette'] * pagineLetteAlMinuto * 60).toInt();
          });
        }
      }
      await markAsDoneBook(libro, true, lettura: lettura);

    }


  }


  void showPreferitiDialog(Map libro, Map lettura) {

    showDialog(context: context, builder: (BuildContext context) {
      return SimpleDialog(
        children: [
        SimpleDialogOption(
            onPressed: () async {
              await eliminaPreferito(libro['isbn'], libro);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Unfavorite', textAlign: TextAlign.center),
                  SizedBox(width: 5),
                  Icon(Icons.heart_broken_outlined, color: Color(0xFF06402B),)
                ]
            ),
          ),
          if(lettura["id"] == "N/A") const Divider(),
          if(lettura["id"] == "N/A") SimpleDialogOption(
            onPressed: () async {
              await startReading(libro, false, 0);
              Navigator.pop(context);
            } ,
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start reading', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.menu_book, color: Color(0xFF06402B),)
                ]
            ),
          ),
          if(lettura["id"] == "N/A") const Divider(),
          if(lettura["id"] == "N/A") SimpleDialogOption(
            onPressed: () async {
              await markAsDoneBook(libro, false);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Mark as done', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.done, color: Color(0xFF06402B),)
                ]
            ),
          ),


        ],

      );
    }
    );
  }

  void showLibreriaDialog(Map libro, Map lettura, double pagineLetteAlMinuto) {
    showDialog(context: context, builder: (BuildContext context) {
      return SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await eliminaLettura(lettura);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Remove', textAlign: TextAlign.center),
                  SizedBox(width: 5),
                  Icon(Icons.remove_circle, color: Color(0xFF06402B),)
                ]
            ),
          ),
          lettura['completato'] == false ? const Divider() : const SizedBox(),
          lettura['completato'] == false ? SimpleDialogOption(
            onPressed: () async {
              lettura['interrotto'] == false ? await interrompiLettura(lettura) : (await riprendiLettura(lettura));
              Navigator.pop(context);
            },
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  lettura['interrotto'] == false ? const Text('Stop reading', textAlign: TextAlign.center) : const Text('Resume reading', textAlign: TextAlign.center,) ,
                  const SizedBox(width: 5),
                  lettura['interrotto'] == false ? const Icon(Icons.stop_circle_rounded, color: Color(0xFF06402B),) : const Icon(Icons.restart_alt, color: Color(0xFF06402B),)
                ]
            ),
          ) : const SizedBox(),
          lettura['completato'] == false ?  const Divider() : const SizedBox(),
          lettura['completato'] == false ? SimpleDialogOption(
            onPressed: () async {
              await completaLettura(lettura, libro, pagineLetteAlMinuto);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Complete', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.incomplete_circle, color: Color(0xFF06402B),)
                ]
            ),
          ) : const SizedBox(),


        ],

      );
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    var months = widget.dati.value[2][0]['numero_mesi_lettura'] >= 1 ? widget.dati.value[2][0]['numero_mesi_lettura'] : 0;
    var days = widget.dati.value[2][0]['numero_giorni_lettura']>=1 ? widget.dati.value[2][0]['numero_giorni_lettura'] - (months * 30) : 0;
    var hours = widget.dati.value[2][0]['numero_ore_lettura'] - (days.truncate() * 24);


    return PopScope(
        canPop: false,
        child:  NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      width: 500,
                      height: 200,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_sharp),
                              SizedBox(width: 10),
                              Text(
                                'Reading time',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${months.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Months',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 50),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${days.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Days',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 50),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${hours.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Hours',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          Column(
                            children: [
                              Text(
                                '${widget.dati.value[2][0]['numero_libri_letti'].toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Books Readed',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Libri preferiti:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  widget.dati.value[1].isNotEmpty ? SizedBox(
                    height: 380,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dati.value[1].length,
                      itemBuilder: (context, index) {
                        var book = widget.dati.value[1][index] ?? '';
                        var imageUrl = book['copertina_url'];
                        var titolo = book['titolo'];

                        var letturaTrovata = widget.dati.value[3].firstWhere(
                              (elemento) => elemento['libro'] == book['id'],
                          orElse: () => {'id': "N/A"}
                        );

                        return GestureDetector(
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                color: Colors.black,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 150,
                                child: Column(
                                  children: [
                                    imageUrl.isNotEmpty
                                        ? Image.network(imageUrl)
                                        : const Center(child: Icon(Icons.image, size: 30)),
                                    const SizedBox(height: 10),
                                    Text('$titolo'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            showPreferitiDialog(book, letturaTrovata);
                          },
                        );
                      },
                    ),
                  ) : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Image.asset(
                          'assets/images/wounded-heart.png',
                          width: 100,
                          height: 100,
                        ),
                          const Text("No books in favorites", style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),)],
                      )
                  ]),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Libreria:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  widget.dati.value[3].isNotEmpty ? SizedBox(
                    height: 380,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dati.value[3].length,
                      itemBuilder: (context, index) {
                        var libroTrovato = widget.dati.value[4].firstWhere(
                              (elemento) => elemento['id'] == widget.dati.value[3][index]['libro'],
                          orElse: () => null,
                        );

                        var letturaTrovata = widget.dati.value[3].firstWhere(
                              (elemento) => elemento['libro'] == libroTrovato['id'],
                          orElse: () => null,
                        );

                        var imageUrl = libroTrovato['copertina_url'];
                        var titolo = libroTrovato['titolo'];
                        var stato = widget.dati.value[3][index]["completato"] == true
                            ? "completato"
                            : widget.dati.value[3][index]["interrotto"] == true
                            ? "interrotto"
                            : "iniziato";

                        return GestureDetector(
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 150,
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        imageUrl.isNotEmpty
                                            ? Image.network(imageUrl)
                                            : const Center(child: Icon(Icons.image, size: 30)),
                                        const SizedBox(height: 10),
                                        Text('$titolo'),
                                      ],
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Stack(
                                        children: [
                                          LinearProgressIndicator(
                                            value: double.parse(widget.dati.value[3][index]["percentuale"]) / 100,
                                            minHeight: 20,
                                            color: _getColorForStato(stato),
                                          ),

                                          Positioned.fill(
                                            child: Center(
                                              child: Text(
                                                '${double.parse(widget.dati.value[3][index]["percentuale"])}%',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            showLibreriaDialog(libroTrovato,letturaTrovata, widget.dati.value[2][0]['pagine_al_minuto_lette']);
                          },
                        );
                      },
                    ),
                  )  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Image.asset(
                              'assets/images/library.png',
                              width: 100,
                              height: 100,
                            ),
                            const Text("No books in the library", style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),)],
                        )
                      ]),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
