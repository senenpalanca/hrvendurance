import 'dart:math';

import 'package:PPG/Functions/functions.dart';
import 'package:PPG/Palette.dart';
import 'package:PPG/chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:iirjdart/butterworth.dart';



class DetailPage extends StatefulWidget {
  final List<SensorValue> data;
  DetailPage({Key key, this.data}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<Peak> _peaks = [];
  String _diffs = "";
  int HR = 0;
  int HRV = 0;
  int RMSSD = 0;
  int numErrors = -1;
  @override
  Widget build(BuildContext context) {

    //print("Numero de datos ${widget.data.length}");
    //print("1. ${_calculateRMSSD([845,745 ,812 ,732 ])}");
    ///print("2. ${_calculateRMSSD([])}");
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
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "HRV",
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
              ),
              numErrors>-1 ? Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Número de errores",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        numErrors.toString(),//(_bpm > 30 && _bpm < 150 ? _bpm.toString() : "--"),
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),

                    ],
                  ),
                ),
              ) : Container()],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Divider(),
          ),
          Row(
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
                        RMSSD.toString(),//(_bpm > 30 && _bpm < 150 ? _bpm.toString() : "--"),
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
],
          ),

          SizedBox(height: 30,),
          numErrors>-1 ? Center(child: Text("Datos erróneos. Por favor, repite la medición", style: TextStyle(color: Colors.red, fontSize: 20),textAlign:TextAlign.center,)): Container(),
          Center(child:  OutlinedButton(
            onPressed: () => _SendEmail(_diffs),
            child: Text("Enviar Email con Peaks"),
          ),)

        ],
      ),
    );
  }

  void calculatePeaks()  {
    //List peaks =  peakDetector(data, 0.2).map((e) => e.value);
    final List<SensorValue> _data = _lowPassFilter(widget.data);
    PeakResult res =  peakDetector(_data, 0.40);
    List<Peak> peaks = res.maxtab;
    List<Peak> minPeaks = res.mintab;
   // peaks = _timeFilter(peaks, minPeaks);
    setState(() {
      _peaks = peaks;
    });
    _calculateData();
  }

  List<Peak> _timeFilter(List<Peak> peaks,List<Peak> minPeaks) {
    double tiempoMinimoEntreLatidos = 0;
    double tiempoMaximoEntreLatidos = 1500;
    List<Peak> result = [];

    for (int i = 1; i<peaks.length-1;i++){
      int milliActual = peaks[i].time.millisecondsSinceEpoch;
      int milliAnterior = peaks[i-1].time.millisecondsSinceEpoch;
      int milliPosterior = peaks[i+1].time.millisecondsSinceEpoch;
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
  List<Peak> _timeFilteroLD(List<Peak> peaks,List<Peak> minPeaks) {
    double tiempoMinimoEntreLatidos = 0;
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
    var resExcel = "";

    if(_peaks.isNotEmpty){
      List<int> diffs = [];
      for (int i = 0; i<_peaks.length-1;i++){
        diffs.add(_peaks[i+1].time.millisecondsSinceEpoch-_peaks[i].time.millisecondsSinceEpoch);
      }
      for(int x = 0; x < diffs.length; x++){
        resExcel += "${diffs[x]},";
      }
      print(resExcel);
      _diffs = resExcel;
      var _hrv = _calculateRMSSD(diffs).toInt();
      setState(() {
        HRV = _hrv;
      });
    }else{


        setState(() {
          numErrors = 0;
        });

    }

  }
  double _calculateRMSSD(List<int> values) {

    _orderAndRemove(values);

    double _sumatorio = 0;
    int errors = 0;
    for(int i = 1; i<values.length;i++){
      if(values[i]>1600){
        errors += 1;
      }
      int resta = values[i]-values[i-1];
      print("RESTA: ${resta}");
      _sumatorio += resta*resta;
    }
    //Errors management
    if (errors > 1 ){
      setState(() {
        numErrors = errors;
      });
    }
    //End Errors management
    print("SUMATORIO: ${_sumatorio}");
    if(values.length>0){
      double x = _sumatorio/(values.length-1);
      var rmssd = sqrt(x);
      setState(() {
        RMSSD = rmssd?.toInt()??0;
      });
      var logrmssd = log(rmssd);
      return logrmssd*10;
    }
    //ESCALA

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

  void _orderAndRemove(List<int> values) {
    List values2 = List.from(values);

    values2.sort();
    //Eliminar 5% de extremos
    if(values2.length > 20){
      var y = values2.length / 20;
      var x = y.toInt();
      values2 = values2.sublist(x,values.length-x);
    }

    print("Numero val1: ${values.length}, Numero val2: ${values2.length}");

    for(int i = 0; i<values.length;i++) {
      if(!values2.contains(values[i])) {
        values.removeAt(i);
      }
    }
    print("values: "+values.toString());
  }

  _SendEmail(String data) async {
    final Email email = Email(
      body: data ,
      subject: 'HRV Endurance - Logs ${DateTime.now()}',
      recipients: ['senenpalanca@gmail.com'],
      cc: ['senenpalanca@gmail.com'],
      bcc: ['senenpalanca@gmail.com'],
      //attachmentPaths: ['/path/to/attachment.zip'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);

  }

}
