import 'package:flutter/material.dart';

class VideoTimeLapse extends StatefulWidget {
  const VideoTimeLapse({
    Key? key,
    this.height = 160,
    required this.timeList,
    required this.timeFocusChanged,
    required this.previousCallBack,
    required this.nextDateCallBack,
    this.timeLineExteriorColor = Colors.grey,
    this.timeLineColor = Colors.lightBlueAccent,
    this.timeLineBackgroundColor = Colors.white,
    this.focusAndTimeTextBackgroundColor = Colors.red,
    this.timeLineHandColor = Colors.black,
    this.timeTextColor = Colors.white,
  }) : super(key: key);

  /// 높이
  final double height;

  /// 비디오 시간 목록
  final List<bool> timeList;

  /// 중심 시간값 변경 시 호출
  final ValueChanged<String> timeFocusChanged;

  /// 이전 지점 도착 시 호출
  final VoidCallback previousCallBack;

  /// 다음 지점 도착 시 호출
  final VoidCallback nextDateCallBack;

  /// 타임 라인 외장 칼라
  final Color timeLineExteriorColor;

  /// 타임 라인 색상
  final Color timeLineColor;

  /// 타임 라인 배경 색상
  final Color timeLineBackgroundColor;

  /// 타임 시간 시간 침 색상
  final Color timeLineHandColor;

  /// 시간 텍스트 색상
  final Color timeTextColor;

  /// 표적 및 시간 텍스트 배경 색상
  final Color focusAndTimeTextBackgroundColor;

  @override
  State<VideoTimeLapse> createState() => VideoTimeLapseState();
}

class VideoTimeLapseState extends State<VideoTimeLapse> {
  /// 비디오 스크롤 컨트롤러
  late final ScrollController videoScrollController;

  /// 시간 스크롤 컨트롤러
  late final ScrollController timeScrollController;

  // ------------------------------------------------

  /// 일반 배율
  late double scale = zoomLevel2Scale;

  late ValueNotifier<double> widgetSizeNotifier = ValueNotifier(zoomLevel1Scale / 10);

  /// 줌 레벨1 스케일
  final double zoomLevel1Scale = 30;

  /// 줌 레벨2 스케일
  final double zoomLevel2Scale = 45;

  /// 줌 레벨3 스케일
  final double zoomLevel3Scale = 90;

  // ------------------------------------------------

  /// 최소 줌 스케일
  double get minScale => zoomLevel1Scale;

  /// 최대 줌 스케일
  double get maxScale => zoomLevel3Scale;

  bool get isZoomLevel1 => scale < zoomLevel2Scale && scale >= zoomLevel1Scale;
  bool get isZoomLevel2 => scale < zoomLevel3Scale && scale >= zoomLevel2Scale;
  bool get isZoomLevel3 => scale == zoomLevel3Scale;

  // ------------------------------------------------

  /// 하루 -> 초로 환산
  int get dayInSeconds => 86400;

  // ------------------------------------------------

  /// 중심 시간 초 데이터
  int focusTimeInSeconds = 0;

  /// 터치 카운트
  int pointerCount = 0;

