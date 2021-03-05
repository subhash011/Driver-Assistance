import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'package:sensors/sensors.dart';

class Obstacles {

  Sensors sensor = Sensors();

  var _signal = BehaviorSubject<int>.seeded(0);
  /*
  signal code (currently only 0 and 1)
  {
    0: No Obstacle
    1: Pothole
    2: Speed Breaker
    3: Sharp Turn
    4: Construction
    5: Others
  }
  */

  get accelerometer {
    return sensor.accelerometer;
  }

  get userAccelerometer {
    return sensor.userAccelerometer;
  }

  get signal {
    return _signal.scan((accumulated, value, index) => accumulated + value, 0); // 'reduce' only for testing signal.
  }

  rule (acc, [userAcc]) {
    var mag = pow(acc[0], 2) + pow(acc[1], 2) + pow(acc[2], 2);
    mag = sqrt(mag);
    if (mag > 13) {
      _signal.add(1);
    } else {
      _signal.add(0);
    }
  }

  Obstacles() {
    // ignore: close_sinks
    BehaviorSubject accelerometer = sensor.accelerometer;
    // BehaviorSubject userAccelerometer = sensor.userAccelerometer;
    accelerometer.stream.listen((event) {
      rule(event);
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

