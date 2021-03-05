import 'package:rxdart/rxdart.dart';
import 'package:sensors/sensors.dart';

class Obstacles {

  var _accelerometerSub = BehaviorSubject<dynamic>();
  var _userAccelerometerSub = BehaviorSubject<dynamic>();

  get accelerometer {
    return _accelerometerSub;
  }

  get userAccelerometer {
    return _userAccelerometerSub;
  }

  Obstacles() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      List<String> accelerometerValues = <double>[event.x, event.y, event.z]
          .map((e) => e.toStringAsFixed(3)).toList();
      _accelerometerSub.add(accelerometerValues);
    });

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      List<String> accelerometerValues = <double>[event.x, event.y, event.z]
          .map((e) => e.toStringAsFixed(3)).toList();
      _userAccelerometerSub.add(accelerometerValues);
    });
  }

  dispose() {
    _accelerometerSub.close();
    _userAccelerometerSub.close();
  }
}


