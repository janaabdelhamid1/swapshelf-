import 'package:flutter/material.dart';
import 'package:swapshelf_app/onboarding/onboarding_screen.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp( SwapShelf());
}

class SwapShelf extends StatelessWidget{
@override
Widget build (BuildContext context){
  return ScreenUtilInit(
  designSize: const Size(393, 808),  
   minTextAdapt: true,
  splitScreenMode: true,  
  child: MaterialApp(
      home: OnBoardingScreen(),
    ),
  );
    

}
}