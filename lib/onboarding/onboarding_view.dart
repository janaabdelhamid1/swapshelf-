import 'package:flutter/material.dart';
import 'package:swapshelf_app/main_page.dart';
import 'package:swapshelf_app/login/signin.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingView extends StatelessWidget {
  final String image;
  final String title1;
  final String title2;
  final String description;
  final int currentIndex;
  const OnboardingView({
     required this.image,
     required this.title1,
     required this.title2,
     required this.description,
     required this.currentIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0xFFFDF3E4),
        child: Container(
          margin : EdgeInsets.all(8),
          child: Column(
              children: [
                SizedBox(height: 40.h,),
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>MainPage()));
                  },
                  child: Container(
                    alignment: Alignment.topRight,
                 child: Text('skip',
                  style: GoogleFonts.dmSerifDisplay(
                    textStyle :TextStyle(
                    fontSize: 18.sp,
                    color: Colors.brown,
                    fontWeight: FontWeight.bold
                  ),
                  )
                  ),
                  ),
                  ),
                 SizedBox(height: 20.h,),
                 Container(
                  height: 360.h,
                  child: Image.asset(image)) ,  
                 Container(
                  height: 50.h,
                   child: Text(title1,
                   style:GoogleFonts.dmSerifDisplay ( textStyle:TextStyle(
                    fontSize: 35.sp,
                    color: const Color(0xfff2A0A09),
                    fontWeight: FontWeight.bold
                    
                   )),
                   ),
                 ),
                 Container(
                  height: 50.h,
                   child: Text(title2,
                   style: GoogleFonts.dmSerifDisplay ( textStyle:TextStyle(
                    fontSize: 35.sp,
                    color: const Color(0xfff2A0A09),
                    fontWeight: FontWeight.bold
                   )),
                   ),
                 ),
                 Container(
                  height: 30.h,
                  child: Text(description,
                  style: GoogleFonts.dmSerifDisplay ( textStyle:TextStyle(
                 color: const Color(0xfff2A0A09),
                 fontSize: 18.sp
      
                   ) ),
                  ),
                  
                 ),
                 SizedBox(height: 50.h,),
      
      
              
                 
              ],
          ),
        ),
      ),
    );
  }
}
  