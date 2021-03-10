import 'dart:math';

import 'package:PotholeDetector/config.dart';
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
    return _signal.distinct().scan(
        (accumulated, value, index) => accumulated + value,
        0); // 'reduce' only for testing signal.
  }

  double calcDev(Vector3 acc, Vector3 userAcc) {
    // Jerk along the axis of gravity (For speed-beakers and potholes ).
    double dot = acc.dot(userAcc);
    double mag = acc.distanceTo(Vector3.zero());
    double deviation = dot / mag;
    return deviation;
  }

  sampleDeviations(values) {
    // Sampling over a range of values
    List<double> deviations = [];
    values.forEach((element) {
      double deviation = calcDev(element[0], element[1]);
      deviations.add(deviation);
    });
    return deviations;
  }

  rule(values) {
    List<double> deviations = sampleDeviations(values);
    double mean = deviations.reduce((value, element) => value + element) /
        deviations.length;
    print("###############################");
    print("mean = $mean");
    print("###############################");
    if (mean >= Config.meanThreshold) {
      _signal.add(1);
    } else {
      _signal.add(0);
    }
  }

  reorient(Vector3 accelerometer) {
    if (accelerometer[1] == 0 && accelerometer[2] == 0) {
      return Vector3(0, 0, 9.8);
    }
    var alpha = atan(accelerometer[1] / accelerometer[2]);
    var beta = atan(-1 *
        accelerometer[0] /
        (sqrt(pow(accelerometer[1], 2) + pow(accelerometer[2], 2))));
    var x = cos(beta) * accelerometer[0] +
        sin(beta) * sin(alpha) * accelerometer[1] +
        cos(alpha) * sin(beta) * accelerometer[2];
    var y = cos(alpha) * accelerometer[1] - sin(alpha) * accelerometer[2];
    var z = -1 * sin(beta) * accelerometer[0] +
        cos(beta) * sin(alpha) * accelerometer[1] +
        cos(beta) * cos(alpha) * accelerometer[2];
    return Vector3(x, y, z);
  }

  Obstacles() {
    // ignore: close_sinks
    BehaviorSubject<Vector3> accelerometer = sensor.accelerometer;
    // ignore: close_sinks
    BehaviorSubject<Vector3> userAccelerometer = sensor.userAccelerometer;
    accelerometer.stream
        .map(reorient)
        .zipWith(userAccelerometer.stream, (t, s) => [t, s])
        .bufferTime(Duration(seconds: Config.samplingRate))
        .listen((event) {
      rule(event);
    });
  }

  dispose() {
    _signal.close();
  }
}

class Sensors {
  BehaviorSubject _accelerometerSub = BehaviorSubject<Vector3>();
  BehaviorSubject _userAccelerometerSub = BehaviorSubject<Vector3>();

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
