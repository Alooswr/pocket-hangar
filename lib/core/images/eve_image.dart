import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../sde/sde_models.dart';

/// Images from images.evetech.net, downloaded on first use and kept in the app cache directory.
/// Nothing is bundled with the app.
class ImageDiskCache {
  /// [root] and [download] replace the app cache directory and the HTTP request in tests.
  ImageDiskCache({this._root, this._download});

  /// The cache the image widgets read from. Tests replace it.
  static ImageDiskCache instance = ImageDiskCache();

  final Directory? _root;
  final Future<List<int>?> Function(String url)? _download;
  late final _dio = Dio(BaseOptions(
    responseType: ResponseType.bytes,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'User-Agent': AppConfig.userAgent},
  ));
  final _inflight = <String, Future<Uint8List>>{};
  Directory? _dir;

  Future<Directory> _directory() async {
    final existing = _dir;
    if (existing != null) return existing;
    final dir = Directory(p.join((_root ?? await getApplicationCacheDirectory()).path, 'eve_images'));
    await dir.create(recursive: true);
    return _dir = dir;
  }

  Future<List<int>?> _fetch(String url) async =>
      _download != null ? _download(url) : (await _dio.get<List<int>>(url)).data;

  /// One download per URL at a time. The cleanup callback must not return the removed future:
  /// whenComplete waits for a returned future, and this one is the future itself, so an arrow
  /// function here never completes (images stayed placeholders that way).
  Future<Uint8List> bytes(String url) => _inflight[url] ??= _load(url).whenComplete(() {
        _inflight.remove(url);
      });

  Future<Uint8List> _load(String url) async {
    final name = sha1.convert(url.codeUnits).toString();
    final file = File(p.join((await _directory()).path, '$name.img'));
    if (await file.exists()) return file.readAsBytes();
    final data = Uint8List.fromList(await _fetch(url) ?? const []);
    if (data.isEmpty) throw StateError('empty image $url');
    final tmp = File('${file.path}.part');
    await tmp.writeAsBytes(data, flush: true);
    await tmp.rename(file.path);
    return data;
  }
}

@immutable
class CachedEveImage extends ImageProvider<CachedEveImage> {
  const CachedEveImage(this.url);

  final String url;

  @override
  Future<CachedEveImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(CachedEveImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _codec(decode), scale: 1, debugLabel: url);

  Future<ui.Codec> _codec(ImageDecoderCallback decode) async {
    final data = await ImageDiskCache.instance.bytes(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(data));
  }

  @override
  bool operator ==(Object other) => other is CachedEveImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// Picks the image server size (a power of two from 32 to 1024) for a logical size.
int imageServerSize(double logicalSize, double devicePixelRatio) {
  final px = logicalSize * devicePixelRatio;
  var size = 32;
  while (size < px && size < 1024) {
    size *= 2;
  }
  return size;
}

class EveImage extends StatelessWidget {
  const EveImage._(this._path, {required this.size, this.circle = false, this.icon, super.key});

  /// The image server has an `icon` for most types, only `bp` and `bpc` for blueprints, and
  /// nothing for SKINs (404), so [categoryId] picks the variant. SKINs get a local icon and no
  /// request. [variant] overrides the choice, e.g. `render` for a ship.
  factory EveImage.type(int typeId, {int? categoryId, String? variant, double size = 32, Key? key}) =>
      categoryId == Categories.skin && variant == null
          ? EveImage._(null, size: size, icon: Icons.palette_outlined, key: key)
          : EveImage._(
              'types/$typeId/${variant ?? (categoryId == Categories.blueprint ? 'bp' : 'icon')}',
              size: size,
              key: key,
            );

  factory EveImage.character(int characterId, {double size = 32, Key? key}) =>
      EveImage._('characters/$characterId/portrait', size: size, circle: true, key: key);

  /// Path on the image server, or null when there is no image and [icon] is shown instead.
  final String? _path;
  final double size;
  final bool circle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final px = imageServerSize(size, MediaQuery.devicePixelRatioOf(context));
    final t = context.tokens;
    final placeholder = Container(width: size, height: size, color: t.surface2);
    Widget iconBox(IconData data) => Container(
          width: size,
          height: size,
          color: t.surface2,
          alignment: Alignment.center,
          child: Icon(data, size: size * 0.5, color: t.textMuted),
        );
    final path = _path;
    final image = path == null
        ? iconBox(icon ?? Icons.image_not_supported_outlined)
        : Image(
            image: CachedEveImage('${AppConfig.imageBaseUrl}/$path?size=$px'),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sync) => sync || frame != null ? child : placeholder,
            errorBuilder: (context, error, stack) => iconBox(Icons.image_not_supported_outlined),
          );
    return circle
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: BorderRadius.circular(size >= 48 ? Radii.md : Radii.sm), child: image);
  }
}
