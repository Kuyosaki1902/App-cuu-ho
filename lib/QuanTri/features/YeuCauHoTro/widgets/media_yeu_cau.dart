import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../models/ban_ghi.dart';
import '../../../models/du_lieu_anh.dart';
import '../../TaiKhoan/models/tai_khoan_model.dart';
import '../services/chi_tiet_yeu_cau_service.dart';

const _mediaBlue = Color(0xFF1767B2);
const _mediaInk = Color(0xFF172B4D);
const _mediaMuted = Color(0xFF64748B);

String mediaSource(Map<String, dynamic> data) {
  for (final key in [
    'anhURL',
    'fileURL',
    'fileUrl',
    'tepTinUrl',
    'taiLieuUrl',
    'duongDanTep',
    'attachmentUrl',
    'urlFile',
    'duongDan',
    'videoUrl',
    'ghiAmUrl',
    'anhBase64',
    'base64Image',
    'base64',
  ]) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String mediaExtension(String source) {
  final value = source.trim();
  final dataMime = RegExp(
    r'^data:([^;,]+)',
    caseSensitive: false,
  ).firstMatch(value)?.group(1);
  if (dataMime != null) {
    final parts = dataMime.toLowerCase().split('/');
    return parts.length == 2 ? parts.last : '';
  }
  final uri = Uri.tryParse(value);
  var path = uri?.path ?? value.split('?').first;
  try {
    path = Uri.decodeComponent(path);
  } catch (_) {}
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

enum _MediaKind { image, audio, video, file, unknown }

_MediaKind _mediaKind(String source, {bool assumeImage = false}) {
  final value = source.trim().toLowerCase();
  if (value.startsWith('data:image/')) return _MediaKind.image;
  if (value.startsWith('data:audio/')) return _MediaKind.audio;
  if (value.startsWith('data:video/')) return _MediaKind.video;
  final ext = mediaExtension(source);
  if (const {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  }.contains(ext)) {
    return _MediaKind.image;
  }
  if (const {
    'm4a',
    'mp3',
    'wav',
    'aac',
    'ogg',
    'opus',
    'amr',
    'flac',
  }.contains(ext)) {
    return _MediaKind.audio;
  }
  if (const {
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
    '3gp',
    'm3u8',
  }.contains(ext)) {
    return _MediaKind.video;
  }
  if (const {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'zip',
    'rar',
    '7z',
  }.contains(ext)) {
    return _MediaKind.file;
  }
  if (assumeImage || value.startsWith('data:image/')) return _MediaKind.image;
  return _MediaKind.unknown;
}

String mediaFileName(String source, Map<String, dynamic> data) {
  for (final key in ['tenTep', 'tenFile', 'fileName', 'filename', 'name']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  final uri = Uri.tryParse(source);
  var path = uri?.path ?? source.split('?').first;
  try {
    path = Uri.decodeComponent(path);
  } catch (_) {}
  final name = path.split('/').last;
  return name.isEmpty ? 'Tệp đính kèm' : name;
}

class MediaAttachmentTile extends StatelessWidget {
  final BanGhi record;
  const MediaAttachmentTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final source = mediaSource(record.data);
    if (source.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.attach_file),
        title: Text('Tệp đính kèm không có đường dẫn.'),
      );
    }
    final mime = (record.data['contentType'] ?? record.data['mimeType'] ?? '')
        .toString()
        .toLowerCase();
    final kind = mime.startsWith('video/')
        ? _MediaKind.video
        : mime.startsWith('audio/')
        ? _MediaKind.audio
        : mime.startsWith('image/')
        ? _MediaKind.image
        : mime.startsWith('application/') || mime.startsWith('text/')
        ? _MediaKind.file
        : _mediaKind(source, assumeImage: true);
    switch (kind) {
      case _MediaKind.image:
        return _InlineImage(
          source: source,
          title: mediaFileName(source, record.data),
        );
      case _MediaKind.audio:
        return AudioAttachmentPlayer(
          url: source,
          title: mediaFileName(source, record.data),
        );
      case _MediaKind.video:
        return VideoAttachmentPlayer(
          url: source,
          title: mediaFileName(source, record.data),
        );
      case _MediaKind.file:
      case _MediaKind.unknown:
        return FileAttachmentTile(
          url: source,
          name: mediaFileName(source, record.data),
          contentType:
              record.data['contentType']?.toString() ??
              record.data['mimeType']?.toString(),
        );
    }
  }
}

