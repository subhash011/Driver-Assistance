import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'package:sensors/sensors.dart';

class Obstacles {

  Sensors sensor = Sensors();

  var _signal = BehaviorSubject<int>.seeded(0);

  get accelerometer {
    return sensor.accelerometer;
  }

  get userAccelerometer {
    return sensor.userAccelerometer;
  }

  get signal {
    return _signal;
  }

  Obstacles() {
    // ignore: close_sinks
    BehaviorSubject accelerometer = sensor.accelerometer;
    // BehaviorSubject userAccelerometer = sensor.userAccelerometer;
    accelerometer.stream.listen((event) {
      var mag = pow(event[0], 2) + pow(event[1], 2) + pow(event[2], 2);
      mag = sqrt(mag);
      if (mag > 11) {
        _signal.add(1);
        print("Obstacle Detected");
      } else {
        _signal.add(0);
      }
    });
  }

  dispose() {
    _signal.close();
  }
}


class Sensors {
  BehaviorSubject _accelerometerSub = BehaviorSubject<dynamic>();
  BehaviorSubject _userAccelerometerSub = BehaviorSubject<dynamic>();

  get accelerometer {
    return _accelerometerSub;
  }

  get userAccelerometer {
    return _userAccelerometerSub;
  }

  Sensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      List<double> accelerometerValues = <double>[event.x, event.y, event.z]
          .map((e) => double.parse(e.toStringAsFixed(3))).toList();
      _accelerometerSub.add(accelerometerValues);
    });

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      List<double> accelerometerValues = <double>[event.x, event.y, event.z]
          .map((e) => double.parse(e.toStringAsFixed(3))).toList();
      _userAccelerometerSub.add(accelerometerValues);
    });
  }

  dispose() {
    _accelerometerSub.close();
    _userAccelerometerSub.close();
  }

}

