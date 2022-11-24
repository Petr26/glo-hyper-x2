import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _mainController;
  late VideoPlayerController _introController;
  late VideoPlayerController _gameShowcaseController;
  late VideoPlayerController _winningGameController;
  late VideoPlayerController _loosingGameController;

  final _initVideoPauseTicks = 140;
  final _showcaseVideoPauseTicks = 124;
  final _timeFraction = 50;
  final _winCount = 4;
  late Timer _introTimer;
  late Timer _showcaseTimer;

  int phase = 1;
  int _spinCounter = 0;

  initListener() {
    if (_introController.value.isInitialized &&
        _introController.value.position == _introController.value.duration) {
      setState(() {
        _mainController = _gameShowcaseController;
        phase = 2;
        _mainController.play();
        _introController.removeListener(initListener);
        _gameShowcaseController.addListener(showcaseListener);
        _showcaseTimer =
            Timer.periodic(Duration(milliseconds: _timeFraction), (timer) {
          if (timer.tick == _showcaseVideoPauseTicks) {
            _gameShowcaseController.pause();
            timer.cancel();
          }
        });
      });
    }
  }

  showcaseListener() {
    if (_gameShowcaseController.value.isInitialized &&
        _gameShowcaseController.value.position ==
            _gameShowcaseController.value.duration) {
      setState(() {
        if (_spinCounter % _winCount == 0) {
          _mainController = _winningGameController;
        } else {
          _mainController = _loosingGameController;
        }
        phase = 3;
        _mainController.play();
        _gameShowcaseController.removeListener(showcaseListener);
      });
    }
  }

  Future<void> init({bool dispose = true}) async {
    phase = 1;
    if (dispose) {
      await _mainController.dispose();
      await _introController.dispose();
      await _loosingGameController.dispose();
      await _winningGameController.dispose();
      await _gameShowcaseController.dispose();
    }

    _introController = VideoPlayerController.asset('lib/assets/intro.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          _mainController.play();
        });
      });

    _mainController = _introController;
    _gameShowcaseController =
        VideoPlayerController.asset('lib/assets/showcase.mp4')..initialize();
    _winningGameController = VideoPlayerController.asset('lib/assets/win.mp4')
      ..initialize();
    _loosingGameController = VideoPlayerController.asset('lib/assets/loose.mp4')
      ..initialize();

    _introTimer =
        Timer.periodic(Duration(milliseconds: _timeFraction), (timer) {
      if (timer.tick == _initVideoPauseTicks) {
        _introController.pause();
        timer.cancel();
      }
    });

    _introController.addListener(initListener);
  }

  @override
  void initState() {
    super.initState();
    init(dispose: false);
  }

  @override
  void dispose() {
    super.dispose();
    _introController.dispose();
    _gameShowcaseController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late Color iconColor;
    if (phase == 1) {
      iconColor = const Color(0x8Aea6d52);
    } else if (phase == 2) {
      iconColor = Colors.white54;
    } else {
      iconColor = const Color(0x8Acf1445);
    }

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _mainController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _mainController.value.aspectRatio,
                    child: VideoPlayer(_mainController),
                  )
                : Container(),
          ),
          if (phase == 1)
            Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    if (_introTimer.isActive) {
                      _introTimer.cancel();
                    }
                    setState(() {
                      _mainController
                          .seekTo(const Duration(milliseconds: 7250));
                      _mainController.play();
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 100,
                        color: Colors.transparent,
                      )
                    ],
                  ),
                )),
          if (phase == 2)
            Positioned(
                bottom: 120,
                right: 200,
                child: GestureDetector(
                  onVerticalDragEnd: (s) {
                    if (_showcaseTimer.isActive) {
                      _showcaseTimer.cancel();
                    }
                    setState(() {
                      _spinCounter++;
                      _mainController
                          .seekTo(const Duration(milliseconds: 7000));
                      _mainController.play();
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 350,
                        height: 500,
                        color: Colors.transparent,
                      )
                    ],
                  ),
                )),
          if (phase == 3)
            Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    await init();
                    setState(() {});
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 80,
                        color: Colors.transparent,
                      )
                    ],
                  ),
                )),
          Positioned(
              top: 25,
              right: 25,
              child: IconButton(
                  onPressed: () async {
                    await SystemChannels.platform
                        .invokeMethod<void>('SystemNavigator.pop', true);
                  },
                  icon: Icon(
                    CupertinoIcons.clear,
                    size: 32,
                    color: iconColor,
                  ))),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       _introController.value.isPlaying
      //           ? _introController.pause()
      //           : _introController.play();
      //     });
      //   },
      //   child: Icon(
      //     _introController.value.isPlaying ? Icons.pause : Icons.play_arrow,
      //   ),
      // ),
    );
  }
}
