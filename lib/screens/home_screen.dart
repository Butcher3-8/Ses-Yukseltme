import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color gold = Color(0xFFFFD700); // Custom gold color
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  late AudioPlayer _audioPlayer;
  double _volume = 1.0;
  String? _fileName;
  String? _filePath;
  bool _isVideo = false;
  bool _isLoading = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _audioPosition = position);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });
  }

  Future<void> _loadFile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'mp3', 'wav'],
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        _isVideo = result.files.single.extension == 'mp4' || result.files.single.extension == 'mov';
      });

      try {
        if (_isVideo) {
          _videoPlayerController = VideoPlayerController.file(File(_filePath!));
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: false,
            looping: false,
            materialProgressColors: ChewieProgressColors(
              playedColor: gold,
              handleColor: Colors.white,
              backgroundColor: Colors.grey[800]!,
              bufferedColor: Colors.grey[600] ?? Colors.grey,
            ),
          );
          await _videoPlayerController.initialize();
        } else {
          await _audioPlayer.stop();
          await _audioPlayer.setSourceDeviceFile(_filePath!);
          await _audioPlayer.setVolume(_volume);
        }
        setState(() {});
      } catch (e) {
        print('Error loading file: $e');
        setState(() {
          _filePath = null;
          _fileName = 'Error loading file: $e';
        });
      }
    }
    setState(() => _isLoading = false);
  }

  void _seekAudio(Duration position) {
    if (!_isLoading && !_isVideo && _audioDuration.inSeconds > 0) {
      _audioPlayer.seek(position);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.grey[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[850]!.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player Area
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gold, Colors.deepPurple[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: gold))
                        : _filePath != null && (_isVideo ? _videoPlayerController.value.isInitialized : true)
                            ? _isVideo
                                ? Chewie(
                                    controller: _chewieController,
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _audioPlayer.state == PlayerState.playing ? Icons.stop : Icons.music_note,
                                          color: gold,
                                          size: 60,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${_audioPosition.inMinutes}:${(_audioPosition.inSeconds % 60).toString().padLeft(2, '0')} / '
                                          '${_audioDuration.inMinutes}:${(_audioDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  )
                            : Center(
                                child: Text(
                                  _fileName ?? 'Select a file to play',
                                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                                ),
                              ),
                  ),
                  const SizedBox(height: 30),
                  // File Name Area
                  Container(
                    height: 70,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _fileName ?? 'No file selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Control Area
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[700]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _filePath != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isVideo
                                      ? (_videoPlayerController.value.isPlaying ? Icons.pause : Icons.play_arrow)
                                      : (_audioPlayer.state == PlayerState.playing ? Icons.pause : Icons.play_arrow),
                                  color: gold,
                                  size: 40,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_isVideo) {
                                            if (_videoPlayerController.value.isPlaying) {
                                              _videoPlayerController.pause();
                                            } else {
                                              _videoPlayerController.play();
                                            }
                                          } else {
                                            if (_audioPlayer.state == PlayerState.playing) {
                                              _audioPlayer.pause();
                                            } else {
                                              _audioPlayer.play(DeviceFileSource(_filePath!));
                                            }
                                          }
                                        });
                                      },
                              ),
                              if (!_isVideo)
                                Expanded(
                                  child: Slider(
                                    value: _audioPosition.inSeconds.toDouble(),
                                    min: 0.0,
                                    activeColor: gold,
                                    inactiveColor: Colors.grey[600],
                                    onChanged: (value) {
                                      _seekAudio(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                            ],
                          )
                        : const Center(
                            child: Text(
                              'Select a file to control',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          ),
                  ),
                  const SizedBox(height: 30),
                  // Volume Control Area
                  Container(
                    height: 90,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: gold,
                      inactiveColor: Colors.grey[600],
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _volume = value;
                                if (_isVideo && _videoPlayerController.value.isInitialized) {
                                  _videoPlayerController.setVolume(_volume);
                                } else {
                                  _audioPlayer.setVolume(_volume);
                                }
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gold, Colors.deepPurple[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.6),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _loadFile,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.folder_open, color: Colors.white, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}