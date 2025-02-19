import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:plmclient/merchat/market/model/menus.dart';
import 'package:plmclient/merchat/market/uploadScreens/menus_upload_screen.dart';
import 'package:plmclient/merchat/market/widgets/info_design.dart';
import 'package:plmclient/merchat/market/widgets/my_drawer.dart';
import 'package:plmclient/merchat/market/widgets/progress_bar.dart';
import 'package:plmclient/merchat/market/widgets/text_widget_header.dart';
import '../../../main.dart';
import '../authentication/authScreen.dart';
import '../global/global.dart';

class HomeScreenEmarket extends StatefulWidget {
  const HomeScreenEmarket({Key? key}) : super(key: key);

  @override
  _HomeScreenEmarketState createState() => _HomeScreenEmarketState();
}

class _HomeScreenEmarketState extends State<HomeScreenEmarket> {

  bool connected=true;
  String status = "Unknown";
  final _connectivity = Connectivity();
  ConnectivityResult connectivityResult = ConnectivityResult.none;
  StreamSubscription<ConnectivityResult>? _streamSubscription;

  getMyData(){
    FirebaseFirestore.instance
        .collection("pilamokoemarket")
        .doc(sharedPreferences!.getString("uid"))
        .get().then((snap) {
      email = snap.data()!['pilamokoemarketEmail'].toString();
      phone = snap.data()!['phone'].toString();
      zone = snap.data()!['zone'].toString();
      number = snap.data()!['earning'].toString();
      loadWallet = snap.data()!['loadWallet'].toString();
      address = snap.data()!['address'].toString();
    });
  }

  @override
  void initState() {
    initialisedConnectivity();
    _streamSubscription = _connectivity.onConnectivityChanged.listen((event) {updateConnectivityStatus(event);
    });
    getMyData();
    super.initState();
  }

  initialisedConnectivity() async {
    ConnectivityResult result = ConnectivityResult.none;
    result = await _connectivity.checkConnectivity();
    updateConnectivityStatus(result);
    print(result);
  }

  updateConnectivityStatus(ConnectivityResult result){
    connectivityResult = result;
    switch(result){
      case ConnectivityResult.none:
        status = "Not Connected";
        setState(() {
          connected=false;
        });

        break;
      case ConnectivityResult.wifi:
        status = "Connected to Wifi";
        setState(() {
          connected=true;
        });
        break;
      case ConnectivityResult.mobile:
        status = "Connected to Mobile Data";
        setState(() {
          connected=true;
        });
        break;
      default:
    }

    if(!connected)
    {
      firebaseAuth.signOut();
      Navigator.push(context, MaterialPageRoute(builder: (c)=> AuthScreen()));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.lightBlueAccent,
              ],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: Text(
          sharedPreferences!.getString("name")!,
          style: const TextStyle(fontSize: 30, fontFamily: "Lobster"),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add, color: Colors.white,),
            onPressed: ()
            {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const MenusUploadScreen()));
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              connectivityResult == ConnectivityResult.none ?
              Container(
                width: MediaQuery.of(context).size.width,
                height: 30,
                color: Colors.red[400],
                alignment: Alignment.center,
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Device is in offline",
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ): Container(),
            ],
          ),
        ],
      ),
      body: DoubleBack(
        message: "Double Back Press to exit",
        background: Colors.red,
        backgroundRadius: 10,
        child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(pinned: true, delegate: TextWidgetHeader(title: "My Products")),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("pilamokoemarket")
                .doc(sharedPreferences!.getString("uid"))
                .collection("menus")
                .orderBy("publishDate", descending: true)
                .snapshots(),
            builder: (context, snapshot)
            {
              return !snapshot.hasData
                  ? SliverToBoxAdapter(child: Center(child: circularProgress(),),)
                  : SliverStaggeredGrid.countBuilder(
                crossAxisCount: 1,
                staggeredTileBuilder: (c) => const StaggeredTile.fit(1),
                itemBuilder: (context, index)
                {
                  Menus model = Menus.fromJson(
                    snapshot.data!.docs[index].data()! as Map<String, dynamic>,
                  );
                  return InfoDesignWidget(
                    model: model,
                    context: context,
                  );
                },
                itemCount: snapshot.data!.docs.length,
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
