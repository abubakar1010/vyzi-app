class BillFileModel {
  final String id;
  final String billId;
  final String fileUrl;
  final String? originalName;
  final String? mimeType;
  final int? fileSize;
  final String createdAt;

  const BillFileModel({
    required this.id,
    required this.billId,
    required this.fileUrl,
    this.originalName,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
  });

  factory BillFileModel.fromJson(Map<String, dynamic> json) {
    return BillFileModel(
      id: json['id']?.toString() ?? '',
      billId: json['billId']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      originalName: json['originalName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : int.tryParse(json['fileSize']?.toString() ?? ''),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  String get displayName =>
      originalName ?? fileUrl.split('/').last;

  String get displaySize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(0)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      mimeType?.startsWith('image/') == true;
}

/// A request from an admin asking the customer to send something in.
///
/// The admin only writes a message — there are no per-field requests. Every new
/// request is a `bill` one, answered by uploading the bill document on the
/// verification screen. `contract` requests date from when contracts were
/// signed inside the app; the customer can no longer answer one, so
/// [isContract] exists to recognise and skip them.
class BillVerificationModel {
  final String id;
  final String billId;
  final String adminMessage;
  final String type; // bill, contract
  final String status; // pending, submitted, resolved
  final String? userMessage;
  final List<BillFileModel> files;
  final String? resolvedAt;
  final String createdAt;

  const BillVerificationModel({
    required this.id,
    required this.billId,
    required this.adminMessage,
    this.type = 'bill',
    required this.status,
    this.userMessage,
    this.files = const [],
    this.resolvedAt,
    required this.createdAt,
  });

  factory BillVerificationModel.fromJson(Map<String, dynamic> json) {
    return BillVerificationModel(
      id: json['id']?.toString() ?? '',
      billId: json['billId']?.toString() ?? '',
      adminMessage: json['adminMessage']?.toString() ?? '',
      // Requests recorded before the field existed were all about the bill.
      type: json['type']?.toString() ?? 'bill',
      status: json['status']?.toString() ?? 'pending',
      userMessage: json['userMessage']?.toString(),
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => BillFileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resolvedAt: json['resolvedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  bool get isPending => status == 'pending';

  bool get isContract => type == 'contract';
}
