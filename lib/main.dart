import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.green[200]),
      title: 'Control User',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void initState() {
    _fetchData();
    super.initState();
  }

  List data = [];
  bool isLoading = false;
  _fetchData() {
    FirebaseDatabase.instance.reference().onValue.listen((event) {
      // event.snapshot.exists ? log('esixts') : log('not exists');
      var temp = Map<String, dynamic>.from(event.snapshot.value);
      if (temp != null)
        data = temp.entries.map((e) {
          return e.value;
        }).toList();
      // temp.forEach((key, value) {
      //   if(value[''])
      // });
      isLoading = false;
      setState(() {});
    });
  }

  showDeleteDialog(String id, int index) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete ' + id),
            content: Text('Do you really want to delete the user $id?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'Cancel');
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'OK');
                  FirebaseDatabase.instance.reference().child(id).remove();
                  data.removeAt(index);
                  // setState(() {});
                  log(id + 'deleted');
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('User control'),
      ),
      body: Container(
        color: Colors.green[100],
        child: ListView(
          children: [
            SizedBox(
              height: 10,
            ),
            Center(
              child: Text('Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 15),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Container(
                    alignment: Alignment.center,
                    child: data == null || data.isEmpty
                        ? Text('No active users available')
                        : ListView.builder(
                            itemCount: data.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (_, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child:
                                    // data[index]['isAccepted'] == 'false'
                                    //     ?
                                    // Container()
                                    // :
                                    InkWell(
                                  onLongPress: () {
                                    showDeleteDialog(
                                        data[index]['ID'].substring(1, data[index]['ID'].length - 1), index);
                                    setState(() {});
                                  },
                                  child: data[index]['ID'] == null
                                      ? Container()
                                      : new UserCard(
                                          id: data[index]['ID'].substring(1, data[index]['ID'].length - 1),
                                          isAllowed: data[index]['isAllowed'],
                                          isAccepted: data[index]['isAccepted'],
                                          lastActive: data[index]['lastActive'],
                                          data: data[index],
                                        ),
                                ),
                              );
                            })),
            SizedBox(
              height: 50,
            ),
            // Divider(
            //   thickness: 1,
            // ),
            // Center(
            //     child: Text(
            //   'New User Request',
            //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            // )),
            // SizedBox(
            //   height: 15,
            // ),
            // isLoading
            //     ? Center(child: CircularProgressIndicator())
            //     : Container(
            //         alignment: Alignment.center,
            //         child: data == null
            //             ? Text('No new Request available')
            //             : ListView.builder(
            //                 itemCount: data.length,
            //                 shrinkWrap: true,
            //                 physics: NeverScrollableScrollPhysics(),
            //                 itemBuilder: (_, index) {
            //                   return Padding(
            //                     padding: const EdgeInsets.only(bottom: 15.0),
            //                     child: data[index]['isAccepted'] == 'true'
            //                         ? Container()
            //                         : InkWell(
            //                             onLongPress: () {
            //                               showDeleteDialog(
            //                                   data[index]['ID'].substring(1,
            //                                       data[index]['ID'].length - 1),
            //                                   index);
            //                             },
            //                             child: data[index]['ID'] == null
            //                                 ? Container()
            //                                 : NewUserCard(
            //                                     lastActive: data[index]
            //                                         ['lastActive'],
            //                                     id: data[index]['ID'].substring(
            //                                         1,
            //                                         data[index]['ID'].length -
            //                                             1),
            //                                     isAccepted: data[index]
            //                                         ['isAccepted']),
            //                           ),
            //                   );
            //                 })),
            SizedBox(
              height: 45,
            ),
          ],
        ),
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  UserCard(
      {Key key,
      @required this.id,
      @required this.isAllowed,
      @required this.lastActive,
      @required this.isAccepted,
      @required this.data})
      : super(key: key);
  String isAllowed, isAccepted, lastActive;
  final String id;
  var data;

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool isActive;
  bool enableToggling;
  void initState() {
    super.initState();
    int tempTime = 0;
    isActive = true;
    enableToggling = false;
    tempTime = int.parse(widget.lastActive);
    ////////////TIMER FOR ACTIVE USER///////////////
    Timer.periodic(Duration(seconds: 15), (timer) {
      if (tempTime == int.parse(widget.lastActive)) {
        isActive = false;
        setState(() {});
      } else {
        isActive = true;
        tempTime = int.parse(widget.lastActive);
      }
    });
  }

  showDialogForIP(String id, int index, String IP) {
    final ipController = TextEditingController();
    if (IP.isNotEmpty) ipController.text = IP;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Set IP for ' + id),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('You have to set an IP address before enabling  user $id?'),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 50,
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(),
                    controller: ipController,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(8),
                        hintText: 'IP Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                )
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'Cancel');
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (ipController.text.isEmpty) {
                    return;
                  }

                  Navigator.pop(context, 'OK');
                  await FirebaseDatabase.instance.reference().child(id).update({'IP': ipController.text});
                  Fluttertoast.showToast(
                      msg: "IP Updated successfully",
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      fontSize: 16.0);

                  // setState(() {});
                  log(id + ' ip updated');
                },
                child: const Text(
                  'Set',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8),
      child: InkWell(
        onTap: () {
          showDialogForIP(widget.id, 0, widget.data['IP'] != null ? widget.data['IP'] : '');
        },
        child: Container(
            alignment: Alignment.center,
            height: 55,
            width: MediaQuery.of(context).size.width * .80,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
                boxShadow: [BoxShadow(blurRadius: 4, offset: Offset(0, 0))]),
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'ID: ' + widget.id,
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        Row(
                          children: [
                            Text(
                              'Active: ',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                            Container(
                              height: 20,
                              width: 20,
                              decoration:
                                  BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(widget.isAllowed == 'true' ? Colors.red : Colors.green)),
                      onPressed: () async {
                        if (widget.data['IP'] == null || widget.data['IP'].isEmpty) {
                          try {
                            await showDialogForIP(widget.id, 0, widget.data['IP'] != null ? widget.data['IP'] : '');
                          } on Exception catch (e) {
                            // TODO
                          }
                          return;
                        }

                        if (widget.isAllowed == 'true')
                          widget.isAllowed = "false";
                        else
                          widget.isAllowed = "true";
                        await FirebaseDatabase.instance
                            .reference()
                            .child(widget.id)
                            .update({'isAllowed': widget.isAllowed});

                        // setState(() {});
                        // FirebaseFirestore.instance
                        //     .collection('phones')
                        //     .doc(widget.id)
                        //     .update({'isAllowed': widget.isAllowed});
                      },
                      child: widget.isAllowed == 'true' ? Text('Disable') : Text('Enable')),
                ],
              ),
            )),
      ),
    );
  }
}

