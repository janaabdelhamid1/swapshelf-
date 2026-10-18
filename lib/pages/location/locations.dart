import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swapshelf_app/pages/location/pin_point.dart';
import 'package:url_launcher/url_launcher.dart';
class Locations extends StatefulWidget{
  @override
  State<Locations> createState() => _LocationsState();
}
Future<void> openMap(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('Could not open Google Maps');
  }
}
class _LocationsState extends State<Locations> {
  @override
  Widget build (BuildContext context){
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
      
          decoration: BoxDecoration(
            color: Color(0xFFFDF3E4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children:[
                SizedBox(height: 30.h,),
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('Locations',
                        style:  GoogleFonts.dmSerifDisplay ( textStyle: TextStyle(
                                           fontSize: 35.sp,
                                           color: const Color(0xfff2A0A09),
                        ))
                        ),
                          Text('Trusted Locations',
                         style: GoogleFonts.dmSerifDisplay ( textStyle: TextStyle(
                     fontSize: 20,
                     color: const Color(0xfff2A0A09),
                 
                   )))
                      ],
                    ),
                   Image.asset('assets/images/pics/location.png',
                  //  height: 200.h,
                   width: 200.w,) ,
                   
                  ],
                ),
                  Text('Choose your preferred meeting place when sending a swap request.\n please wait in the sprcified point  ',
                         style :  TextStyle(
                     fontSize: 18,
                     color: const Color(0xfff2A0A09),
                 
                   )),
                  SizedBox(height: 20.h,),
           
              
            
                PinPoints(
                  name: 'Tivoli Dome',
                  area: 'Sidi Gaber, Alexandria',
                  location: 'https://www.google.com/maps/search/?api=1&query=Tivoli+Dome+Alexandria',
                  image: 'https://www.holidify.com/images/cmsuploads/compressed/IMG20230101192357_20230101213745.jpg',
                ),    
                PinPoints(
                  name: 'San Stefano mall',
                  area: 'San Stefano, Alexandria',
                  location: 'https://www.google.com/maps/search/?api=1&query=San+Stefano+Grand+Plaza+Mall+Alexandria',
                  image: 'https://tse1.mm.bing.net/th/id/OIP.yrV7RsPBRTT05Qwfg_KBMgHaEK?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
                ),    
                PinPoints(
                  name: 'Green Plaza Mall',
                  area: 'Smouha, Alexandria',
                  location: 'https://www.google.com/maps/search/?api=1&query=Green+Plaza+Mall+Alexandria',
                  image: 'https://mir-s3-cdn-cf.behance.net/project_modules/1400/c465cb160664403.63b82a128bc65.jpg',
                ),    
                PinPoints(
                  name: 'City Centre Alexandria',
                  area: 'Alexandria-Cairo Desert Road',
                  location: 'https://www.google.com/maps/search/?api=1&query=City+Centre+Alexandria+Egypt',
                  image: 'https://ik.imagekit.io/mecsrweb/images/photos/main/8ee4937df04ccc7eae73731ec4565067.jpeg',
                ),    
                PinPoints(
                  name: 'Delices Patisserie',
                  area: 'Raml Station, Alexandria',
                  location: 'https://www.google.com/maps/search/?api=1&query=Delices+Patisserie+Alexandria',
                  image: 'https://images.openai.com/static-rsc-4/Ijs35VxFrpLDAkWQkYcQyv0i9VVkihIvcsQYsqV2lyzilvhnCmRpVZLYYWbMn0xmhOE9u4SK6_TTEvcSg3uVdcJrP22DAlwuf-GgPmpT6CL2ELmb2ujhVxb-aYYp0uo0GjQx0eHOWq37D9SvoNxFveWmOq71mG4TGFUvaQS-OTfMgRxuY5YevgvqJ-iVzSXx?purpose=fullsize',
                ),  
                SizedBox(height: 15,),
                Text('New places will be added soon ',
                  style:  TextStyle(
                     fontSize: 20,
                     color: const Color(0xfff2A0A09),
                 
                   )
                ),  
              ]
            ),
          ),
        ),
      ),
    );
  }
}

