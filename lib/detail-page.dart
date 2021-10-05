import 'dart:math';

import 'package:PPG/Functions/functions.dart';
import 'package:PPG/Palette.dart';
import 'package:PPG/chart.dart';
import 'package:flutter/material.dart';
import 'package:iirjdart/butterworth.dart';



class DetailPage extends StatefulWidget {
  final List<SensorValue> data;
  DetailPage({Key key, this.data}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<Peak> _peaks = [];
  int HR = 0;
  int HRV = 0;
  @override
  Widget build(BuildContext context) {
    print("Numero de datos ${widget.data.length}");

    calculatePeaks();

    return Scaffold(
      appBar: AppBar(
        title: Text("HRV Endurance"),
        backgroundColor: hrvEnduranceColor2,
      ),
      backgroundColor: Colors.white,
      body:ListView(
        children: <Widget>[
        SizedBox(height: 20,),
         Padding(
           padding: const EdgeInsets.all(16.0),
           child: Row(
             children: [ Text("Gráfica ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),],
           ),
         ),
          Container(
            height: 200,
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: Color.fromRGBO(254, 252, 230, 1)),
            child: Chart(widget.data, _peaks),
          ),
          SizedBox(height: 20,),
          Row(
            children: [Expanded(
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
                      HRV.toString(),//(_bpm > 30 && _bpm < 150 ? _bpm.toString() : "--"),
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
                        HR.toString(),//(_bpm > 30 && _bpm < 150 ? _bpm.toString() : "--"),
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),

                    ],
                  ),
                ),
              ),],
          )



        ],
      ),
    );
  }

  void calculatePeaks()  {
    //List peaks =  peakDetector(data, 0.2).map((e) => e.value);
    final List<SensorValue> _data = _lowPassFilter(widget.data);
    PeakResult res =  peakDetector(_data, 0.25);
    List<Peak> peaks = res.maxtab;
    List<Peak> minPeaks = res.mintab;
    peaks = _timeFilter(peaks, minPeaks);

    setState(() {
      _peaks = peaks;
    });
    _calculateData();
  }

  List<Peak> _timeFilter(List<Peak> peaks,List<Peak> minPeaks) {
    double tiempoMinimoEntreLatidos = 350;
    double tiempoMaximoEntreLatidos = 1500;
    List<Peak> result = [];
    for (int i = 1; i<peaks.length-1;i++){
      int milliActual = peaks[i].time.millisecondsSinceEpoch;
      int milliAnterior = peaks[i-1].time.millisecondsSinceEpoch;
      if(milliActual -milliAnterior>tiempoMinimoEntreLatidos &&
          milliActual- milliAnterior<tiempoMaximoEntreLatidos){
        if(i>0){
          double valAnterior = peaks[i-1].value;
          double valActual = peaks[i].value;
          double diferenciaConValleAct = valActual - minPeaks[i]?.value??0;
          double diferenciaConValleAnt = valAnterior - minPeaks[i]?.value??0;
          result.add(peaks[i]);
          //print("Minimo valor: ${minPeaks[i].value},Valor Actual: ${valActual} Dif actual: ${diferenciaConValleAct}, difAnterior: ${diferenciaConValleAnt}");
          //result.add(peaks[i]);
            /* NO UTIL, REVISAR
             if(diferenciaConValleAct / diferenciaConValleAnt > 0.70 && milliActual- milliAnterior>tiempoMinimoEntreLatidos)
              result.add(peaks[i]);

           r  */

        }
      }
    }
    return result;
  }

  void _calculateData()  {

    _calculateHR();
    _calculateHRV();


  }

  void _calculateHR() {
    int hr = 0;
    if(_peaks.isNotEmpty){
      int milliPrimero = _peaks[0].time.millisecondsSinceEpoch;
      int milliUltimo = _peaks[_peaks.length-1].time.millisecondsSinceEpoch;
      int diff = milliUltimo - milliPrimero;

      if(diff>0){
        int latidos = _peaks.length;

        double _hr = (60*latidos*1000)/diff;
        setState(() {
          HR = _hr.round();
        });
        //print("Numero de latidos: ${latidos}, HR: ${_hr}, diferencia de tiempo: ${diff}");

      }
    }




  }
  void _calculateHRV() {
    if(_peaks.isNotEmpty){
      List<int> diffs = [];
      for (int i = 0; i<_peaks.length-1;i++){
        diffs.add(_peaks[i+1].time.millisecondsSinceEpoch-_peaks[i].time.millisecondsSinceEpoch);
      }
      print(diffs);
      var _hrv = _calculateRMSSD(diffs).toInt();
      setState(() {
        HRV = _hrv;
      });
    }

  }
  double _calculateRMSSD(List<int> values) {

    double _sumatorio = 0;
    for(int i = 0; i<values.length-1;i++){

      int resta = values[i]-values[i+1];

      _sumatorio += resta*resta;
    }

    if(values.length>0){
      double x = _sumatorio/(values.length-1);

      var rmssd = sqrt(x);
      return rmssd;
    }

  }
  List<SensorValue> _lowPassFilter(List<SensorValue> dataToFilter) {

    Butterworth butterworth = Butterworth();
    butterworth.lowPass(4, 1000,10);
    List<SensorValue> filteredData = [];
    for(var v in dataToFilter) {
      filteredData.add(new SensorValue(v.time, v.value));
    }
    return filteredData;

  }
}
