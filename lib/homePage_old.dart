import 'dart:async';
import 'dart:math';

import 'package:PPG/Palette.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'chart.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _toggled = false; // toggle button value
  List<SensorValue> _data = []; // array to store the values
  List<SensorValue> _finaldata = []; // array to store the values
  CameraController _controller;
  double _alpha = 0.3; // factor for the mean value
  AnimationController _animationController;
  double _iconScale = 1;
  int _bpm = 0; // beats per minute
  double _rmssd = 0;
  int _fs = 30; // sampling frequency (fps)
  int _windowLen = 30 * 6; // window length to display - 20 seconds
  CameraImage _image; // store the last camera image
  double _avg; // store the average value during calculation
  DateTime _now; // store the now Datetime
  Timer _timer; // timer for image processing

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animationController
      ..addListener(() {
        setState(() {
          _iconScale = 1.0 + _animationController.value * 0.4;
        });
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _toggled = false;
    _disposeController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String rmssdVal = "";
    try{
      rmssdVal = _rmssd.round().toString();
    }catch(Exception){
      print("ERROR: rmssd=${_rmssd}");
      rmssdVal = "--";
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("HRV Endurance"),
        backgroundColor: hrvEnduranceColor2,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[

            Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(height: 50,),
                    Center(child: Text(!_toggled ? "Pulse para comenzar a medir" : "Midiendo...",style: TextStyle(fontSize: 22),),),
                    /*
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(18),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: <Widget>[
                              _controller != null && _toggled
                                  ? AspectRatio(
                                      aspectRatio:
                                          _controller.value.aspectRatio,
                                      child: CameraPreview(_controller),
                                    )
                                  : Container(
                                      padding: EdgeInsets.all(12),
                                      alignment: Alignment.center,
                                      color: Colors.grey,
                                    ),
                              Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(4),
                                child: Text(
                                  _toggled
                                      ? "Cover both the camera and the flash with your finger"
                                      : "Camera feed will display here",
                                  style: TextStyle(
                                      backgroundColor: _toggled
                                          ? Colors.white
                                          : Colors.transparent),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),*/

                    Expanded(
                      flex: 1,
                      child: Center(
                          child: Transform.scale(
                            scale: _iconScale,
                            child: IconButton(

                              icon:
                              Icon(_toggled ? Icons.favorite : Icons.favorite_border),
                              color: hrvEnduranceColor2,
                              iconSize: 128,
                              onPressed: () {
                                if (_toggled) {
                                  _untoggle();
                                } else {
                                  _toggle();
                                }
                              },
                            ),
                          )),
                    ),
                  ],
                )),


            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "RMSSD",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            rmssdVal,//(_bpm > 30 && _bpm < 150 ? _bpm.toString() : "--"),
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Pulsaciones por \nminuto",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            (_bpm > 30 && _bpm < 150 ? _bpm.toString() : "--"),
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: Color.fromRGBO(254, 252, 230, 1)),
                child: Chart(_data, []),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearData() {
    // create array of 128 ~= 255/2
    _data.clear();
    _finaldata.clear();
    int now = DateTime
        .now()
        .millisecondsSinceEpoch;
    for (int i = 0; i < _windowLen; i++) {
      _data.insert(
          0,
          SensorValue(
              DateTime.fromMillisecondsSinceEpoch(now - i * 1000 ~/ _fs), 128));
      _finaldata.insert(
          0,
          SensorValue(
              DateTime.fromMillisecondsSinceEpoch(now - i * 1000 ~/ _fs), 128));
    }
  }
  void _toggle() {
    _clearData();
    _initController().then((onValue) {
      Wakelock.enable();
      _animationController?.repeat(reverse: true);
      setState(() {
        _toggled = true;
      });

      // after is toggled
      _initTimer();
      _update();

      //_update();
    });
  }

  void _untoggle() {
    _getLogOfData();
    _disposeController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.value = 0.0;
    setState(() {
      _toggled = false;
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _initController() async {
    try {
      List _cameras = await availableCameras();
      _controller = CameraController(_cameras.first, ResolutionPreset.low);
      await _controller.initialize();
      Future.delayed(Duration(milliseconds: 100)).then((onValue) {
        _controller.setFlashMode(FlashMode.torch);
      });
      _controller.startImageStream((CameraImage image) {
        _image = image;
      });
    } catch (Exception) {
      debugPrint(Exception);
    }
  }

  void _initTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fs), (timer) {
      if (_toggled) {
        if (_image != null) _scanImage(_image);
      } else {
        timer.cancel();
      }
    });
  }

  void _scanImage(CameraImage image) {
    _now = DateTime.now();
    _avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;
    if (_data.length >= _windowLen) {
      _data.removeAt(0);
    }
    setState(() {
      _data.add(SensorValue(_now, 255 - _avg));
      _finaldata.add(SensorValue(_now, 255 - _avg));

    });
  }
  void _update() async {
    await Future.delayed(Duration(
       seconds: 10));


    List<SensorValue> _values;
    double _avg;
    int _n;
    double _m;
    double _threshold;
    double _bpm;
    int _diff;
    int _counter;
    int _previous;
    List<int> diffValues = [];
    List<DateTime> timestamps = [];
    while (_toggled) {
      _values = List.from(_data);



      _avg = 0;
      _n = _values.length;

      _m = 0;
      _values.forEach((SensorValue value) {
        _avg += value.value / _n;
        if (value.value > _m) _m = value.value;
      });
      //_threshold = (_m + _avg) / 2;
      _threshold = (_m*0.3 + _avg*0.7);

      _bpm = 0;
      _counter = 0;
      _previous = 0;
      for (int i = 1; i < _n; i++) {
        if (_values[i - 1].value < _threshold &&
            _values[i].value > _threshold) {

          print("PULSACI??N ENCONTRADA");
          if (_previous != 0) {

            //Eliminar valores an??malos:
            int _diff =  _values[i].time.millisecondsSinceEpoch - _previous;
            if(_diff < 1200 && _diff > 500){

              timestamps.add(_values[i].time);
              diffValues.add(_diff);
            }


            //print("PREVIOUS: ${_previous}, NOW: ${_values[i].time.millisecondsSinceEpoch}",);

            /*CALCULAR BPM*/
            _counter++;
            _bpm += 60 *
                1000 /
                (_values[i].time.millisecondsSinceEpoch - _previous);

          }
          _previous = _values[i].time.millisecondsSinceEpoch;

        }
      }

      //*TEST*//
      String ret = "";

      for(int i = 0; i<_data.length;i++){
        ret += i.toString() + "," + _data[i].value.toString()+","+ (timestamps.contains(_data[i].time)?"1":"0")+"\n";
      }
      print(ret);
      //END TEST



      //BPM
      if (_counter > 0) {
        _bpm = _bpm / _counter;
        setState(() {
          _bpm = (1 - _alpha) * _bpm + _alpha * _bpm;
          this._bpm = _bpm.toInt();
          print(_bpm);
        });
      }

      _calculateRMSSD(diffValues);
      //diffValues.clear();
      timestamps.clear();
      /*
      if (_counter > 0) {
        _bpm = _bpm / _counter;
        print(_bpm);
        setState(() {
          this._bpm = ((1 - _alpha) * this._bpm + _alpha * _bpm).toInt();
        });
      }
      */

      await Future.delayed(Duration(
          milliseconds:
              1000 * _windowLen ~/ _fs)); // wait for a new set of _data values
    }
  }

  void _calculateRMSSD(List<int> values) {

    String diffs;
    for(int j = 0; j<values.length; j++){
      diffs += values[j].toString() + "\n";
    }
    print(values);
    double _sumatorio = 0;
    for(int i = 0; i<values.length-1;i++){

        int resta = values[i]-values[i+1];

        _sumatorio += resta*resta;
    }

    if(values.length>0){
      double x = _sumatorio/(values.length-1);

      var rmssd = sqrt(x);
      setState(() {
        print("RMSSD: ${rmssd}");
        if(rmssd > 20 && rmssd < 150){
          //_rmssd = (rmssd + _rmssd)/2;
          _rmssd = 0.3*rmssd + 0.7*_rmssd;
        }

      });
    }

  }

  void _getLogOfData() {
    String ret = "";

    for(int i = 0; i<_finaldata.length;i++){
      ret += i.toString() + "," + _finaldata[i].value.toString()+"\n";
    }
    print(ret);
  }
}


