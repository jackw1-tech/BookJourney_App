import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bookjourney_app/api.dart';
import '../HomePage/HomePage.dart';

class Caricamentoprehomepage extends StatefulWidget {
  final String authToken;
  final int idUtente;
  final bool primaVolta;

  const Caricamentoprehomepage({super.key, required this.authToken, required this.idUtente, required this.primaVolta});

  @override
  CaricamentoState createState() => CaricamentoState();
}

class CaricamentoState extends State<Caricamentoprehomepage> {
  List<dynamic> preferiti = [];
  List<dynamic> booksDetail = [];
  List<dynamic> likedBooksDetail = [];
  List<dynamic> profiloLettore = [];
  List<dynamic> lettureUtente = [];
  List<dynamic> sessioniLetturaUtente = [];
  bool isLoadingDatiCompleti = true;


  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([
    [],
    [],
    [],
    [],
    [],
    [],
  ]);

  Future<void> fetchISBNPreferiti() async {
    try {
      if(widget.primaVolta)
        {
          final response_3 = await http.post(
            Uri.parse(Config.profilo_utente),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },
            body: jsonEncode({'avatar': null, 'user': widget.idUtente}),
          );

          if (response_3.statusCode == 200 || response_3.statusCode == 201) {

            String id = widget.idUtente.toString();
            String urlBaseProfilo = "${Config.utente}$id/profilo-lettore/";
            final response_3 = await http.post(
              Uri.parse(urlBaseProfilo),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },
              body: jsonEncode({
                "numero_ore_lettura": 0,
                "numero_giorni_lettura": 0,
                "numero_mesi_lettura": 0,
                "pagine_al_minuto_lette": 0.5,
                "numero_libri_letti": 0,
                "numero_libri_in_corso": 0,
                "numero_libri_interrotti": 0,
                "numero_pagine_lette": 0,
                "numero_sessioni_lettura": 0
              }),
            );
            if (response_3.statusCode != 200 && response_3.statusCode != 201) {

              return;
            }

          }

        }

      final response = await http.get(Uri.parse(Config.preferitiUrl));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List<dynamic>;
        preferiti = data;
        try {
              final response = await http.get(
                Uri.parse(Config.libroUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                final data = json.decode(response.body);
                booksDetail= data;
              }
            } catch (e) {}



        String urlBaseProfilo = Config.profilo_lettoreURL;
        String profiloLettoreUrl = '$urlBaseProfilo${widget.idUtente}/';

        final response_3 = await http.get(Uri.parse(profiloLettoreUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_3.statusCode == 200 || response_3.statusCode == 201) {
          profiloLettore.add(json.decode(response_3.body));
        }

        final response_4 = await http.get(Uri.parse("${Config.lettura_utente}${widget.idUtente}/"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_4.statusCode == 200 || response_4.statusCode == 201) {
          lettureUtente = (json.decode(response_4.body));
        }

        final response_5 = await http.get(Uri.parse("${Config.dettagli_sessione_lettura}${widget.idUtente}/"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_5.statusCode == 200 || response_5.statusCode == 201) {
          sessioniLetturaUtente = (json.decode(response_5.body));
        }
        setState(() {
          isLoadingDatiCompleti = false;
        });

        dati.value[0] = preferiti;



        for (var preferito in dati.value[0]) {
          if(preferito['utente'] == widget.idUtente.toString())
            {
              var libroTrovato = booksDetail.firstWhere(
                    (libro) => libro['id'] == preferito['libro'],
                orElse: () => null,
              );


              if (libroTrovato != null) {
                likedBooksDetail.add(libroTrovato);

              }
            }

        }


        dati.value[1] = likedBooksDetail;
        dati.value[2] = profiloLettore;
        dati.value[3] = lettureUtente;
        dati.value[4] = booksDetail;
        dati.value[5] = sessioniLetturaUtente;






        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              authToken: widget.authToken,
              dati: dati,
              id_utente: widget.idUtente,
            ),
          ),
        );
      } else {
      }
    } catch (e) {
    }
  }

  @override
  void initState() {
    super.initState();
    fetchISBNPreferiti();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child:  Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Loading",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06402B),
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 30),
              if (isLoadingDatiCompleti)
                const LinearProgressIndicator(
                  minHeight: 10,
                  borderRadius: BorderRadius.all(Radius.circular(200)),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06402B)),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}
