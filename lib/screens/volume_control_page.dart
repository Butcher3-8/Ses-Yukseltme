import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class VolumeControlPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final Function(String) onProcessComplete;

  const VolumeControlPage({
    Key? key,
    required this.filePath,
    required this.fileName,
    required this.onProcessComplete,
  }) : super(key: key);

  @override
  _VolumeControlPageState createState() => _VolumeControlPageState();
}

class _VolumeControlPageState extends State<VolumeControlPage> {
  static const Color gold = Color(0xFFFFD700);
  double _volumeMultiplier = 1.0; // 1.0 = %100, 2.0 = %200 vs.
  bool _isProcessing = false;
  String _processingStatus = '';

  // Ses seviyesi presetleri
  final Map<String, double> _volumePresets = {
    'Çok Düşük': 0.25,
    'Düşük': 0.5,
    'Normal': 1.0,
    'Yüksek': 1.5,
    'Çok Yüksek': 2.0,
    'Maksimum': 3.0,
  };

Future<void> _processAudioVolume() async {
  if (_isProcessing) return;

  setState(() {
    _isProcessing = true;
    _processingStatus = 'İşlem başlatılıyor...';
  });

  try {
    // Geçici klasör alma
    final Directory tempDir = await getTemporaryDirectory();
    final String fileExtension = path.extension(widget.filePath).toLowerCase();
    final String baseName = path.basenameWithoutExtension(widget.fileName);
    // Özel karakterleri temizleme
    final String sanitizedBaseName = baseName.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final String outputFileName = '${sanitizedBaseName}_volume_${(_volumeMultiplier * 100).round()}$fileExtension';
    final String outputPath = path.join(tempDir.path, outputFileName);

    setState(() {
      _processingStatus = 'Ses seviyesi ayarlanıyor...';
    });

    // FFmpeg komutunu hazırlama
    String ffmpegCommand;
    if (['.mp4', '.mov'].contains(fileExtension)) {
      // Video dosyaları için
      ffmpegCommand =
          '-i "${path.normalize(widget.filePath)}" -af "volume=${_volumeMultiplier}" -c:v copy -c:a aac -y "${path.normalize(outputPath)}"';
    } else if (['.mp3', '.wav', '.m4a'].contains(fileExtension)) {
      // Ses dosyaları için
      ffmpegCommand =
          '-i "${path.normalize(widget.filePath)}" -af "volume=${_volumeMultiplier}" -c:a aac -y "${path.normalize(outputPath)}"';
    } else {
      throw Exception('Desteklenmeyen dosya formatı: $fileExtension');
    }

    print('FFmpeg Command: $ffmpegCommand');

    // FFmpeg işlemini çalıştırma
    final session = await FFmpegKit.executeAsync(
      ffmpegCommand,
      (session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          setState(() {
            _processingStatus = 'İşlem tamamlandı!';
          });

          // Başarılı işlem sonrası callback
          widget.onProcessComplete(outputPath);

          // 2 saniye sonra sayfayı kapat
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          final logs = await session.getAllLogsAsString();
          print('FFmpeg Error Logs: $logs');
          setState(() {
            _processingStatus = 'İşlem başarısız oldu! Hata: $logs';
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İşlem başarısız: $logs')),
          );
        }
      },
      (log) {
        // İşlem durumunu güncelle
        final logMessage = log.getMessage();
        print('FFmpeg Log: $logMessage');
        if (logMessage.contains('time=')) {
          setState(() {
            _processingStatus =
                'İşleniyor... ${logMessage.split('time=')[1].split(' ')[0]}';
          });
        }
      },
      (statistics) {
        print('FFmpeg Statistics: ${statistics.toString()}');
      },
    );

    // İşlem tamamlanana kadar bekle
    await session.getReturnCode();
  } catch (e) {
    print('Error processing audio: $e');
    setState(() {
      _processingStatus = 'Hata: $e';
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hata: $e')),
    );
  }
}

  Color _getVolumeColor() {
    if (_volumeMultiplier <= 0.5) {
      return Colors.blue;
    } else if (_volumeMultiplier <= 1.0) {
      return gold;
    } else if (_volumeMultiplier <= 2.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getVolumeIcon() {
    if (_volumeMultiplier == 0) {
      return Icons.volume_off;
    } else if (_volumeMultiplier <= 0.5) {
      return Icons.volume_down;
    } else if (_volumeMultiplier <= 1.5) {
      return Icons.volume_up;
    } else {
      return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ses Seviyesi Ayarla',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Dosya bilgisi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: gold.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.audio_file,
                      color: gold,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // Ses seviyesi göstergesi
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _getVolumeColor().withOpacity(0.5), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getVolumeIcon(),
                          color: _getVolumeColor(),
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ses Seviyesi',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${(_volumeMultiplier * 100).round()}%',
                              style: TextStyle(
                                color: _getVolumeColor(),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    // Ses kontrol slider'ı
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _getVolumeColor(),
                        inactiveTrackColor: Colors.grey[600],
                        thumbColor: _getVolumeColor(),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        overlayColor: _getVolumeColor().withOpacity(0.3),
                        trackHeight: 8,
                      ),
                      child: Slider(
                        value: _volumeMultiplier,
                        min: 0.0,
                        max: 3.0,
                        divisions: 30,
                        onChanged: _isProcessing
                            ? null
                            : (value) {
                                setState(() {
                                  _volumeMultiplier = value;
                                });
                              },
                      ),
                    ),

                    // Uyarı mesajları
                    if (_volumeMultiplier > 2.0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'DİKKAT: Çok yüksek ses seviyesi işitme hasarına neden olabilir!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_volumeMultiplier > 1.5) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Yüksek ses seviyesi - Dikkatli kullanın',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Preset butonları
              if (!_isProcessing) ...[
                Text(
                  'Hızlı Seçim',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _volumePresets.entries.map((preset) {
                    final isSelected = (_volumeMultiplier - preset.value).abs() < 0.01;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _volumeMultiplier = preset.value;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? gold.withOpacity(0.2) : Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? gold : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${preset.key} (${(preset.value * 100).round()}%)',
                          style: TextStyle(
                            color: isSelected ? gold : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const Spacer(),

              // İşlem durumu
              if (_isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(gold),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _processingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // İşle butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processAudioVolume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isProcessing ? Colors.grey[600] : gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: _isProcessing ? 0 : 8,
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'İşleniyor...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Ses Seviyesini Uygula',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}