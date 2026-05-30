enum DocumentType { aadhaar, pan, passbook, voterId, drivingLicense }

extension DocumentTypeX on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.aadhaar: return 'आधार कार्ड';
      case DocumentType.pan: return 'पैन कार्ड';
      case DocumentType.passbook: return 'बैंक पासबुक';
      case DocumentType.voterId: return 'वोटर आईडी';
      case DocumentType.drivingLicense: return 'ड्राइविंग लाइसेंस';
    }
  }
  String get placeAudioKey {
    switch (this) {
      case DocumentType.aadhaar: return 'place_aadhaar';
      case DocumentType.pan: return 'place_pan';
      case DocumentType.passbook: return 'place_passbook';
      default: return 'place_aadhaar';
    }
  }
  String get notFoundAudioKey {
    switch (this) {
      case DocumentType.aadhaar: return 'not_aadhaar';
      case DocumentType.pan: return 'not_pan';
      case DocumentType.passbook: return 'not_passbook';
      case DocumentType.voterId: return 'not_voter';
      case DocumentType.drivingLicense: return 'not_license';
    }
  }
  List<String> get keywords {
    switch (this) {
      case DocumentType.aadhaar: return ['uidai','unique identification','आधार','aadhaar','vid','govt of india'];
      case DocumentType.pan: return ['income tax','permanent account','income tax department','pan'];
      case DocumentType.passbook: return ['bank','बैंक','account no','branch','ifsc','savings'];
      case DocumentType.voterId: return ['election commission','निर्वाचन आयोग','epic','elector'];
      case DocumentType.drivingLicense: return ['driving licence','driving license','transport','ड्राइविंग','dl no'];
    }
  }
}