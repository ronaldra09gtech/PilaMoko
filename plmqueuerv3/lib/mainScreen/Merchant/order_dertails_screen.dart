import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/address.dart';
import '../../widgets/progress_bar.dart';
import 'shipment_address_design.dart';
import 'status_banner.dart';



class OrderDetailsScreen extends StatefulWidget
{
  final String? orderID;

  OrderDetailsScreen({this.orderID});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
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
      setState(() {
        orderStatus = DocumentSnapshot.data()!["status"].toString();
        orderByUser = DocumentSnapshot.data()!["orderBy"].toString();
        sellerID = DocumentSnapshot.data()!["sellerUID"].toString();
        print(orderByUser);
      });
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

                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "₱ ${dataMap!["totalAmount"]}",
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
                        "Order Id = ${widget.orderID!}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Order at: ${DateFormat("dd MMMM, yyyy - hh:mm aa")
                                .format(DateTime.fromMillisecondsSinceEpoch(int.parse(dataMap["orderTime"])))}",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const Divider(thickness: 4,),
                    orderStatus == "ended"
                        ? Image.asset("images/success.jpg")
                        : Image.asset("images/confirm_pick.png"),
                    const Divider(thickness: 4,),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("pilamokoclient")
                          .doc(dataMap["orderBy"])
                          .collection("myDeliveryAddresses")
                          .doc(dataMap["addressID"])
                          .get(),
                      builder: (c, snapshot)
                      {
                        return snapshot.hasData
                            ? ShipmentAddressDesign(
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
