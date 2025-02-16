import 'package:bookjourney_app/Login/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bookjourney_app/api.dart';
import 'caricamento_pre_home_page.dart';

class Registrazione extends StatefulWidget {
  const Registrazione({super.key});


  @override
  _RegistrazionenPageState createState() => _RegistrazionenPageState();
}

class _RegistrazionenPageState extends State<Registrazione> {
  String _authToken = "";
  bool isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  Future<void> registration(String username, String password) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(Config.auth_login);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password, 'email': '$username@gmail.com'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await authenticate(username, password);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> authenticate(String username, String password) async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(Config.loginUrl);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _authToken = data['auth_token'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }


  Future<int?> ottengoId() async {
    final url = Uri.parse(Config.auth_me);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_authToken',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
    finally {
      setState(() {
        isLoading = false;
      });
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child:Scaffold(
      appBar: AppBar(
        title: const Text(
          'BookJourney',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF06402B),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
              child:
              Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF06402B),
                      ),
                      height: 390,
                    ),
                    Expanded(child:
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBEBEB),
                      ),
                    ),
                    ),
                  ]
              )
          ),
          Positioned(
            top: 328,
            child: ClipOval(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 120,
                color: const Color(0xFF06402B),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 60.0),
                  Image.asset(
                    'assets/images/book.png',
                    width: 70.0,
                    height: 70.0,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 70.0),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    color: Colors.white,
                    elevation: 20,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0, left: 40, right: 40, bottom: 70),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06402B),
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              contentPadding: const EdgeInsets.only(left: 10.0),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(vertical:15, horizontal: 15),
                                child: Image.asset(
                                  'assets/images/user.ico',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFF06402B),
                                  width: 3.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFF06402B),
                                  width: 5.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              contentPadding: const EdgeInsets.only(left: 10.0),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(vertical:15, horizontal: 15),
                                child: Image.asset(
                                  'assets/images/key.png',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility: Icons.visibility_off ,
                                  color: const Color(0xFF06402B),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFF06402B),
                                  width: 3.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFF06402B),
                                  width: 5.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06402B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 30.0,
                              ),
                            ),
                            onPressed: () async {
                              await registration(
                                _usernameController.text,
                                _passwordController.text,
                              );
                              int? id = await ottengoId();
                              _authToken.isNotEmpty? Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Caricamentoprehomepage(authToken: _authToken, idUtente: id!,primaVolta: true,))) : null;
                            },
                            child: isLoading
                                ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.0,
                              ),
                            )
                                : const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account?", style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF06402B),
                                fontFamily: 'Roboto',
                              ),),
                              const SizedBox(width: 5),
                              Column(children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement( context,  MaterialPageRoute( builder: (context) => const LoginPage() ),
                                    );
                                  },
                                  child:  const Text("Sign In",
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 15,
                                      color: Color(0xFF06402B),
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.bold,
                                    ),),
                                )


                              ],)
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    ));
  }
}
