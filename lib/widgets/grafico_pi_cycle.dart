import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '/theme/colors.dart';

class GraficoPiCycle extends StatefulWidget {
  final Function()? onTap;

  const GraficoPiCycle({this.onTap, super.key});

  @override
  State<GraficoPiCycle> createState() => _GraficoPiCycleState();
}

class _GraficoPiCycleState extends State<GraficoPiCycle> {
  bool _loading = false;

  List<dynamic> _btcPriceList = [];
  List<dynamic> _ma111List = [];
  List<dynamic> _ma350x2List = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future _loadData() async {
    setState(() {
      _loading = true;
    });

    final url =
        'https://charts.bitcoin.com/api/v1/charts/pi-cycle-top?limit=365';
    /*
{
  "success": true,
  "chart": "pi-cycle-top",
  "description": "Pi Cycle Top Indicator - 111-day MA vs 350-day MA × 2",
  "interval": "daily×pan=1y",
  "dataPoints": 737,
  "data": {
    "price": [
      {
        "timestamp": 1767052800000,
        "price": 87164.0866666667
      },
    ],
    "ma111": [
      {
        "timestamp": 1768690800000,
        "value": 94997.8184684685
      },
    ],
    "ma350x2": [
      {
        "timestamp": 1769551200000,
        "value": 183232.942
      },
    ],
    "crosses": []
  },
  "metadata": {
    "ma111Period": 111,
    "ma350Period": 350,
    "multiplier": 2,
    "lastCross": null
  },
  "timestamp": 1770946736408
}
*/
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        // Handle error
        throw ('Failed http status code: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      if (jsonData['success'] != true) {
        // Handle error
        throw ('Failed to load data: JSON failed');
      }

      _btcPriceList = jsonData['data']['price'];
      _ma111List = jsonData['data']['ma111'];
      _ma350x2List = jsonData['data']['ma350x2'];
    } catch (e) {
      print('Error fetching data: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  List<FlSpot> _getChartSpots(List<dynamic> data, String atrName) {
    return data
        .map(
          (d) => FlSpot(
            (d['timestamp'] as num).toDouble(),
            (d[atrName] as num).toDouble(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_btcPriceList.isEmpty) {
      return Center(child: Text('No data available'));
    }

    // Determine min and max X and Y values for the chart
    double minTS = double.maxFinite;
    double maxTS = 0.0;
    for (var p = 0; p < _btcPriceList.length; p++) {
      var ts = (_btcPriceList[p]['timestamp'] as num).toDouble();
      if (ts < minTS) minTS = ts;
      if (ts > maxTS) maxTS = ts;
    }

    double maxPrice = -double.maxFinite;
    for (var p = 0; p < _ma350x2List.length; p++) {
      var m350 = (_ma350x2List[p]['value'] as num).toDouble();
      if (m350 > maxPrice) maxPrice = m350;
    }
    maxPrice += 10000;

    final firstDate = DateFormat('dd/MM/yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(_btcPriceList.first['timestamp']),
    );

    const styleLegenda = TextStyle(
      color: Colors.black,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    return AspectRatio(
      aspectRatio: 2.2,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: minTS,
              maxX: maxTS,
              minY: 0,
              maxY: maxPrice,
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(_btcPriceList, 'price'),
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              minX: minTS,
              maxX: maxTS,
              minY: 0,
              maxY: maxPrice,
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(_ma111List, 'value'),
                  color: AppColors.secondary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              minX: minTS,
              maxX: maxTS,
              minY: 0,
              maxY: maxPrice,
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(_ma350x2List, 'value'),
                  color: AppColors.goodjob,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Text('Início: $firstDate', style: styleLegenda),
          ),
          if (widget.onTap != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }
}
