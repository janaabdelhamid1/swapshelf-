import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:swapshelf_app/main_page.dart';
import 'package:swapshelf_app/onboarding/onboarding_view.dart';
class OnBoardingScreen extends StatefulWidget{
  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  PageController _controller =PageController();
  bool onLastPage = false;
  bool onFirstPage = true;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body:
      Stack(
        children: [
           PageView(
            onPageChanged: (index){
              setState(() {
                onLastPage = (index==2);
                onFirstPage = (index == 0);
              });
            },
            
            controller: _controller,
            
        children: [
          
          OnboardingView(image: 'assets/images/onboarding/onboarding1.png',title1:'Welcome to' ,title2:'Swap Shelf'  ,description:'Discover books. Share stories' ,currentIndex: 0,),
          OnboardingView(image: 'assets/images/onboarding/onboarding2.png',title1:'A New Home' ,title2:'For Every Book'  ,description:'Discover books. Share stories' ,currentIndex: 1,),
          OnboardingView(image: 'assets/images/onboarding/onboarding3.png',title1:' Connect' ,title2:'Through Books'  ,description:'Discover books. Share stories' ,currentIndex: 2,),
       
        ],
      ),
      // dot indicator
      Container(

        alignment: Alignment(0,0.75),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
           if(!onFirstPage) InkWell(
              onTap: (){
                _controller.previousPage(duration: Duration(milliseconds: 500), curve: Curves.easeIn);
              },
              child: Text('Back',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xfff2A0A09),
                fontWeight: FontWeight.bold
              ),
              )
              ),

              
            SmoothPageIndicator(controller: _controller, count: 3,
               effect: WormEffect(
                dotColor: Color(0xFF7B8791),
                activeDotColor: Color(0xFF35120F),)),
            onLastPage ? 
            InkWell(
                onTap: (){
                 Navigator.push(context, MaterialPageRoute(builder: (context)=>MainPage())
                );              },
              child: Text('Start',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xfff2A0A09),
                fontWeight: FontWeight.bold
              ),
              )
              ):
                InkWell(
                onTap: (){
                _controller.nextPage(duration: Duration(milliseconds: 500), curve: Curves.easeIn);
              },
              child: Text('Next',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xfff2A0A09),
                fontWeight: FontWeight.bold
              ),
              )
              ),

          ],
        )),
        ],
      )
      
    );
  }
}