  /// 스크롤 가능 여부 알림
  ValueNotifier<bool> useScrollNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    videoScrollController = ScrollController();
    timeScrollController = ScrollController();
    videoScrollController.addListener(() {
      /// 스크롤 동기화
      timeScrollController.jumpTo(videoScrollController.offset);

      // 시작 지점 콜백
      if (videoScrollController.offset == 0) {
        widget.previousCallBack();
        return;
      }

      // 종료 지점 콜백
      if (videoScrollController.offset.toInt() == videoScrollController.position.maxScrollExtent.toInt()) {
        widget.nextDateCallBack();
        return;
      }
    });
  }

  @override
  void dispose() {
    videoScrollController.dispose();
    timeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.timeLineExteriorColor,
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  Listener(
                    onPointerDown: (event) {
                      pointerCount += 1;
                      if (pointerCount == 2) {
                        useScrollNotifier.value = false;
                      }
                    },
                    onPointerUp: (event) {
                      pointerCount -= 1;
                      if (pointerCount == 1) {
                        useScrollNotifier.value = true;
                      }
                    },
                    child: GestureDetector(
                      // onScaleStart: (details) {
                      //   if (details.pointerCount == 2) {
                      //     // 줌 시작 전 위치 저장
                      //     focusTimeInSeconds = _scrollOffsetToTimeInSeconds();
                      //   }
                      // },
                      onScaleUpdate: (details) {
                        if (details.pointerCount == 2) {
                          /// 핀치줌(가로) 사이즈를 줄일때
                          if (details.scale < 1.0 && scale > minScale) {
                            scale -= 0.5;
                            widgetSizeNotifier.value = scale / 10;
                            return;
                          }

                          /// 핀치줌(가로) 사이즈를 늘릴때
                          if (details.scale > 1.0 && scale < maxScale) {
                            scale += 0.5;
                            widgetSizeNotifier.value = scale / 10;
                            return;
                          }
                        }
                      },
                      // onScaleEnd: (details) {
                      //   // 줌 위치 보정
                      //   double newOffset = _timeInSecondsToScrollOffset(focusTimeInSeconds.toDouble());
                      //   videoScrollController.animateTo(newOffset, duration: Durations.extralong1, curve: Curves.easeIn);
                      // },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          // 스크롤이 끝났을때 감지
                          if (scrollNotification is ScrollEndNotification) {
                            String hhmmss = _formatSecondsToHHMMSS(_scrollOffsetToTimeInSeconds());
                            widget.timeFocusChanged(hhmmss);
                          }
                          return true;
                        },
                        child: ValueListenableBuilder(
                            valueListenable: useScrollNotifier,
                            builder: (context, value, __) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: videoScrollController,
                                physics: value ? null : const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: (constraints.maxWidth / 2)),
                                child: Row(
                                  children: List.generate(widget.timeList.length, (index) {
                                    var item = widget.timeList[index];
                                    return ValueListenableBuilder(
                                        valueListenable: widgetSizeNotifier,
                                        builder: (context, value, __) {
                                          return Stack(
                                            children: [
                                              Container(
                                                width: value,
                                                decoration: BoxDecoration(
                                                  color: item ? widget.timeLineColor : widget.timeLineBackgroundColor,
                                                  border: Border.all(
                                                    width: 0,
                                                    color: item ? widget.timeLineColor : widget.timeLineBackgroundColor,
                                                  ),
                                                ),
                                              ),
                                              if (index % 60 == 0) ...[
                                                _buildTimeLineHand(30)
                                              ] else if (index % 30 == 0) ...[
                                                _buildTimeLineHand(20)
                                              ] else if (index % 10 == 0 && (isZoomLevel2 || isZoomLevel3)) ...[
                                                _buildTimeLineHand(10)
                                              ] else if (index % 2 == 0 && isZoomLevel3) ...[
                                                _buildTimeLineHand(5)
                                              ]
                                            ],
                                          );
                                        });
                                  }),
                                ),
                              );
                            }),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 20,
                          child: CustomPaint(
                            painter: _TimeLapseFocusHandPainter(widget.focusAndTimeTextBackgroundColor),
                            child: const Center(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: widgetSizeNotifier,
              builder: (context, value, _) {
                if (isZoomLevel1) {
                  return SingleChildScrollView(
                    controller: timeScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: (widget.timeList.length * value) + constraints.maxWidth,
                      height: 20,
                      color: widget.focusAndTimeTextBackgroundColor,
                      child: Stack(
                        children: List.generate(24, (index) {
                          final hour = index;

                          return Positioned(
                            left: (constraints.maxWidth / 2) + (value * 60 * index).toDouble() - 17,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                color: widget.timeTextColor,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                } else if (isZoomLevel2) {
                  return SingleChildScrollView(
                    controller: timeScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: (widget.timeList.length * value) + constraints.maxWidth,
                      height: 20,
                      color: widget.focusAndTimeTextBackgroundColor,
                      child: Stack(
                        children: List.generate(48, (index) {
                          final isEvenIndex = index % 2 == 0;
                          final minute = isEvenIndex ? '00' : '30';
                          final hour = index ~/ 2;

                          return Positioned(
                            left: (constraints.maxWidth / 2) + (value * 30 * index).toDouble() - 17,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:$minute',
                              style: TextStyle(
                                color: widget.timeTextColor,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                } else if (isZoomLevel3) {
                  return SingleChildScrollView(
                    controller: timeScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: (widget.timeList.length * value) + constraints.maxWidth,
                      height: 20,
                      color: widget.focusAndTimeTextBackgroundColor,
                      child: Stack(
                        children: List.generate(144, (index) {
                          final hour = index ~/ 6;
                          final minute = (index % 6) * 10;

                          return Positioned(
                            left: (constraints.maxWidth / 2) + (value * 10 * index).toDouble() - 17,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: widget.timeTextColor,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        );
      }),
    );
  }

  /// 분침 위젯
  Widget _buildTimeLineHand(double height) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          width: 2,
          height: height,
          color: widget.timeLineHandColor,
        ),
      ),
    );
  }

  /// 초(하루) -> 스크롤 위치
  double _timeInSecondsToScrollOffset(double timeInSeconds) {
    // 시간의 최솟값과 최댓값 정의
    double minValue = 0.0;
    double maxValue = videoScrollController.position.maxScrollExtent;

    // 시간의 범위를 구간 수로 나누기
    double intervalSize = (maxValue - minValue) / dayInSeconds;

    // 주어진 시간을 새 범위로 변환
    double newValue = timeInSeconds * intervalSize;

    return newValue;
  }

  /// 스크롤 위치 -> 초(하루)
  int _scrollOffsetToTimeInSeconds() {
    // 현재 스크롤 위치
    double currentOffset = videoScrollController.offset;

    // 범위와 구간 수 정의
    double minValue = 0.0;
    double maxValue = videoScrollController.position.maxScrollExtent;
    int intervals = dayInSeconds;

    // 각 구간의 크기 계산
    double intervalSize = (maxValue - minValue) / intervals;

    // 주어진 값이 몇 번째 구간에 속하는지 계산
    int intervalIndex = ((currentOffset - minValue) / intervalSize).floor();

    return intervalIndex;
  }

  /// 초 ->  hh:mm:ss 포맷으로 변환
  String _formatSecondsToHHMMSS(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  /// 시간에 맞는 위치로 이동
  void moveVideoTimeFocus(String dateTimeData) {
    // if (pointerCount != 0) return;
    DateTime dateTime = DateTime.parse(dateTimeData.replaceAll('.', '-'));
    int seconds = dateTime.hour * 3600 + dateTime.minute * 60 + dateTime.second;
    double newOffset = _timeInSecondsToScrollOffset(seconds.toDouble());
    videoScrollController.jumpTo(newOffset);
  }
}

/// 타입랩스 현재 시점 침 표시 위젯
class _TimeLapseFocusHandPainter extends CustomPainter {
  const _TimeLapseFocusHandPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var width = size.width;
    var lineWidth = width / 10;
    var height = size.height;

    var path = Path();
    path.moveTo((width / 2) - lineWidth, 0);
    path.lineTo((width / 2) + lineWidth, 0);
    path.lineTo((width / 2) + lineWidth, height - width);
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.lineTo((width / 2) - lineWidth, height - width);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
