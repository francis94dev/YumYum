import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/api_constants.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    String finalUrl = imageUrl;
    if (imageUrl.startsWith('/uploads')) {
      finalUrl = '${ApiConstants.baseUrl}$imageUrl';
    }

    final bool isHttp = finalUrl.startsWith('http');
    final bool isBlob = finalUrl.startsWith('blob:');

    if (kIsWeb) {
      if (isHttp || isBlob) {
        return Image.network(
          finalUrl,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _ErrorWidget(),
        );
      }
      return _ErrorWidget();
    }

    if (!isHttp) {
      return Image.file(
        File(finalUrl),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _ErrorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => _ErrorWidget(),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
