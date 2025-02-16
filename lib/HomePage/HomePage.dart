import 'package:bookjourney_app/LettureInCorso/letture_in_corso.dart';
import 'package:flutter/material.dart';
import 'package:bookjourney_app/CercaLibri/cerca.dart';
import 'package:bookjourney_app/Profilo/profilo.dart';

class HomePage extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  final int id_utente;
  HomePage({super.key, required this.authToken, required this.dati, required this.id_utente});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: widget.dati, builder: (context, value, child)
    {
      return PopScope(
          canPop: false,
          child:
          DefaultTabController(
        length: 3,
        child: Scaffold(
          body: TabBarView(
            children: [
             Lettureincorso(authToken: widget.authToken, dati: widget.dati, idUtente: widget.id_utente,),
              CercaLibri(authToken: widget.authToken, dati: widget.dati, idUtente: widget.id_utente,),
              Profilo(authToken: widget.authToken, dati: widget.dati, idUtente: widget.id_utente,)
            ],
          ),
          bottomNavigationBar: const BottomAppBar(
            height: 60,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
            color: Colors.white,
            child: TabBar(
              indicatorColor: Color(0xFF06402B),
              labelColor: Color(0xFF06402B),
              unselectedLabelColor: Colors.black,
              indicatorWeight: 5,
              tabs: [
                Tab(icon: Icon(Icons.book_outlined)),
                Tab(icon: Icon(Icons.search)),
                Tab(icon: Icon(Icons.person)),
              ],
            ),
          ),
        ),
      ) )
    ;
    });
  }
}
