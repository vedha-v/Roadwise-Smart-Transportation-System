import 'package:flutter/material.dart';

import 'screens/home/home_page.dart';
import 'screens/explore/explore_page.dart';
import 'screens/bookings/bookings_page.dart';
import 'screens/ev/ev_page.dart';
import 'screens/profile/profile_page.dart';


void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainNavigation(),
    );
  }
}


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}


class _MainNavigationState extends State<MainNavigation> {

  int currentIndex = 1;


  final pages = const [

    HomePage(),

    ExplorePage(),

    BookingsPage(),

    EvPage(),

    ProfilePage(),

  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],


      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,

        unselectedItemColor: Colors.grey,


        onTap: (index){

          setState(() {

            currentIndex = index;

          });

        },


        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Explore",
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: "Bookings",
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.ev_station_outlined),
            activeIcon: Icon(Icons.ev_station),
            label: "EV",
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),

        ],

      ),

    );

  }
}