import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/app/theme.dart';
import 'package:pocket_hangar/core/images/eve_image.dart';
import 'package:pocket_hangar/core/sde/sde_models.dart';

/// A 1 x 1 PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

void main() {
  late Directory root;
  late int downloads;
  late ImageDiskCache cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ph_images');
    downloads = 0;
    cache = ImageDiskCache(
      root: root,
      download: (url) async {
        downloads++;
        return _png;
      },
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('a download completes, is shared while running, and is read from disk later', () async {
    const url = 'https://images.evetech.net/types/587/icon?size=64';
    final first = cache.bytes(url);
    expect(identical(cache.bytes(url), first), isTrue);
    // Used to hang: the cleanup callback returned the pending future to whenComplete.
    expect(await first.timeout(const Duration(seconds: 5)), _png);
    expect(await cache.bytes(url).timeout(const Duration(seconds: 5)), _png);
    expect(downloads, 1);
    expect(root.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.img')), hasLength(1));
  });

  testWidgets('blueprints ask for the bp image, SKINs ask for nothing', (tester) async {
    final requested = <String>[];
    final previous = ImageDiskCache.instance;
    ImageDiskCache.instance = ImageDiskCache(
      root: root,
      download: (url) async {
        requested.add(url);
        return _png;
      },
    );
    addTearDown(() => ImageDiskCache.instance = previous);

    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        theme: buildDarkTheme(),
        home: Column(children: [
          EveImage.type(691, categoryId: Categories.blueprint),
          EveImage.type(34599, categoryId: Categories.skin),
        ]),
      ));
      final image = tester.widget<Image>(find.byType(Image));
      await precacheImage(image.image, tester.element(find.byType(Image))).timeout(const Duration(seconds: 5));
    });
    expect(requested, [contains('/types/691/bp?')]);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
  });

  testWidgets('EveImage shows the image once it is loaded', (tester) async {
    final previous = ImageDiskCache.instance;
    ImageDiskCache.instance = cache;
    addTearDown(() => ImageDiskCache.instance = previous);

    // File access and decoding are real async work, so the image has to start loading outside
    // the test's fake clock.
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(theme: buildDarkTheme(), home: Center(child: EveImage.type(587))));
      final image = tester.widget<Image>(find.byType(Image));
      await precacheImage(image.image, tester.element(find.byType(Image))).timeout(const Duration(seconds: 5));
    });
    await tester.pump();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });
}
