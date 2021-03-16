import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/homepage.dart';
import 'package:flutter_application_1/sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(alignment: Alignment.center, children: [
        Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [Colors.green, Colors.white]))),
        Container(
            margin: EdgeInsets.only(bottom: 215.0),
            child: Center(
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                          image: AssetImage("assets/images/tick.png"),
                          height: 110.0,
                        )
                      ],
                    ),
                    Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 55.0, vertical: 15.0),
                      child: Text(
                        'Welcome! Start keeping track of your tasks on your own or with your friends today.',
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ))
                  ]),
            )),
        SignInButton()
      ]),
    );
  }
}

class SignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 70.0,
        child: OutlinedButton(
          onPressed: () {
            signInWithGoogle().then((result) => {
                  if (result != null)
                    {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return Homepage(userId: result.uid);
                      }))
                    }
                });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                    image: AssetImage("assets/images/google_logo.png"),
                    height: 30.0),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              ],
            ),
          ),
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)))),
        ));
  }
}
