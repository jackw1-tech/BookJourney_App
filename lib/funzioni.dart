import 'package:intl/intl.dart';

class Utils {
 Map<String, dynamic> componiJsonPrimaLettura(Map libro, bool completato, double pagineAlMinutoLette) {

  Map<String, dynamic> letturaData = {
   "data_inizio_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "data_fine_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "numero_pagine_lette": completato? libro["numero_pagine"] : 0,
   "tempo_di_lettura_secondi": completato ? ( (libro["numero_pagine"] / pagineAlMinutoLette) * 60 ).toInt() : 0,
   "completato": completato? true : false,
   "iniziato": completato? false: true,
   "interrotto": false,
   "percentuale": completato? 100 : 0,
   "libro": libro["id"],
  };

  return letturaData;
 }
}