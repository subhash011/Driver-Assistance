import 'package:PotholeDetector/services/auth.dart';
import 'package:PotholeDetector/shared_preference.dart';
import 'package:PotholeDetector/widgets/home.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  bool toRegister = false;
  final TextEditingController _emailController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    final emailField = TextField(
      obscureText: false,
      style: style,
      controller: _emailController,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Email",
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );
    final passwordField = TextField(
      obscureText: true,
      style: style,
      controller: _passwordController,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Password",
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );
    final loginButon = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Color(0xff01A0C7),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () async {
          String email = _emailController.text;
          String password = _passwordController.text;
          bool response;
          if (this.toRegister) {
            response = await Auth.signup(email, password);
            if (!response) {
              final snackBar = SnackBar(
                content: Text('User already exists, Please login.'),
                action: SnackBarAction(
                  label: 'Ok',
                  onPressed: () {
                    this.toRegister = false;
                    setState(() {});
                  },
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          } else {
            response = await Auth.login(email, password);
            if (response) {
              SharedPreference.setFirst();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => Home()),
              );
            } else {
              final snackBar = SnackBar(
                content: Text('Invalid username or password.'),
                action: SnackBarAction(
                  label: 'Ok',
                  onPressed: () {
                    this.toRegister = false;
                    setState(() {});
                  },
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
        },
        child: Text("Login",
            textAlign: TextAlign.center,
            style: style.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );

    final loginWidget = SingleChildScrollView(
      reverse: true,
      child: Stack(
        children: [
          Container(
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 60.0,
                    child: Image.asset(
                      "assets/images/loc.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 45.0),
                  emailField,
                  SizedBox(height: 25.0),
                  passwordField,
                  SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("First time"),
                      Checkbox(
                        value: this.toRegister,
                        onChanged: (bool value) {
                          this.toRegister = value;
                          setState(() {});
                        },
                      )
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  loginButon,
                  SizedBox(
                    height: 15.0,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );

    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      reverse: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          child: loginWidget,
        ),
      ),
    );
  }
}
