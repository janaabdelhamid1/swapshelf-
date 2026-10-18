import 'package:flutter/material.dart';
import 'package:swapshelf_app/login/signin.dart';
class AuthPage extends StatefulWidget{
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(

        child: Signin(),
      ),
    );
  }
}