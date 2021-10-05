import 'dart:async';
import 'dart:math';

import 'package:PPG/Functions/functions.dart';
import 'package:PPG/Palette.dart';
import 'package:PPG/detail-page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scidart/numdart.dart';
import 'package:wakelock/wakelock.dart';
import 'chart.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends State<HomePage> with SingleTickerProviderStateMixin, TickerProviderStateMixin  {
  bool _toggled = false; // toggle button value
  List<SensorValue> _data = []; // array to store the values
  List<SensorValue> _finaldata = []; // array to store the values
  CameraController _controller;

  double _alpha = 0.3; // factor for the mean value
  AnimationController _animationController;
  AnimationController _animationController2;
  double _iconScale = 1;
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
          _iconScale = 1.0 + _animationController.value * 0.2;
        });
      });

    _animationController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..addListener(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _toggled = false;
    _disposeController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.dispose();
    _animationController2?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

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


                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                width: 165,
                                height: 165,
                                child: CircularProgressIndicator(
                                    strokeWidth: 7,
                                    value: _animationController2.value,
                                    semanticsLabel: 'Linear progress indicator',
                                    valueColor: AlwaysStoppedAnimation<Color>(hrvEnduranceColor2)
                                ),
                              ),
                            ),
                          ),
                          Center(
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

                        ],
                      ),
                    ),
                  ],
                )),



            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: Color.fromRGBO(254, 252, 230, 1)),
                child: Chart(_data,[]),
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
      _animationController2.repeat(reverse: false);
      setState(() {
        _toggled = true;
      });

      // after is toggled
      _initTimer();
      _untoggleAfterSeconds(40);

      //_update();
    });
  }

  void _untoggle() {
    _disposeController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController2.stop();
    _animationController?.value = 0.0;
    _animationController2.value = 0.0;
    setState(() {
      _toggled = false;
    });
    processData();
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

  void _untoggleAfterSeconds(int i) async {
    await Future.delayed(Duration(
        seconds: i));
    _untoggle();
  }

  void processData() {

    List<SensorValue> peaks = [];

    // _finaldata.sublist(180,_finaldata.length);
    for(int i = 220; i< _finaldata.length;i++){
      peaks.add(_finaldata[i]);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPage(data: peaks,)),
    );
  }



}


