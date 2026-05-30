import 'dart:io';
import 'package:flutter/material.dart';

class DocumentReviewScreen extends StatelessWidget {
  final String imagePath; final String docName; final String? extractedNumber;
  const DocumentReviewScreen({super.key, required this.imagePath, required this.docName, this.extractedNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: Colors.black, title: Text(docName, style: const TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: Column(children: [
        Expanded(child: Stack(alignment: Alignment.topRight, children: [
          Padding(padding: const EdgeInsets.all(16), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(imagePath), fit: BoxFit.contain, width: double.infinity))),
          const Padding(padding: EdgeInsets.all(24), child: CircleAvatar(backgroundColor: Color(0xFF00C853), radius: 22, child: Icon(Icons.check, color: Colors.white, size: 26))),
        ])),
        if (extractedNumber != null && extractedNumber!.isNotEmpty)
          Container(margin: const EdgeInsets.symmetric(horizontal:16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE53935))), child: Row(children: [const Icon(Icons.tag, color: Color(0xFFE53935)), const SizedBox(width:12), const Text('नंबर:  ', style: TextStyle(color: Colors.white70, fontSize:16)), Expanded(child: Text(extractedNumber!, style: const TextStyle(color: Colors.white, fontSize:18, fontWeight: FontWeight.w600, letterSpacing:1.5)))])),
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pop(context, null), icon: const Icon(Icons.refresh, color: Colors.white), label: const Text('दोबारा', style: TextStyle(color: Colors.white)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical:16), side: const BorderSide(color: Colors.white54)))),
          const SizedBox(width:12),
          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(vertical:16)), onPressed: () => Navigator.pop(context, {'path': imagePath, 'number': extractedNumber??''}), icon: const Icon(Icons.check), label: const Text('पुष्टि करें'))),
        ])),
      ])),
    );
  }
}