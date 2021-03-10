// import 'package:PotholeDetector/services/obstacle.dart';
// import 'package:PotholeDetector/services/voice.dart';
// import 'package:flutter/material.dart';
//
// Obstacles obs = Obstacles();
// Voice voice = Voice();
//
// class Accelerometer extends StatelessWidget {
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: StreamBuilder(
//         stream: obs.signal,
//         builder: (BuildContext context, AsyncSnapshot snap) {
//           /*
//           **Test Voice**
//             int x = snap.data;
//             int y = x ?? 0;
//             if ((y % 10) == 1) {
//               voice.speak("Hello from the AI");
//             }
//            */
//           return Text('${snap.data}');
//         },
//       ),
//     );
//   }
// }
