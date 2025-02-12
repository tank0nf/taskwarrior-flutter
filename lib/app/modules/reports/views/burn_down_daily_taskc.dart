// import 'dart:io';
// import 'dart:typed_data';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:taskwarrior/api_service.dart';
// import 'package:taskwarrior/app/models/chart.dart';
// import 'package:taskwarrior/app/modules/reports/views/common_chart_indicator.dart';
// import 'package:taskwarrior/app/utils/constants/taskwarrior_colors.dart';
// import 'package:taskwarrior/app/utils/constants/taskwarrior_fonts.dart';
// import 'package:taskwarrior/app/utils/constants/utilites.dart';
// import 'package:taskwarrior/app/utils/app_settings/app_settings.dart';
// import 'package:davinci/davinci.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:home_widget/home_widget.dart';
// import 'package:receive_intent/receive_intent.dart' as receive_intent;
// import 'package:flutter/services.dart'; // Import flutter services

// class BurnDownDailyTaskc extends StatefulWidget {
//   const BurnDownDailyTaskc({super.key});

//   @override
//   State<BurnDownDailyTaskc> createState() => _BurnDownDailyTaskcState();
// }

// class _BurnDownDailyTaskcState extends State<BurnDownDailyTaskc> {
//   final TooltipBehavior _dailyBurndownTooltipBehaviour = TooltipBehavior(
//     enable: true,
//     builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
//         int seriesIndex) {
//       final String date = data.x;
//       final int pendingCount = data.y1;
//       final int completedCount = data.y2;

//       return Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Date: $date',
//               style: GoogleFonts.poppins(
//                 fontWeight: TaskWarriorFonts.bold,
//               ),
//             ),
//             Text('Pending: $pendingCount'),
//             Text('Completed: $completedCount'),
//           ],
//         ),
//       );
//     },
//   );

//   Future<Map<String, Map<String, int>>> fetchDailyInfo() async {
//     TaskDatabase taskDatabase = TaskDatabase();
//     await taskDatabase.open();
//     List<Tasks> tasks = await taskDatabase.fetchTasksFromDatabase();
//     return _processData(tasks);
//   }

//   Map<String, Map<String, int>> _processData(List<Tasks> tasks) {
//     Map<String, Map<String, int>> dailyInfo = {};

//     // Sort tasks by entry date in ascending order
//     tasks.sort((a, b) => a.entry.compareTo(b.entry));

//     for (var task in tasks) {
//       final String date = Utils.formatDate(DateTime.parse(task.entry), 'MM-dd');

//       if (dailyInfo.containsKey(date)) {
//         if (task.status == 'pending') {
//           dailyInfo[date]!['pending'] = (dailyInfo[date]!['pending'] ?? 0) + 1;
//         } else if (task.status == 'completed') {
//           dailyInfo[date]!['completed'] =
//               (dailyInfo[date]!['completed'] ?? 0) + 1;
//         }
//       } else {
//         dailyInfo[date] = {
//           'pending': task.status == 'pending' ? 1 : 0,
//           'completed': task.status == 'completed' ? 1 : 0,
//         };
//       }
//     }

//     return dailyInfo;
//   }

//   final _chartKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//   }

//   Future<void> _requestPermissions() async {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.storage,
//     ].request();

//     print(statuses[Permission.storage]);
//   }

//   Future<void> _captureChart() async {
//     try {
//       RenderRepaintBoundary boundary =
//           _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       final image = await boundary.toImage();
//       final byteData = await image.toByteData(format: ImageByteFormat.png);
//       final pngBytes = byteData!.buffer.asUint8List();

//       // Get the documents directory
//       final directory = await getApplicationDocumentsDirectory();
//       final imagePath = '${directory.path}/daily_burndown_chart.png';

//       // Save the image to the documents directory
//       File imgFile = File(imagePath);
//       await imgFile.writeAsBytes(pngBytes);
//       print('Image saved to: $imagePath');
//       await HomeWidget.saveWidgetData<String>('chart_image', imagePath);

//       // Verify that the file exists
//       if (await imgFile.exists()) {
//         print('Image file exists!');
//       } else {
//         print('Image file does not exist!');
//       }

//       // Send a broadcast to update the widget
//       const platform = MethodChannel('com.example.taskwarrior/widget');
//       try {
//         await platform.invokeMethod('updateWidget');
//       } on PlatformException catch (e) {
//         print("Failed to Invoke: '${e.message}'.");
//       }
//     } catch (e) {
//       print('Error capturing chart: $e');
//     }
//   }

//   Widget _buildChart(double height) {
//     return FutureBuilder<Map<String, Map<String, int>>>(
//       future: fetchDailyInfo(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         Map<String, Map<String, int>> dailyInfo = snapshot.data ?? {};

//         return Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Expanded(
//               child: SizedBox(
//                 height: height * 0.6,
//                 child: RepaintBoundary(
//                   // key: _chartKey,
//                   child: SfCartesianChart(
//                     primaryXAxis: CategoryAxis(
//                       title: AxisTitle(
//                         text: 'Day - Month',
//                         textStyle: GoogleFonts.poppins(
//                           fontWeight: TaskWarriorFonts.bold,
//                           color: AppSettings.isDarkMode
//                               ? Colors.white
//                               : Colors.black,
//                           fontSize: TaskWarriorFonts.fontSizeSmall,
//                         ),
//                       ),
//                     ),
//                     primaryYAxis: NumericAxis(
//                       title: AxisTitle(
//                         text: 'Tasks',
//                         textStyle: GoogleFonts.poppins(
//                           fontWeight: TaskWarriorFonts.bold,
//                           fontSize: TaskWarriorFonts.fontSizeSmall,
//                           color: AppSettings.isDarkMode
//                               ? Colors.white
//                               : Colors.black,
//                         ),
//                       ),
//                     ),
//                     tooltipBehavior: _dailyBurndownTooltipBehaviour,
//                     series: <ChartSeries>[
//                       StackedColumnSeries<ChartData, String>(
//                         groupName: 'Group A',
//                         enableTooltip: true,
//                         color: TaskWarriorColors.green,
//                         dataSource: dailyInfo.entries
//                             .map((entry) => ChartData(
//                                   entry.key,
//                                   entry.value['pending'] ?? 0,
//                                   entry.value['completed'] ?? 0,
//                                 ))
//                             .toList(),
//                         xValueMapper: (ChartData data, _) => data.x,
//                         yValueMapper: (ChartData data, _) => data.y2,
//                         name: 'Completed',
//                       ),
//                       StackedColumnSeries<ChartData, String>(
//                         groupName: 'Group A',
//                         color: TaskWarriorColors.yellow,
//                         enableTooltip: true,
//                         dataSource: dailyInfo.entries
//                             .map((entry) => ChartData(
//                                   entry.key,
//                                   entry.value['pending'] ?? 0,
//                                   entry.value['completed'] ?? 0,
//                                 ))
//                             .toList(),
//                         xValueMapper: (ChartData data, _) => data.x,
//                         yValueMapper: (ChartData data, _) => data.y1,
//                         name: 'Pending',
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const CommonChartIndicator(
//               title: 'Daily Burndown Chart',
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     double height = MediaQuery.of(context).size.height; // Screen height
//     return _buildChart(height);
//   }
// }

// class ChartData {
//   ChartData(this.x, this.y1, this.y2);

//   final String x;
//   final int y1;
//   final int y2;
// }
