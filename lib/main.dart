// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_video_time/video_time_lapse.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: MyBehavior(),
          child: child!,
        );
      },
      home: const SamplePage(),
    );
  }
}

GlobalKey<VideoTimeLapsState> timeLapseKey = GlobalKey();
DateTime sampleDateTime = DateTime.parse('2023.01.07 13:39:22'.replaceAll('.', '-'));

Timer? myTimer;

class SamplePage extends StatelessWidget {
  const SamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    List<bool> timeList = [];
    for (int i = 0; i < 1440; i++) {
      timeList.add(Random().nextBool());
    }
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black54,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoTimeLaps(
                key: timeLapseKey,
                timeList: timeList,
                timeFocusChanged: (value) {
                  print('현재 시간 : $value');
                },
                previousCallBack: () {
                  print('이전 날짜 콜백');
                },
                nextDateCallBack: () {
                  print('다음 날짜 콜백');
                },
              ),
              const SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 40),
          FloatingActionButton(
            heroTag: 'stop',
            onPressed: () {
              // stop
              myTimer?.cancel();
            },
            child: const Text('stop'),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'x1',
            onPressed: () {
              // 1초당 1번 호출
              Timer.periodic(const Duration(milliseconds: 1000), (timer) {
                myTimer = timer;
                sampleDateTime = sampleDateTime.add(const Duration(seconds: 1));
                String formattedDateTime = DateFormat('yyyy.MM.dd HH:mm:ss').format(sampleDateTime);
                timeLapseKey.currentState!.moveVideoTimeFocus(formattedDateTime);
              });
            },
            child: const Text('x1'),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'x60',
            onPressed: () {
              // 1초당 60번 호출
              Timer.periodic(const Duration(milliseconds: 16), (timer) {
                myTimer = timer;
                sampleDateTime = sampleDateTime.add(const Duration(seconds: 1));
                String formattedDateTime = DateFormat('yyyy.MM.dd HH:mm:ss').format(sampleDateTime);
                timeLapseKey.currentState!.moveVideoTimeFocus(formattedDateTime);
              });
            },
            child: const Text('x60'),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'x120',
            onPressed: () {
              // 1초당 60번 호출
              Timer.periodic(const Duration(milliseconds: 8), (timer) {
                myTimer = timer;
                sampleDateTime = sampleDateTime.add(const Duration(seconds: 1));
                String formattedDateTime = DateFormat('yyyy.MM.dd HH:mm:ss').format(sampleDateTime);
                timeLapseKey.currentState!.moveVideoTimeFocus(formattedDateTime);
              });
            },
            child: const Text('x120'),
          ),
        ],
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
