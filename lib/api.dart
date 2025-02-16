import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static String loginUrl = dotenv.env['LOGIN_URL'] ?? '';
  static String libroUrl = dotenv.env['LIBRO'] ?? '';
  static String preferitiUrl = dotenv.env['PREFERITI'] ?? '';
  static String profilo_lettoreURL = dotenv.env['PROFILOLETTORE'] ?? '';
  static String lettura_utente = dotenv.env['LETTURA_UTENTE'] ?? '';
  static String crea_lettura_utente = dotenv.env['CREA_LETTURA'] ?? '';
  static String crea_sessione_lettura = dotenv.env['CREA_SESSIONE_LETTURA'] ?? '';
  static String dettagli_sessione_lettura = dotenv.env['DETTAGLI_SESSIONE_LETTURA'] ?? '';
  static String profilo_utente = dotenv.env['PROFILO_UTENTE'] ?? '';
  static String utente = dotenv.env['UTENTE'] ?? '';
  static String auth_me = dotenv.env['AUTH_ME'] ?? '';
  static String auth_login = dotenv.env['AUTH_LOGIN'] ?? '';
}