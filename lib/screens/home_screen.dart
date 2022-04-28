import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/services/socket_service.dart';
import 'package:band_names/model/band.dart';

class HomeScreen extends StatefulWidget {
   
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<Band> bands = [];

  @override
  void initState() {
    
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', (_handleActiveBands));

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List)
        .map((band) => Band.fromMap(band))
        .toList();

      setState(() {});
  }

  @override
  void dispose() {

    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BandNames', style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)
              ? Icon(Icons.check_circle, color: Colors.blue[300])
              : const Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
      
            _showGraph(),
      
            Expanded(
              child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) => _bandTile(bands[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        elevation: 1,
        onPressed: () => addNewBand()
      ),
    );
  }

  Widget _bandTile(Band band) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => socketService.emit('delete-band',{'id': band.id}),
      background: Container(
        padding: const EdgeInsets.only(right: 10),
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: const Text('Delete', style: TextStyle(color: Colors.white),)
      ),

      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0,2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}',style: const TextStyle(fontSize: 20)),
        onTap: () => socketService.socket.emit('vote-band', { 'id': band.id }),
      ),
    );
  }

  addNewBand() {

    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (_) =>  CupertinoAlertDialog(
        title: const Text('New band name:'),
        content: CupertinoTextField(
        controller: textController,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () => addBandToList(textController.text),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context)
          ),
        ],
      ),
    );
  }

  void addBandToList(String name) {

    if(name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  _showGraph() {

    Map<String, double> dataMap = Map();
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    }); 

    List<Color> colorList = [
      Colors.red.withOpacity(0.5),
      Colors.blue.withOpacity(0.65),
      Colors.red.withOpacity(0.8),
      Colors.blue.withOpacity(0.5),
      Colors.red.withOpacity(0.65),
      Colors.blue.withOpacity(0.8),
    ];

    return (bands.isEmpty)
      ? Container(
        width: double.infinity,
        height: 200,
        child: const Center(child: const Text('No data')),
        )
      : Container(
        width: double.infinity,
        height: 200,
        child: PieChart(
          dataMap: dataMap,
          animationDuration: const Duration(milliseconds: 800),
          chartRadius: MediaQuery.of(context).size.width / 3.2,
          colorList: colorList,
          initialAngleInDegree: 0,
          chartType: ChartType.ring,
          ringStrokeWidth: 32,
          legendOptions: const LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.right,
            showLegends: true,
          ),
        ),
      );
  }
}