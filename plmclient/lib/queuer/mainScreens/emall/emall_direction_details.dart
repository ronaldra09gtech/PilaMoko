import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plmclient/client/models/direction_details.dart';
import 'package:plmclient/queuer/mainScreens/emall/emall_order_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart' as storageRef;

import '../../../client/assistantMethods/assistant_methods.dart';
import '../../../client/widgets/loading_dialog.dart';
import '../../../main.dart';
import '../../global/global.dart';

class EmallDirectionDetails extends StatefulWidget {
  double? purchaserlat;
  double? purchaserlng;
  String? orderID, phonenum;
  String? sellerID, cliendID;
  double? sellerLat, sellerLng;

  EmallDirectionDetails({
    this.purchaserlat,
    this.purchaserlng,
    this.orderID,
    this.sellerID,
    this.sellerLng,
    this.sellerLat,
    this.phonenum,
    this.cliendID
});
  @override
  State<EmallDirectionDetails> createState() => _EmallDirectionDetailsState();
}

class _EmallDirectionDetailsState extends State<EmallDirectionDetails> with TickerProviderStateMixin {

  Completer<GoogleMapController> _controllerGMap = Completer();
  GoogleMapController? newGoogleMapController;
  Set<Marker> markers = {};
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  PolylinePoints polylinePoints = PolylinePoints();
  DirectionDetails? tripDirectionDetails;

  String placeID="";
  Position? currentPosition;

  double rideDetailsContainerHeight = 0;
  double dropOffContainerHeight = 0;
  double searchContainerHeight = 0;
  double signatureContainerHeight = 0;
  double bottomPaddingOfMap = 100;

  String signature="";
  String? serviceType;