class MediaUrlPreview extends StatelessWidget {
  final String url;
  final String title;
  final String? contentType;
  const MediaUrlPreview({
    super.key,
    required this.url,
    required this.title,
    this.contentType,
  });

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const SizedBox.shrink();
    final mime = (contentType ?? '').toLowerCase();
    final kind = mime.startsWith('video/')
        ? _MediaKind.video
        : mime.startsWith('audio/')
        ? _MediaKind.audio
        : mime.startsWith('image/')
        ? _MediaKind.image
        : mime.startsWith('application/') || mime.startsWith('text/')
        ? _MediaKind.file
        : _mediaKind(url);
    switch (kind) {
      case _MediaKind.image:
        return const SizedBox.shrink();
      case _MediaKind.audio:
        return AudioAttachmentPlayer(url: url, title: title);
      case _MediaKind.video:
        return VideoAttachmentPlayer(url: url, title: title);
      case _MediaKind.file:
      case _MediaKind.unknown:
        return FileAttachmentTile(url: url, name: title);
    }
  }
}

class _InlineImage extends StatefulWidget {
  final String source;
  final String title;
  const _InlineImage({required this.source, required this.title});

  @override
  State<_InlineImage> createState() => _InlineImageState();
}

class _InlineImageState extends State<_InlineImage> {
  late Future<DuLieuAnh> _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _InlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _load();
  }

  void _load() {
    _image = compute(decodeDocumentImage, widget.source);
  }

  void _open(DuLieuAnh data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImageViewer(image: data, title: widget.title),
      ),
    );
  }

  Widget _failure(String message) => Container(
    height: 170,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 30, color: _mediaMuted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mediaMuted),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<DuLieuAnh>(
    future: _image,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Container(
          height: 190,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const CircularProgressIndicator(),
        );
      }
      if (snapshot.hasError || snapshot.data == null) {
        return _failure('Không tải được hình ảnh hiện trường.');
      }
      final data = snapshot.data!;
      final image = data.bytes != null
          ? Image.memory(
              data.bytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 210,
            )
          : Image.network(
              data.url!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 210,
              errorBuilder: (_, _, _) =>
                  _failure('Không tải được hình ảnh hiện trường.'),
            );
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(data),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    image,
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, size: 16, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Phóng to',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 17,
                        color: _mediaBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title.isEmpty
                              ? 'Ảnh hiện trường'
                              : widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _mediaInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: _mediaMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ImageViewer extends StatelessWidget {
  final DuLieuAnh image;
  final String title;
  const _ImageViewer({required this.image, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(title.isEmpty ? 'Ảnh hiện trường' : title),
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 6,
        boundaryMargin: const EdgeInsets.all(80),
        child: image.bytes != null
            ? Image.memory(image.bytes!, fit: BoxFit.contain)
            : Image.network(
                image.url!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 54,
                ),
              ),
      ),
    ),
  );
}

class AudioAttachmentPlayer extends StatefulWidget {
  final String url;
  final String title;
  const AudioAttachmentPlayer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AudioAttachmentPlayer> createState() => _AudioAttachmentPlayerState();
}

