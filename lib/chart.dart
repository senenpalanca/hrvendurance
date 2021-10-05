import 'package:PPG/Functions/functions.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class Chart extends StatelessWidget {
  final List<SensorValue> _data;
  final List<Peak> _peaks;
  Chart(this._data, this._peaks);

  @override
  Widget build(BuildContext context) {
    
    Color corporateColor = new Color.fromRGBO(254, 252, 230, 1);
    return new charts.TimeSeriesChart(

        [
      charts.Series<SensorValue, DateTime>(
        id: 'Values',
        colorFn: (_, __) => charts.Color.fromHex(code: "#18A7AD"),
        areaColorFn:  (_, __) => charts.Color.fromHex(code: "#FEFCE6"),
        fillColorFn: (_, __) => charts.Color.fromHex(code: "#FEFCE6"),
        patternColorFn: (_, __) => charts.Color.fromHex(code: "#FEFCE6"),

        domainFn: (SensorValue values, _) => values.time,
        measureFn: (SensorValue values, _) => values.value,
        data: _data,

      ),
          charts.Series<Peak, DateTime>(
            id: 'Values2',

            colorFn: (_, __) => charts.Color.fromHex(code: '#FC0707'),
            /*
            areaColorFn:  (_, __) => charts.Color.fromHex(code: "#FEFCE6"),
            fillColorFn: (_, __) => charts.Color.fromHex(code: "#FEFCE6"),
            patternColorFn: (_, __) => charts.Color.fromHex(code: "#FEFCE6"),
            */
            domainFn: (Peak values, _) => values.time,
            measureFn: (Peak values, _) => values.value,
            data: _peaks,
          )..setAttribute(charts.rendererIdKey, 'customPoint'),
    ],
        customSeriesRenderers: [
          charts.PointRendererConfig(
          // ID used to link series to this renderer.
            customRendererId: 'customPoint')],
        animate: false,
        primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec:
              charts.BasicNumericTickProviderSpec(zeroBound: false),
          renderSpec: charts.NoneRenderSpec(),
        ),
        domainAxis: new charts.DateTimeAxisSpec(
            renderSpec: new charts.NoneRenderSpec()));
  }
}

class SensorValue {
  final DateTime time;
  final double value;

  SensorValue(this.time, this.value);
}
