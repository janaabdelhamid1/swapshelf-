import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
class VerifyEmail extends StatelessWidget{
  @override 
  Widget build(BuildContext context){
    return Scaffold(
      body :Container(
       height: double.infinity,
       width: double.infinity,
       color:  Color(0xFFFDF3E4),
       child: Padding(padding: EdgeInsets.all(8),
       child: Column(
        children: [
          SizedBox(height: 100.h,),
          Image.asset('assets/images/signup_pics/Envelope.png'),
          Text('Verify Your Email',
          style:  GoogleFonts.dmSerifDisplay ( textStyle: TextStyle(
                   fontSize: 35,
                   color: const Color(0xfff2A0A09),
                   
                 )),
          ),
          
          
        ],
       ),),
      )
    );
    }
    }