import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swapshelf_app/login/signup.dart';

class Signin extends StatefulWidget{
  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  // controllers 

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future signIn() async{
    await FirebaseAuth.instance.signInWithEmailAndPassword(
     email: emailController.text.trim(),
     password: passwordController.text.trim());
  }
@override
void dispose(){
  super.dispose();
  emailController.dispose();
  passwordController.dispose();
}
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context){
    
    return Scaffold(
     body: Container(
       height: double.infinity,
     width: double.infinity,
     decoration: BoxDecoration(
       color:  Color(0xFFFDF3E4),
     ),
        
       child: SingleChildScrollView(
         child: Padding(
           padding: const EdgeInsets.all(8.0),
           child: Column(
           
             children :[
            
             SizedBox(height: 100.h,),
             Container(
               alignment: Alignment.bottomLeft,
               child: Text('Welcome Back',
                 style : GoogleFonts.dmSerifDisplay ( textStyle: TextStyle(
                   fontSize: 35,
                   color: const Color(0xfff2A0A09),
               
                 ))
               ),
             ),
             SizedBox(height:2,),
             Container(
               alignment: Alignment.bottomLeft,
               child: Text('Sign in to continue to Swap Shelf',
                 style : GoogleFonts.dmSerifDisplay ( textStyle: TextStyle(
                   fontSize: 20,
                   color: const Color(0xfff2A0A09),
               
                 ))
               ),
             ),
             SizedBox(height: 60.h,),
             Form(
               key: formKey,
               child: 
             Column(
              children: [
               TextFormField(
                 controller: emailController,
                 decoration: InputDecoration(
                   labelText: "Email",
                   
                   hintText: "Entre Your Email",
                   focusedBorder: OutlineInputBorder(
                     borderSide: BorderSide(
                     color: const Color(0xfff2A0A09),
                   width: 2.w ,
                   
                   ),
                   ),
                   border: OutlineInputBorder(
                     borderRadius : BorderRadius.circular(20.r),
                     borderSide: BorderSide(color: Colors.grey)
                   ),
                 ),
                  validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Email is required';
                   }
                   return null;
                 },
               ),
               SizedBox(height: 20.h,),
           
               // password text form
           
               TextFormField(
                 controller: passwordController,
                 obscureText: true ,
                 decoration: InputDecoration(
                   labelText: "Password",
                   
                   hintText: "Entre Your Password",
                   focusedBorder: OutlineInputBorder(
                     borderSide: BorderSide(
                     color: const Color(0xfff2A0A09),
                   width: 2.w ,
                   
                   ),
                   ),
                   border: OutlineInputBorder(
                     borderRadius : BorderRadius.circular(20.r),
                     borderSide: BorderSide(color: Colors.grey)
                   ),
                 ),
                  validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'password is required';
                   }
                   // else if()
                   return null;
                 },
               ),
               SizedBox(height: 20.h,),
               InkWell(
                   onTap: ()async {
                   if (formKey.currentState!.validate()) {
                     await signIn();
                   }
                 },
                 child: Container(
                 height: 50.h,
                 width: 400.w,
                 decoration: BoxDecoration(
                   color: Color(0xFF79432C),
                   borderRadius: BorderRadius.circular(20.r)
                 ),
                 child: Center(
                   child: Text('SignIn',
                   style: TextStyle(color: Colors.white,
                   fontSize: 20.sp
                   ), 
                   ),
                 ),
               ),
               )
              ],
             ),
             ),
             SizedBox(height: 5.h,),
              Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children:[
               Text("Not a member ? ",
               style:TextStyle(
                 color:  Color(0xfff2A0A09),
                 fontWeight: FontWeight.bold,
               )
               ),
               GestureDetector(
                 onTap: (){
                  Navigator.push(
                   context , MaterialPageRoute(builder: (context)=>SignUp())
                  );
                 },
                 child: Text('Register now ',
                 style: TextStyle(
                   color : Colors.blue,
                   fontWeight: FontWeight.bold,
                 )
                 ),
               )
               ]
              ),
             ]
           ),
         ),
       ),
     ),
    );
  }
}