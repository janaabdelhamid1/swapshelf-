import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:swapshelf_app/pages/add_book_page.dart';
import 'package:swapshelf_app/pages/home_page.dart';
import 'package:swapshelf_app/pages/location/locations.dart';
import 'package:swapshelf_app/pages/my_shelf.dart';
import 'package:swapshelf_app/pages/profile_page/profile_page.dart';
class NavBar extends StatefulWidget{
  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
List <Widget> _pages =[
  HomePage(),
 Locations(),
AddBookPage(),
 MyShelfPage(),
    ProfilePage(),
];
int _selectedIndex = 0;
void _navigateBottomBar(int index){
 setState((){
  _selectedIndex =index;});
}
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: 60,
        child: Container(
          color: Color(0xFFFFF8EF),
          child: GNav(
            backgroundColor: Color(0xFFFFF8EF),
            color: Color(0xFF7B8791),
            activeColor: Color(0xFF35120F),
            tabBackgroundColor: Colors.grey,
            gap: 8,
            onTabChange: _navigateBottomBar,
            padding: EdgeInsets.all(15),
            tabs: [
              GButton(icon: Icons.home,
              text: 'home',
              ),
              GButton(icon: Icons.location_pin,
              text: 'Locations',
              ),
              GButton(icon: Icons.add_box_outlined,
              text: 'Add New Book'
              ),
              GButton(icon: Icons.book_outlined,
              text:'Shelf'
              ),
          
              GButton(icon: Icons.person_outlined,
              text:'Profile'
              ),
          
          ],
          ),
        ),
      ),
    );
  }
}