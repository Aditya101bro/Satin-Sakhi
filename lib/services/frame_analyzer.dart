import 'dart:typed_data';

class FramePayload {
  final Uint8List yPlane;
  final int width, height, rowStride;
  FramePayload(this.yPlane, this.width, this.height, this.rowStride);
}

class FrameStats {
  final double blurVariance, brightness, glareRatio, coverage, tiltDegrees;
  const FrameStats(this.blurVariance, this.brightness, this.glareRatio, this.coverage, this.tiltDegrees);
}

FrameStats analyzeFrame(FramePayload p) {
  final w = p.width, h = p.height, stride = p.rowStride;
  final y = p.yPlane;
  const step = 2;
  int count = 0, glare = 0;
  double sum = 0;
  for (int row = 0; row < h; row += step) {
    final base = row * stride;
    for (int col = 0; col < w; col += step) {
      final v = y[base + col];
      sum += v; if (v > 240) glare++; count++;
    }
  }
  final brightness = count == 0 ? 0.0 : sum / count;
  final glareRatio = count == 0 ? 0.0 : glare / count;

  double lapSum = 0, lapSqSum = 0; int lapN = 0;
  for (int row = step; row < h - step; row += step) {
    final base = row * stride, up = (row-step)*stride, down = (row+step)*stride;
    for (int col = step; col < w - step; col += step) {
      final c = y[base+col];
      final lap = (4*c) - y[base+col-step] - y[base+col+step] - y[up+col] - y[down+col];
      lapSum += lap; lapSqSum += lap*lap; lapN++;
    }
  }
  double blurVar = 0;
  if (lapN > 0) { final m = lapSum/lapN; blurVar = (lapSqSum/lapN)-(m*m); }

  int minX = w, maxX = 0, minY = h, maxY = 0, edgePts = 0;
  const edgeThresh = 35;
  for (int row = step; row < h-step; row += step) {
    final base = row * stride;
    for (int col = step; col < w-step; col += step) {
      final gx = (y[base+col+step]-y[base+col-step]).abs();
      final gy = (y[(row+step)*stride+col]-y[(row-step)*stride+col]).abs();
      if (gx+gy > edgeThresh) {
        edgePts++;
        if (col < minX) minX=col; if (col > maxX) maxX=col;
        if (row < minY) minY=row; if (row > maxY) maxY=row;
      }
    }
  }
  double coverage = 0, tilt = 0;
  if (edgePts > 50 && maxX > minX && maxY > minY) {
    coverage = ((maxX-minX)*(maxY-minY))/(w*h);
    tilt = _estimateTilt(y, w, h, stride, minX, maxX, minY, maxY, step);
  }
  return FrameStats(blurVar, brightness, glareRatio, coverage, tilt);
}

double _estimateTilt(Uint8List y, int w, int h, int stride, int minX, int maxX, int minY, int maxY, int step) {
  double topC=0, botC=0; int topN=0, botN=0;
  final topBand = minY+(maxY-minY)~/6, botBand = maxY-(maxY-minY)~/6;
  for (int col = minX; col < maxX; col += step) {
    final gTop = (y[(topBand+step)*stride+col]-y[(topBand-step)*stride+col]).abs();
    if (gTop > 40) { topC+=col; topN++; }
    final gBot = (y[(botBand+step)*stride+col]-y[(botBand-step)*stride+col]).abs();
    if (gBot > 40) { botC+=col; botN++; }
  }
  if (topN==0||botN==0) return 0;
  final dx=(botC/botN)-(topC/topN), dy=(botBand-topBand).toDouble();
  if (dy==0) return 0;
  return (dx/dy).abs()*57.2958;
}