import 'package:PotholeDetector/services/obstacle.dart';
import 'package:PotholeDetector/services/voice.dart';
import 'package:PotholeDetector/widgets/accelerometer/accelerometer.dart';
import 'package:PotholeDetector/widgets/maps/maps.dart';
import 'package:flutter/material.dart';

Obstacles obs = Obstacles();
Voice voice = Voice();

class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    obs.signal.stream.listen((event) {
      print("Obstacle Detected ! ; $event");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Assistance')),
      body: MapView(),
    );
  }
}

// final List<Widget> _allPages = <Widget>[MapView(), Accelerometer()];
// final List<String> _titles = ["Maps", "Accelerometer"];
//
// class Home extends StatelessWidget {
//   void _pushPage(BuildContext context, Widget page, String title) {
//     Navigator.of(context).push(MaterialPageRoute<void>(
//         builder: (_) => Scaffold(
//               appBar: AppBar(title: Text(title)),
//               body: page,
//             )));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Driver Assistance')),
//       body: ListView.builder(
//         shrinkWrap: true,
//         itemCount: _allPages.length,
//         itemBuilder: (_, int index) => ListTile(
//           title: Text(_titles[index]),
//           onTap: () => _pushPage(context, _allPages[index], _titles[index]),
//         ),
//       ),
//     );
//   }
// }