class _AudioAttachmentPlayerState extends State<AudioAttachmentPlayer> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  bool _started = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _durationSub = _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duration = value);
    });
    _positionSub = _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _stateSub = _player.onPlayerStateChanged.listen((value) {
      if (mounted) setState(() => _state = value);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _state = PlayerState.completed;
          _started = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AudioAttachmentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _player.stop();
      _started = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _error = null;
    }
  }

  Future<void> _toggle() async {
    try {
      if (_state == PlayerState.playing) {
        await _player.pause();
      } else if (_started && _state == PlayerState.paused) {
        await _player.resume();
      } else {
        final uri = Uri.tryParse(widget.url);
        if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
          throw const FormatException('Đường dẫn ghi âm không hợp lệ.');
        }
        await _player.play(UrlSource(widget.url));
        _started = true;
      }
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không phát được tệp ghi âm.');
    }
  }

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final current = _position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    final playing = _state == PlayerState.playing;
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEBFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_none_rounded, color: _mediaBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title.isEmpty ? 'Ghi âm tình trạng' : widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _mediaInk,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: _toggle,
                tooltip: playing ? 'Tạm dừng' : 'Phát ghi âm',
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
          Slider(
            value: current,
            max: max,
            onChanged: _duration == Duration.zero
                ? null
                : (value) =>
                      _player.seek(Duration(milliseconds: value.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _time(_position),
                style: const TextStyle(fontSize: 11, color: _mediaMuted),
              ),
              Text(
                _time(_duration),
                style: const TextStyle(fontSize: 11, color: _mediaMuted),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoAttachmentPlayer extends StatefulWidget {
  final String url;
  final String title;
  const VideoAttachmentPlayer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<VideoAttachmentPlayer> createState() => _VideoAttachmentPlayerState();
}

class _VideoAttachmentPlayerState extends State<VideoAttachmentPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant VideoAttachmentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _createController();
    }
  }

  void _createController() {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      _error = 'Đường dẫn video không hợp lệ.';
      _initializing = Future<void>.value();
      return;
    }
    _error = null;
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    _initializing = controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((_) {
          if (mounted) setState(() => _error = 'Không tải được video.');
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10, bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam_outlined, color: _mediaBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title.isEmpty ? 'Video hiện trường' : widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _mediaInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<void>(
          future: _initializing,
          builder: (context, snapshot) {
            final controller = _controller;
            if (_error != null) {
              return _videoMessage(_error!);
            }
            if (snapshot.connectionState != ConnectionState.done ||
                controller == null ||
                !controller.value.isInitialized) {
              return _videoMessage('Đang tải video…', loading: true);
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio > 0
                    ? controller.value.aspectRatio
                    : 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(controller),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => IconButton.filledTonal(
                        onPressed: () => value.isPlaying
                            ? controller.pause()
                            : controller.play(),
                        iconSize: 34,
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: _mediaBlue,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _videoMessage(String text, {bool loading = false}) => Container(
    height: 170,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFE8EEF5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: loading
        ? const CircularProgressIndicator()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_file_outlined,
                size: 34,
                color: _mediaMuted,
              ),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: _mediaMuted)),
            ],
          ),
  );
}

class FileAttachmentTile extends StatelessWidget {
  final String url;
  final String name;
  final String? contentType;
  const FileAttachmentTile({
    super.key,
    required this.url,
    required this.name,
    this.contentType,
  });

  IconData get _icon {
    final ext = mediaExtension(url);
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (const {'doc', 'docx'}.contains(ext)) return Icons.description_outlined;
    if (const {'xls', 'xlsx', 'csv'}.contains(ext))
      return Icons.table_chart_outlined;
    if (const {'zip', 'rar', '7z'}.contains(ext))
      return Icons.folder_zip_outlined;
    return Icons.attach_file_rounded;
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao chép đường dẫn tệp.')),
        );
      }
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được tệp đính kèm.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FB),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(_icon, color: _mediaBlue),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      subtitle: Text(
        contentType ?? mediaExtension(url).toUpperCase(),
        style: const TextStyle(color: _mediaMuted, fontSize: 11),
      ),
      trailing: const Icon(Icons.open_in_new, color: _mediaBlue),
      onTap: () => _open(context),
    ),
  );
}

class DanhGiaYeuCauTile extends StatelessWidget {
  final BanGhi review;
  final NguonChiTietYeuCau repository;
  const DanhGiaYeuCauTile({
    super.key,
    required this.review,
    required this.repository,
  });

  Widget _person(String uid, String label) {
    if (uid.trim().isEmpty) {
      return Text(
        '$label: Chưa có thông tin',
        style: const TextStyle(fontSize: 12, color: _mediaMuted),
      );
    }
    return StreamBuilder<BanGhi?>(
      stream: repository.watchPerson(uid),
      builder: (context, snapshot) {
        final name = snapshot.data?.text('hoTen', '') ?? '';
        return Text(
          '$label: ${name.isEmpty ? uid : name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: _mediaMuted),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreRaw = review.data['diemDanhGia'];
    final score = scoreRaw is num
        ? scoreRaw.toInt()
        : int.tryParse('$scoreRaw') ?? 0;
    final reviewer = review.text('maNguoiDanhGia', '');
    final helper = review.text('maNguoiCuuHo', review.id);
    final comment = review.text('nhanXet', '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < score
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF4A62A),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$score/5',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _mediaInk,
                ),
              ),
              const Spacer(),
              Text(
                dateText(review.data['ngayTao']),
                style: const TextStyle(fontSize: 11, color: _mediaMuted),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: _mediaInk,
              ),
            ),
          ],
          const Divider(height: 20),
          _person(reviewer, 'Người đánh giá'),
          const SizedBox(height: 4),
          _person(helper, 'Người được đánh giá'),
        ],
      ),
    );
  }
}
