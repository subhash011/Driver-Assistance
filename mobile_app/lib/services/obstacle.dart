import 'package:rxdart/rxdart.dart';
import 'package:sensors/sensors.dart';
import 'package:vector_math/vector_math.dart';


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
    4: Others
  }
  */

  get accelerometer {
    return sensor.accelerometer;
  }

  get userAccelerometer {
    return sensor.userAccelerometer;
  }

  get signal {
    return _signal
        .distinct()
        .scan((accumulated, value, index) => accumulated + value, 0); // 'reduce' only for testing signal.
  }

  rule (acc, userAcc) {
    var mag = userAcc.distanceTo(Vector3.zero());
    if (mag > 7) {
      _signal.add(1);
    } else {
      _signal.add(0);
    }
  }

  Obstacles() {
    // ignore: close_sinks
    BehaviorSubject accelerometer = sensor.accelerometer;
    // ignore: close_sinks
    BehaviorSubject userAccelerometer = sensor.userAccelerometer;
    userAccelerometer.stream.listen((event) {
      rule(Vector3.zero(), event);
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
      List<double> accelerometerValues = <double>[event.x, event.y, event.z];
      _accelerometerSub.add(Vector3.array(accelerometerValues));
    });

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      List<double> accelerometerValues = <double>[event.x, event.y, event.z];
      _userAccelerometerSub.add(Vector3.array(accelerometerValues));
    });
  }

  dispose() {
    _accelerometerSub.close();
    _userAccelerometerSub.close();
  }

}