  String? uniqueIDName;
  String orderTotalAmount = "";

  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(13.8848117, 122.2601717),
    zoom: 17,
  );

  var geolocator = Geolocator();

  void locatePosition() async
  {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLatPosition, zoom: 14);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    Navigator.pop(context);
    // String address = await AssistantMethods.searchCoordinateAddress(position, context);
    // print(address);
  }

  displayRideDetailsContainer()
  {
    setState(() {
      searchContainerHeight=0;
      rideDetailsContainerHeight=240;
      bottomPaddingOfMap = 230;
    });
  }

  displaySignatureContainer()
  {
    setState(() {
      searchContainerHeight=0;
      rideDetailsContainerHeight=0;
      dropOffContainerHeight=0;
      signatureContainerHeight=100;
      bottomPaddingOfMap = 230;
    });
  }

  displayDropOffContainer()
  {
    setState(() {
      searchContainerHeight=0;
      rideDetailsContainerHeight=0;
      dropOffContainerHeight=240;
      bottomPaddingOfMap = 230;
    });
  }

  confirmParcelHasBeenPicked(getOrderID)
  {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(getOrderID).update({
      "status": "delivering",
      "riderUID": sharedPreferences!.getString("email"),
    });
  }

  void getLocationLiveUpdates()
  {
    homeTabPageStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      currentPosition = position;
      usersRef!.update({
        "lat": position.latitude,
        "lng": position.longitude,
      });
    });
    LatLng latLatPosition = LatLng(position!.latitude, position!.longitude);
    CameraPosition cameraPosition = new CameraPosition(target: latLatPosition, zoom: 14);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  captureImageWithCamera() async {
    imageXFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxHeight: 720,
      maxWidth: 1280,
    );
    setState(() {
      imageXFile;
    });

  }

  getOrderTotalAmount()
  {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderID)
        .get()
        .then((snap){
      orderTotalAmount = snap.data()!["totalAmount"].toString();
    }).then((value){
      if(serviceType == "eresto"){
        getSellerData();
      }
      else if(serviceType == "emall") {
        getEmallData();
      }
      else if(serviceType == "emarket") {
        getEmarketData();
      }
    });
  }

  getSellerData()
  {
    FirebaseFirestore.instance
        .collection("pilamokoseller")
        .doc(widget.sellerID)
        .get().then((snap){
      previousEarnings = snap.data()!["earning"].toString();
    });
  }

  getEmallData()
  {
    FirebaseFirestore.instance
        .collection("pilamokoemall")
        .doc(widget.sellerID)
        .get().then((snap){
      previousEarnings = snap.data()!["earning"].toString();
    });
  }

  getEmarketData()
  {
    FirebaseFirestore.instance
        .collection("pilamokoemarket")
        .doc(widget.sellerID)
        .get().then((snap){
      previousEarnings = snap.data()!["earning"].toString();
    });
  }


  @override
  void initState() {
    super.initState();

    getOrderTotalAmount();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Colors.lightBlue,
                  Colors.blueAccent,
                ],
                begin: FractionalOffset(0.0, 0.0),
                end: FractionalOffset(1.0, 0.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: 100),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            polylines: polylineSet,
            markers: markers,
            onMapCreated: (GoogleMapController controller) async{
              _controllerGMap.complete(controller);
              newGoogleMapController = controller;
              showDialog(
                  context: context,
                  builder: (BuildContext context) => LoadingDialog(message: "Please Wait...",)
              );
              locatePosition();
            },
            buildingsEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: false,
            rotateGesturesEnabled: true,
            trafficEnabled: true,
          ),
          Positioned(
            left: 0.0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6,),
                      GestureDetector(
                        onTap: () async
                        {
                          getPlaceDirection();
                          displayRideDetailsContainer();
                          getLocationLiveUpdates();

                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                spreadRadius: 0.5,
                                offset: Offset(0.7,0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: const [
                                SizedBox(width: 10,),
                                Text("Show Pickup Location")
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7),
                      )
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.lightBlueAccent,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16,),
                          child: Row(
                            children: [
                              Image.asset("images/signup.png",height: 70, width: 80,),
                              SizedBox(width: 16,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Pickup Location", style: TextStyle(fontSize: 18, fontFamily: "Brand"),),
                                  Text(((tripDirectionDetails != null) ?tripDirectionDetails!.distanceText.toString() : ''), style: TextStyle(fontSize: 18, color: Colors.black),),

                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null) ? tripDirectionDetails!.durationText.toString(): ''),
                                style: TextStyle(fontSize: 18, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6,),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            child: GestureDetector(
                              onTap: () async
                              {
                                getDropOffDirection();
                                displayDropOffContainer();
                                confirmParcelHasBeenPicked(widget.orderID!);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.lightBlue,
                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                      offset: Offset(0.7,0.7),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: const [
                                      Text("Parcel Has Been PickUp")
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            child: GestureDetector(
                              onTap: () async
                              {
                                var number = widget.phonenum.toString();
                                launch('tel://$number');
                                print(number);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.lightBlue,
                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                      offset: Offset(0.7,0.7),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: const [
                                      Text("Call Seller")
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: dropOffContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7),
                      )
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.lightBlueAccent,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16,),
                          child: Row(
                            children: [
                              Image.asset("images/signup.png",height: 70, width: 80,),
                              SizedBox(width: 16,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Drop Off Location", style: TextStyle(fontSize: 18, fontFamily: "Brand"),),
                                  Text(((tripDirectionDetails != null) ?tripDirectionDetails!.distanceText.toString() : ''), style: TextStyle(fontSize: 18, color: Colors.black),),

                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null) ? tripDirectionDetails!.durationText.toString(): ''),
                                style: TextStyle(fontSize: 18, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6,),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            child: GestureDetector(
                              onTap: () async
                              {
                                captureImageWithCamera();
                                displaySignatureContainer();
                                // confirmParcelHasBeenDelivered(widget.bookingDetails!.bookID!);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.lightBlue,
                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                      offset: Offset(0.7,0.7),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: const [
                                      Text("Parcel Has Been Delivered")
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            child: GestureDetector(
                              onTap: () async
                              {
                                var number = widget.phonenum.toString();
                                launch('tel://$number');
                                print(number);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.lightBlue,
                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                      offset: Offset(0.7,0.7),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: const [
                                      Text("Call Client")
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: signatureContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7),
                      )
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                        child: GestureDetector(
                          onTap: () async
                          {
                            if(imageXFile != null){
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) => LoadingDialog(message: "Please Wait...",)
                              );
                              uploadImage(File(imageXFile!.path));
                            }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.lightBlue,
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7,0.7),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: const [
                                  Text("Order Complete")
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  uploadImage(mImageFile) async{
    uniqueIDName = DateTime.now().millisecondsSinceEpoch.toString();

    storageRef.Reference reference =
    storageRef.FirebaseStorage.instance.ref().child("emallorders");

    storageRef.UploadTask uploadTask =
    reference.child(uniqueIDName! + ".jpg").putFile(mImageFile);

    storageRef.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

    String downloadURL = await taskSnapshot.ref.getDownloadURL();

    FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderID)
        .update({
      "pod": downloadURL,
      "status": "ended"
    }).whenComplete((){
      confirmParcelHasBeenDelivered(widget.orderID, widget.sellerID, widget.cliendID);
    });
  }

  confirmParcelHasBeenDelivered(getOrderID, sellerID, purchaserID)
  {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(getOrderID)
        .get()
        .then((snapshot){
          if(snapshot.data()!['paymentDetails'] == "Cash on Delivery"){
            String riderNewTotalEarningAmount = ((double.parse(previousRiderEarnings)) - (double.parse(perParcelDeliveryAmount))).toString();

            FirebaseFirestore.instance
                .collection("pilamokoqueuer")
                .doc(sharedPreferences!.getString("email"))
                .update({
              "earning":riderNewTotalEarningAmount,
            }).then((value){
              if(serviceType == "eresto"){
                FirebaseFirestore.instance
                    .collection("pilamokoseller")
                    .doc(widget.sellerID)
                    .update({
                  "earning":(double.parse(orderTotalAmount) + (double.parse(previousEarnings))).toString(), //total earnings amount of seller,
                });
              }
              else if(serviceType == "emall"){
                FirebaseFirestore.instance
                    .collection("pilamokoemall")
                    .doc(widget.sellerID)
                    .update({
                  "earning":(double.parse(orderTotalAmount) + (double.parse(previousEarnings))).toString(), //total earnings amount of seller,
                });
              }

              else if(serviceType == "emarket"){
                FirebaseFirestore.instance
                    .collection("pilamokoemarket")
                    .doc(widget.sellerID)
                    .update({
                  "earning":(double.parse(orderTotalAmount) + (double.parse(previousEarnings))).toString(), //total earnings amount of seller,
                });
              }
            });
          }
          else {
            String riderNewTotalEarningAmount = ((double.parse(previousRiderEarnings)) + (double.parse(perParcelDeliveryAmount))).toString();

            FirebaseFirestore.instance
                .collection("orders")
                .doc(getOrderID)
                .update({
              "status": "ended",
            }).then((value){
              FirebaseFirestore.instance
                  .collection("pilamokoqueuer")
                  .doc(sharedPreferences!.getString("email"))
                  .update({
                "earning":riderNewTotalEarningAmount,
              });
            }).then((value){
              if(serviceType == "eresto"){
                FirebaseFirestore.instance
                    .collection("pilamokoseller")
                    .doc(widget.sellerID)
                    .update({
                  "earning":(double.parse(orderTotalAmount) + (double.parse(previousEarnings))).toString(), //total earnings amount of seller,
                });
              }
              else if(serviceType == "emall"){
                FirebaseFirestore.instance
                    .collection("pilamokoemall")
                    .doc(widget.sellerID)
                    .update({
                  "earning":(double.parse(orderTotalAmount) + (double.parse(previousEarnings))).toString(), //total earnings amount of seller,
                });
              }

              else if(serviceType == "emarket"){
                FirebaseFirestore.instance
                    .collection("pilamokoemarket")
                    .doc(widget.sellerID)
                    .update({
                  "earning":(double.parse(orderTotalAmount) + (double.parse(previousEarnings))).toString(), //total earnings amount of seller,
                });
              }

            }).then((value){
              FirebaseFirestore.instance
                  .collection("pilamokoclient")
                  .doc(purchaserID)
                  .collection("orders")
                  .doc(getOrderID).update(
                  {
                    "status": "ended",
                    "riderUID": sharedPreferences!.getString("uid"),
                  });
            });
          }
        }).whenComplete(() {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (c)=> EmallOrderScreen()));
    });

  }


  Future<void> getPlaceDirection() async
  {
    var pickUpLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    var dropOffLatLng = LatLng(widget.sellerLat!, widget.sellerLng!);

    showDialog(
        context: context,
        builder: (BuildContext context) => LoadingDialog(message: "Please Wait...",)
    );

    var details = await AssistantMethods.obtainDirectionDetails(pickUpLatLng, dropOffLatLng);

    setState(() {
      tripDirectionDetails = details as DirectionDetails?;
    });

    Navigator.pop(context);
    print(details!.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsResult = polylinePoints.decodePolyline(details.encodedPoints.toString());

    pLineCoordinates.clear();
    if(decodedPolylinePointsResult.isNotEmpty)
    {
      decodedPolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });
    LatLngBounds latLngBounds;

    if(pickUpLatLng.latitude > dropOffLatLng.latitude && pickUpLatLng.longitude > dropOffLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    }
    else if(pickUpLatLng.longitude > dropOffLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    }
    else if(pickUpLatLng.latitude > dropOffLatLng.latitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    }
    else
    {
      latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds,70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: "My Location", snippet: "My Location"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId")
    );

    Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: "DropOff Location", snippet: "DropOff Location"),
        position: dropOffLatLng,
        markerId: MarkerId("dropOffId")
    );

    setState(() {
      markers.add(pickUpLocMarker);
      markers.add(dropOffLocMarker);
    });
  }

  Future<void> getDropOffDirection() async
  {
    var pickUpLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    var dropOffLatLng = LatLng(widget.purchaserlat!, widget.purchaserlng!);

    showDialog(
        context: context,
        builder: (BuildContext context) => LoadingDialog(message: "Please Wait...",)
    );

    var details = await AssistantMethods.obtainDirectionDetails(pickUpLatLng, dropOffLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);
    print(details!.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsResult = polylinePoints.decodePolyline(details.encodedPoints.toString());

    pLineCoordinates.clear();
    if(decodedPolylinePointsResult.isNotEmpty)
    {
      decodedPolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });
    LatLngBounds latLngBounds;

    if(pickUpLatLng.latitude > dropOffLatLng.latitude && pickUpLatLng.longitude > dropOffLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    }
    else if(pickUpLatLng.longitude > dropOffLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    }
    else if(pickUpLatLng.latitude > dropOffLatLng.latitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    }
    else
    {
      latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }
    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds,70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: "My Location", snippet: "My Location"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId")
    );

    Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: "DropOff Location", snippet: "DropOff Location"),
        position: dropOffLatLng,
        markerId: MarkerId("dropOffId")
    );

    setState(() {
      markers.add(pickUpLocMarker);
      markers.add(dropOffLocMarker);
    });
  }
}
