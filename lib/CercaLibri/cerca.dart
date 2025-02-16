import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bookjourney_app/api.dart';

class CercaLibri extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  final int idUtente;
  CercaLibri({super.key, required this.authToken, required this.dati, required this.idUtente});


  @override
  _CercaLibriState createState() => _CercaLibriState();
}

class _CercaLibriState extends State<CercaLibri> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _books = [];
  bool isSearch = false;
  bool isLoadingLike = false;
  List<String> isbnPreferiti = [];

  String getCoverUrl(Map<String, dynamic> book) {

    if (book['volumeInfo'] != null && book['volumeInfo']['imageLinks'] != null) {

      String coverUrl = book['volumeInfo']['imageLinks']['large'] ??
          book['volumeInfo']['imageLinks']['medium'] ??
          book['volumeInfo']['imageLinks']['thumbnail'] ?? '';

      return coverUrl;
    } else {
      return '';
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
                    String fullUrlEliminaPref = '${Config
                        .preferitiUrl}$idPref/';

                    final response4 = await http.delete(
                      Uri.parse(fullUrlEliminaPref),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Token ${widget.authToken}',
                      },
                    );

                    if (response4.statusCode == 200 || response4.statusCode == 204) {
                      setState(() {
                        isbnPreferiti.remove((bookISBN));
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

  void toggleLike(String bookISBN, Map bookData) async {
    setState(() {
      isLoadingLike = true;
    });
    if (isbnPreferiti.contains(bookISBN)) {
      await eliminaPreferito(bookISBN, bookData);

    } else {
      var libro = await mettiLike(bookData["google_books_id"], bookData);
      widget.dati.value[1].add(libro);
      widget.dati.value[4].insert(widget.dati.value[4].length,libro);
      isbnPreferiti.add(bookISBN);
    }
    setState(() {
      isLoadingLike = false;
    });
  }

  Future<void> fetchBooks(String query) async {

    if(isbnPreferiti.isEmpty){
      for(var libro in widget.dati.value[1]){
        isbnPreferiti.add(libro["isbn"]);
      }
    }


    setState(() {
      isSearch = true;
    });




    final String apiKey = dotenv.env['API_KEY'] ?? '';
    const String endpoint = 'https://www.googleapis.com/books/v1/volumes';
    final String url = '$endpoint?q=$query&key=$apiKey';

    try {

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data["items"] != null) {
          setState(() {
            _books = data["items"];
            isSearch = false;
          });
        }

      }
    }
    finally
        {
          setState(() {
            isSearch = false;
          });
        }
  }



  Future<Map<dynamic,dynamic>?> mettiLike(String id, Map libro) async {

    String libroUrl = dotenv.env['LIBRO'] ?? '';
    try {

      final response = await http.get(
        Uri.parse(libroUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var libroDb in jsonDecode(response.body)) {
          if (libroDb['isbn'].toString() == libro['isbn'].toString()) {
            try{
              final response = await http.get(
                  Uri.parse(Config.preferitiUrl),
                  headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
              },);
              if (response.statusCode == 200 || response.statusCode == 201) {
                for (var preferitoDb in jsonDecode(response.body)) {
                  if (preferitoDb['libro'].toString() == libroDb['id'].toString() &&
                      preferitoDb['utente'].toString() == widget.idUtente.toString() )
                  {
                    return libroDb;
                  }
                }
              }

            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Si è verificato un errore: $e')),
              );
              }

            String id = widget.idUtente.toString();
            String api = dotenv.env['UTENTE'] ?? '';
            String preferiti = '$api$id/preferiti/';

            String idLibro = libroDb['id'];
            try {
              final body = jsonEncode({'libro': idLibro});

              final response = await http.post(
                Uri.parse(preferiti),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },
                body: body,
              );

              if (response.statusCode == 200 ||
                  response.statusCode == 201) {
                var responseData = jsonDecode(response.body);
                widget.dati.value[0].add(responseData);
                return libroDb;
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Si è verificato un errore: $e')),
              );
            }


          }
        }



        try {
          final body = jsonEncode(libro);
          final response = await http.post(
            Uri.parse(libroUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            },
            body: body,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            try {
              final response = await http.get(
                Uri.parse(libroUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },
              );

              if (response.statusCode == 200 || response.statusCode == 200) {
                for (libro in jsonDecode(response.body)) {
                  if (libro['google_books_id'] == id) {
                    String api = dotenv.env['UTENTE'] ?? '';
                    String idUtente = widget.idUtente.toString();
                    String preferiti = '$api$idUtente/preferiti/';
                    String idLibro = libro['id'];
                    try {
                      final body = jsonEncode({'libro': idLibro});

                      final response = await http.post(
                        Uri.parse(preferiti),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Token ${widget.authToken}',
                        },
                        body: body,
                      );

                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        var responseData = jsonDecode(response.body);
                        widget.dati.value[0].add(responseData);
                        return libro;
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Si è verificato un errore: $e')),
                      );
                    }
                  }
                }
              } else {
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Si è verificato un errore: $e')),
              );
            }
          } else {
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Si è verificato un errore: $e')),
          );
        }
      }
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Si è verificato un errore: $e')),
      );
    }
    return null;


  }




  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child:CustomScrollView(
      slivers: [
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

    SliverToBoxAdapter( child:
    Padding(

    padding: const EdgeInsets.only(left: 20, right: 20),
    child:Column(
        children: [
      const SizedBox(height: 10.0),
      TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search books',
          prefixIcon: GestureDetector( child: const Icon(Icons.search ), onTap : (){
            if (_controller.text.isEmpty)
              {
                setState(() {
                  _books = [];
                });
              }
            else {
              fetchBooks(_controller.text);
            }}),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF06402B),
              width: 3.0,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF06402B),
              width: 5.0,
            ),
          ),
        ),
      ),
          const SizedBox(height: 10.0),
          Text(
            _books.isNotEmpty? 'Results:' : '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          isSearch ? const CircularProgressIndicator(color: Color(0xFF06402B),) : const SizedBox(height: 0.0),
    ],
    )
    ),
    ),

       _books.isNotEmpty?  SliverList(
          delegate: SliverChildBuilderDelegate(

                (BuildContext context, int index) {
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 42,
                        height: 120,
                        child: (_books[index]['volumeInfo']['imageLinks']?['thumbnail'] != null)
                            ? Image.network(
                          _books[index]['volumeInfo']['imageLinks']?['thumbnail'] ?? '',
                          fit: BoxFit.fill,
                        )
                            : Image.asset(
                          'assets/images/img.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      _books[index]['volumeInfo']['title'] ?? 'N/A',
                    ),
                    subtitle: Text(
                      'Author: ${_books[index]['volumeInfo']['authors']?.first ?? 'N/A'}',
                    ),
                    trailing: GestureDetector(

                      onTap: isLoadingLike
                          ? null : () {
                        Map<String, dynamic> libro = {
                          "titolo": _books[index]['volumeInfo']['title'] ?? 'N/A',
                          "autore": (_books[index]['volumeInfo']['authors'] != null &&
                              _books[index]['volumeInfo']['authors'] is List)
                              ? _books[index]['volumeInfo']['authors']?.join(', ') ?? 'N/A'
                              : 'N/A',
                          "numero_pagine": _books[index]['volumeInfo']['pageCount'] ?? 0,
                          "copertina": null,
                          "descrizione": _books[index]['volumeInfo']['description'] ?? 'N/A',
                          "data_pubblicazione": null,
                          "google_books_id": _books[index]['id'] ?? 'N/A',


                        "copertina_url": getCoverUrl(_books[index]),
                          "link_esterna":
                          _books[index]['volumeInfo']['canonicalVolumeLink'] ?? '',
                          "isbn": (_books[index]['volumeInfo']['industryIdentifiers'] !=
                              null &&
                              _books[index]['volumeInfo']['industryIdentifiers'] is List &&
                              _books[index]['volumeInfo']['industryIdentifiers']
                                  .isNotEmpty)
                              ? _books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'] ??
                              'N/A'
                              : 'N/A',
                          "categoria": null,
                        };
                        toggleLike(libro["isbn"], libro);

                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.favorite,
                          color: _books[index]['volumeInfo'] != null &&
                              _books[index]['volumeInfo']['industryIdentifiers'] != null &&
                              _books[index]['volumeInfo']['industryIdentifiers'].isNotEmpty &&
                              _books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'] != null &&
                              isbnPreferiti.contains(_books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'])
                              ? Colors.red
                              : Colors.grey,
                        ),
                      )

                    ),
                  );
                },
            childCount: _books.length
          ),
        ) :SliverToBoxAdapter(
         child: Container(
         ),
       )

      ],
    ));
  }
}