// class NewUserCard extends StatefulWidget {
//   NewUserCard(
//       {Key key,
//       @required this.id,
//       @required this.isAccepted,
//       @required this.lastActive})
//       : super(key: key);
//   String isAccepted = 'true', lastActive;
//   final String id;

//   @override
//   _NewUserCardState createState() => _NewUserCardState();
// }

// class _NewUserCardState extends State<NewUserCard> {
//   bool isActive;
//   void initState() {
//     super.initState();
//     int tempTime = 0;
//     isActive = true;
//     tempTime = int.parse(widget.lastActive);
//     print('initState called' + tempTime.toString());
//     ////////////TIMER FOR ACTIVE USER///////////////
//     ///
//     Timer.periodic(Duration(seconds: 15), (timer) {
//       log('\ntimer');
//       log('temp: ' + tempTime.toString());
//       log('first' + widget.lastActive + ' ' + widget.id);
//       if (tempTime == int.parse(widget.lastActive)) {
//         isActive = false;
//         log('not active');
//         tempTime = int.parse(widget.lastActive);
//         log(tempTime.toString());
//         setState(() {});
//       } else {
//         log('active');
//         isActive = true;
//         tempTime = int.parse(widget.lastActive);
//         log(tempTime.toString());
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 8.0, right: 8),
//       child: Container(
//           alignment: Alignment.center,
//           height: 55,
//           width: MediaQuery.of(context).size.width * .80,
//           decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: Colors.grey[200],
//               boxShadow: [BoxShadow(blurRadius: 4, offset: Offset(0, 0))]),
//           child: Padding(
//             padding: const EdgeInsets.only(left: 10.0, right: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Text(
//                         'ID: ' + widget.id,
//                         style: TextStyle(
//                             fontWeight: FontWeight.w500, fontSize: 16),
//                       ),
//                       Row(
//                         children: [
//                           Text(
//                             'Active: ',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.w500, fontSize: 14),
//                           ),
//                           Container(
//                             height: 20,
//                             width: 20,
//                             decoration: BoxDecoration(
//                                 color: isActive ? Colors.green : Colors.red,
//                                 shape: BoxShape.circle),
//                           )
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 ElevatedButton(
//                     style: ButtonStyle(
//                         backgroundColor: MaterialStateProperty.all(
//                             widget.isAccepted == 'true'
//                                 ? Colors.red
//                                 : Colors.green)),
//                     onPressed: () async {
//                       await showDialogBox(widget.isAccepted, widget.id);
//                       setState(() {});
//                     },
//                     child: widget.isAccepted == 'true'
//                         ? Text('Delete')
//                         : Text('Accept')),
//               ],
//             ),
//           )),
//     );
//   }

//   showDialogBox(String isAllowed, String id) {
//     return showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: Text('Accept $id'),
//             content: Text('Do you really want to accept the user $id?'),
//             actions: <Widget>[
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context, 'Cancel');
//                 },
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   widget.isAccepted == 'true'
//                       ? widget.isAccepted = 'false'
//                       : widget.isAccepted = 'true';
//                   Navigator.pop(context, 'OK');
//                   FirebaseDatabase.instance
//                       .reference()
//                       .child(widget.id)
//                       .update({'isAccepted': widget.isAccepted});
//                 },
//                 child: const Text(
//                   'Accept',
//                   style: TextStyle(color: Colors.green),
//                 ),
//               ),
//             ],
//           );
//         });
//   }
// }

// // class ItemModel {
//   final String isAccepted, isAllowed, id, lastActive;
//   ItemModel(
//       {@required this.isAccepted,
//       @required this.isAllowed,
//       @required this.id,
//       @required this.lastActive});

//   factory ItemModel.fromRTDB(Map<String, dynamic> data) {
//     return ItemModel(
//         isAccepted: data['isAccepted'],
//         isAllowed: data['isAllowed'],
//         id: data['id'],
//         lastActive: data['lastActive']);
//   }
// }
