import 'package:flutter/material.dart';

enum GuideState { scanning, ready, error, confirming }

class DocOverlayPainter extends CustomPainter {
  final GuideState state;
  DocOverlayPainter(this.state);
  Color get _color {
    switch (state) {
      case GuideState.ready: return const Color(0xFF00C853);
      case GuideState.error: return const Color(0xFFFF3D00);
      case GuideState.confirming: return const Color(0xFFFFD600);
      case GuideState.scanning: return const Color(0x80FFFFFF);
    }
  }
  @override
  void paint(Canvas canvas, Size size) {
    final guide = Rect.fromLTWH(size.width*0.08, size.height*0.28, size.width*0.84, size.height*0.40);
    canvas.drawPath(Path()..addRect(Offset.zero & size)..addRRect(RRect.fromRectAndRadius(guide, const Radius.circular(16)))..fillType = PathFillType.evenOdd, Paint()..color = const Color(0x99000000));
    canvas.drawRRect(RRect.fromRectAndRadius(guide, const Radius.circular(16)), Paint()..color = _color..style = PaintingStyle.stroke..strokeWidth = state == GuideState.scanning ? 2 : 4);
    final c = Paint()..color = _color..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const l = 28.0;
    void corner(Offset o, Offset a, Offset b) { canvas.drawLine(o,a,c); canvas.drawLine(o,b,c); }
    corner(guide.topLeft, guide.topLeft+const Offset(l,0), guide.topLeft+const Offset(0,l));
    corner(guide.topRight, guide.topRight+const Offset(-l,0), guide.topRight+const Offset(0,l));
    corner(guide.bottomLeft, guide.bottomLeft+const Offset(l,0), guide.bottomLeft+const Offset(0,-l));
    corner(guide.bottomRight, guide.bottomRight+const Offset(-l,0), guide.bottomRight+const Offset(0,-l));
  }
  @override bool shouldRepaint(covariant DocOverlayPainter old) => old.state != state;
}

class FaceOverlayPainter extends CustomPainter {
  final GuideState state; final double ringProgress;
  FaceOverlayPainter(this.state, this.ringProgress);
  @override
  void paint(Canvas canvas, Size size) {
    final cx=size.width/2, cy=size.height*0.42;
    final oval = Rect.fromCenter(center: Offset(cx,cy), width: size.width*0.68, height: size.height*0.48);
    canvas.drawPath(Path()..addRect(Offset.zero & size)..addOval(oval)..fillType = PathFillType.evenOdd, Paint()..color = const Color(0x99000000));
    Color c; switch(state){case GuideState.ready: c=const Color(0xFF00C853);break;case GuideState.error: c=const Color(0xFFFF3D00);break;case GuideState.confirming: c=const Color(0xFFFFD600);break;default: c=const Color(0x80FFFFFF);}
    canvas.drawOval(oval, Paint()..color=c..style=PaintingStyle.stroke..strokeWidth=4);
    if(ringProgress>0) canvas.drawArc(oval.inflate(10),-1.5708,6.2832*ringProgress,false,Paint()..color=const Color(0xFF00C853)..style=PaintingStyle.stroke..strokeWidth=6..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(covariant FaceOverlayPainter old) => old.state != state || old.ringProgress != ringProgress;
}