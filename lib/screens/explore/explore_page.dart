import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}


class _ExplorePageState extends State<ExplorePage> {

  LatLng currentLocation = const LatLng(12.9716, 77.5946);

  String selectedTransport = "Car";

  String trafficStatus = "Moderate";


  final transports = [
    "Car",
    "Bus",
    "Train",
    "Public Transport",
    "Two Wheeler",
    "Freight Vehicle",
  ];


  final destinations = [
    "Airport",
    "Railway Station",
    "Shopping Mall",
    "University",
  ];


  Future<void> getCurrentLocation() async {

    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }


    LocationPermission permission =
        await Geolocator.requestPermission();


    if(permission == LocationPermission.denied){
      return;
    }


    Position position =
        await Geolocator.getCurrentPosition();


    setState(() {

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

    });

  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF5F7FB),


      appBar: AppBar(

        title: const Text(
          "Explore RoadWise",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

      ),



      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),


        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,


          children: [


            // Traffic Card

            Card(

              child: Padding(

                padding: const EdgeInsets.all(16),

                child: Row(

                  children: [

                    const Icon(
                      Icons.traffic,
                      size: 40,
                    ),


                    const SizedBox(width:20),


                    Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,


                      children: [

                        const Text(
                          "Traffic Status",
                          style: TextStyle(
                            fontSize:18,
                            fontWeight:FontWeight.bold,
                          ),
                        ),


                        Text(
                          trafficStatus,
                          style: const TextStyle(
                            fontSize:16,
                          ),
                        )

                      ],
                    )

                  ],

                ),

              ),

            ),



            const SizedBox(height:20),



            // Map


            const Text(

              "Explore Map",

              style: TextStyle(
                fontSize:20,
                fontWeight:FontWeight.bold,
              ),

            ),



            const SizedBox(height:10),



            SizedBox(

              height:250,


              child: FlutterMap(

                options: MapOptions(

                  initialCenter: currentLocation,

                  initialZoom: 14,

                ),


                children: [

                  TileLayer(

                    urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

                  ),


                  MarkerLayer(

                    markers: [

                      Marker(

                        point: currentLocation,

                        child: const Icon(

                          Icons.location_pin,

                          color: Colors.red,

                          size:40,

                        ),

                      )

                    ],

                  )

                ],

              ),

            ),



            const SizedBox(height:15),



            ElevatedButton.icon(

              onPressed:getCurrentLocation,

              icon:const Icon(Icons.my_location),

              label:
              const Text(
                "Use Current Location",
              ),

            ),



            const SizedBox(height:25),



            const Text(

              "Choose Transport",

              style:TextStyle(

                fontSize:20,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),



            Wrap(

              spacing:10,

              runSpacing:10,


              children:

              transports.map((transport){

                return ChoiceChip(

                  label:Text(transport),


                  selected:
                  selectedTransport == transport,


                  onSelected:(value){

                    setState((){

                      selectedTransport = transport;

                    });

                  },

                );


              }).toList(),

            ),




            const SizedBox(height:25),




            const Text(

              "Popular Destinations",

              style:TextStyle(

                fontSize:20,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),




            ...destinations.map((place){


              return Card(

                child:ListTile(

                  leading:
                  const Icon(Icons.location_on),


                  title:Text(place),


                  trailing:
                  const Icon(
                    Icons.arrow_forward_ios,
                    size:16,
                  ),

                ),

              );


            }),





            const SizedBox(height:25),



            const Text(

              "RoadWise Services",

              style:TextStyle(

                fontSize:20,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),




            GridView.count(

              shrinkWrap:true,

              physics:
              const NeverScrollableScrollPhysics(),


              crossAxisCount:2,


              children:[


                serviceCard(
                  "Parking",
                  Icons.local_parking,
                ),


                serviceCard(
                  "EV Stations",
                  Icons.ev_station,
                ),


                serviceCard(
                  "Route Planning",
                  Icons.route,
                ),


                serviceCard(
                  "Bookings",
                  Icons.book_online,
                ),


              ],

            )


          ],

        ),

      ),

    );

  }





  Widget serviceCard(
      String title,
      IconData icon,
      ){

    return Card(

      child:Column(

        mainAxisAlignment:
        MainAxisAlignment.center,


        children:[


          Icon(
            icon,
            size:40,
          ),


          const SizedBox(height:10),


          Text(

            title,

            style:
            const TextStyle(
              fontWeight:FontWeight.bold,
            ),

          )


        ],

      ),

    );

  }


}