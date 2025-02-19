import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plmclient/merchat/market/model/address.dart';
import 'package:plmclient/merchat/market/widgets/new_order_shipment_design.dart';
import 'package:plmclient/merchat/market/widgets/progress_bar.dart';
import 'package:plmclient/merchat/market/widgets/shipment_address_design.dart';
import 'package:plmclient/merchat/market/widgets/status_banner.dart';

class NewOrderDetailsScreen extends StatefulWidget
{
  final String? orderID;

  NewOrderDetailsScreen({this.orderID});

  @override
  _NewOrderDetailsScreenState createState() => _NewOrderDetailsScreenState();
}




class _NewOrderDetailsScreenState extends State<NewOrderDetailsScreen>
{
  String orderStatus = "";
  String orderByUser = "";
  String sellerID = "";
  String userID = "";

  getOrderInfo()
  {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderID).get().then((DocumentSnapshot)
    {
      orderStatus = DocumentSnapshot.data()!["status"].toString();
      orderByUser = DocumentSnapshot.data()!["orderBy"].toString();
      sellerID = DocumentSnapshot.data()!["sellerUID"].toString();

    });
  }

  @override
  void initState() {
    super.initState();

    getOrderInfo();
  }

  @override
  Widget build(BuildContext context)
  {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("orders")
                .doc(widget.orderID)
                .get(),
            builder: (c, snapshot)
            {
              Map? dataMap;
              if(snapshot.hasData)
              {
                dataMap = snapshot.data!.data()! as Map<String, dynamic>;
                orderStatus = dataMap["status"].toString();
              }
              return snapshot.hasData
                  ? Container(
                child: Column(
                  children: [
                    StatusBanner(
                      status: dataMap!["isSuccess"],
                      orderStatus: orderStatus,
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "₱ " + dataMap["totalAmount"].toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Order Id = " + widget.orderID!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Order at: " +
                            DateFormat("dd MMMM, yyyy - hh:mm aa")
                                .format(DateTime.fromMillisecondsSinceEpoch(int.parse(dataMap["orderTime"]))),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const Divider(thickness: 4,),
                    orderStatus == "ended"
                        ? Image.asset("images/delivered.png")
                        : Image.asset("images/packing.png"),
                    const Divider(thickness: 4,),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("pilamokoclient")
                          .doc(orderByUser)
                          .collection("userAddress")
                          .doc(dataMap["addressID"])
                          .get(),
                      builder: (c, snapshot)
                      {
                        return snapshot.hasData
                            ? NewOrderShipmentAddressDesign(
                          model: Address.fromJson(
                              snapshot.data!.data()! as Map<String, dynamic>
                          ),
                          orderStatus: orderStatus,
                          orderID: widget.orderID,
                          sellerID: sellerID,
                          orderByUser: orderByUser,
                        )
                            : Center(child: circularProgress(),);
                      },
                    ),
                  ],
                ),
              )
                  : Center(child: circularProgress(),);
            },
          ),
        ),
      ),
    );
  }
}
