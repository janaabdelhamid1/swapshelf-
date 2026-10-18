import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swapshelf_app/login/auth.dart';
import 'package:swapshelf_app/nav_bar.dart';
class MainPage extends StatelessWidget{
  
  @override
  Widget build (BuildContext context ){
    return Scaffold(
      body: StreamBuilder<User?>(
        stream : FirebaseAuth.instance.authStateChanges(),
        builder:(context, snapshot){
          if(snapshot.hasData){
            return NavBar();
          }else{
            return AuthPage();
          }
        }
      ),
    );

  }
}