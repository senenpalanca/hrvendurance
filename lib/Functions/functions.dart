
import 'package:PPG/chart.dart';
import 'package:scidart/src/numdart/numdart.dart';


const double infinity = 1.0 / 0.0;
class Peak {
  Peak({this.position, this.value, this.time});
  DateTime time;
  int position;
  double value;
}

class PeakResult{
  List<Peak> maxtab;
  List<Peak> mintab;
  PeakResult({this.maxtab,this.mintab});
}

PeakResult peakDetector(List<SensorValue> arr, double delta){


  List<Peak> maxtab = [];
  List<Peak> mintab = [];

  Array v = Array(arr.map((e) => e.value).toList());

  Array x = arange(stop: v.length);

  Array helper = arange(stop: v.length);

  double mn = infinity;
  double mx =-infinity;
  int mxpos = null;
  int mnpos = null;
  bool lookForMax = true;

  if(delta <= 0){
    return new PeakResult(maxtab: List.empty(), mintab: List.empty());
  }

  int length = x.length;

  for(int i = 0; i<x.length;i++){

    double selected = v[i];
    if(selected > mx){
      mx = selected;
      mxpos = x[i].toInt();
    }
    if(selected < mn){
      mn = selected;
      mnpos = x[i].toInt();
    }
    if(lookForMax){

      if(selected < mx-delta){
        maxtab.add(new Peak(position: mxpos,value: mx, time: arr[i].time));
        mn = selected;
        mnpos = x[i].toInt();
        lookForMax = false;
      }
    }else{
      if(selected> mn+delta){
        mintab.add(new Peak(position: mnpos,value: mn,  time: arr[i].time));
        mx = selected;
        mxpos = x[i].toInt();
        lookForMax = true;
      }
    }
    print("Resultado: ${mintab}");

  }
  return  PeakResult(maxtab: maxtab, mintab: mintab);;
/*
  for i in arange(len(v)):
  this = v[i]
  if this > mx:
  mx = this
  mxpos = x[i]
  if this < mn:
  mn = this
  mnpos = x[i]

  if lookformax:
  if this < mx-delta:
  maxtab.append((mxpos, mx))
  mn = this
  mnpos = x[i]
  lookformax = False
  else:
  if this > mn+delta:
  mintab.append((mnpos, mn))
  mx = this
  mxpos = x[i]
  lookformax = True

  return array(maxtab), array(mintab)
  */

}


