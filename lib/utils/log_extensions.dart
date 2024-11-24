import 'package:flutter/foundation.dart';

int defaultLength = 150;

void logDebug(Object? content, {String? header, String? footer, int? maxLength}) {
  if (kDebugMode && content != null) {
    String contentStr;

    // Chuyển đổi nội dung thành chuỗi nếu là Map hoặc String
    if (content is String) {
      contentStr = content;
    } else if (content is Map) {
      contentStr = _mapToString(content);
    } else {
      contentStr = content.toString();
    }

    // Lấy tên class từ StackTrace
    String className = "Log from: ${_getCallerClassName()}";

    // Tính chiều dài của object hoặc header nếu có, cộng thêm chiều dài của className
    int maxLineLength = className.length;
    if (header != null) {
      maxLineLength = maxLineLength > header.length ? maxLineLength : header.length; // Chọn chiều dài lớn nhất giữa className và header
    }

    // Tính chiều dài tối đa giữa các dòng nội dung
    for (var line in contentStr.split('\n')) {
      if (line.length > maxLineLength) {
        maxLineLength = line.length; // Tính chiều dài tối đa của các dòng nội dung
      }
    }

    final defaultMaxLength = maxLength ?? defaultLength;

    // Đảm bảo maxLineLength không quá dài, ví dụ giới hạn ở 100
    if (maxLineLength > defaultMaxLength) {
      maxLineLength = defaultMaxLength;
    }

    // Viền trên
    final borderTop = '╔${'=' * (maxLineLength + 2)}╗';
    if (kDebugMode) print(borderTop);

    // In tên class gọi log
    if (kDebugMode) {
      final paddedClassName = className.padRight(maxLineLength);
      if (kDebugMode) {
        print('║ $paddedClassName ║');
      }
      print('╟${'─' * (maxLineLength + 2)}╢');
    }

    // In header nếu có
    if (header != null) {
      final paddedHeader = header.padRight(maxLineLength);
      if (kDebugMode) {
        print('║ $paddedHeader ║');
      }
      if (kDebugMode) {
        print('╟${'─' * (maxLineLength + 2)}╢');
      }
    }

    // In từng dòng của object (chắc chắn mỗi dòng không quá 100 ký tự)
    final lines = contentStr.split('\n');
    for (var line in lines) {
      // Nếu dòng quá dài, chia nhỏ ra và in ra
      _printWrappedLine(line, maxLineLength);
    }

    // Viền dưới
    final borderBottom = '╚${'=' * (maxLineLength + 2)}╝';
    if (kDebugMode) print(borderBottom);
  }
}

String _mapToString(Map content) {
  final buffer = StringBuffer();
  content.forEach((key, value) {
    String valueStr = value != null ? value.toString() : 'null';
    if (value is String) {
      valueStr = '"$valueStr"';
    }
    buffer.writeln('$key: $valueStr');
  });
  return buffer.toString();
}

String _getCallerClassName() {
  // Dùng StackTrace để lấy tên class gọi log
  final stackTrace = StackTrace.current.toString().split('\n');

  // Tìm dòng đầu tiên có dạng: <class>.<method> (file:line)
  final callerLine = stackTrace[2];

  // Trích xuất tên lớp từ phần đầu của dòng
  final regex = RegExp(r'(\w+)\.(\w+)');
  final match = regex.firstMatch(callerLine);

  if (match != null) {
    // Lấy tên lớp (thường là phần đầu tiên trong biểu thức)
    return match.group(1) ?? 'Unknown';
  }
  return 'Unknown'; // Nếu không thể tìm thấy tên lớp
}

// Hàm in dòng dài, tự động xuống dòng nếu cần thiết
void _printWrappedLine(String line, int maxLineLength) {
  // Nếu dòng dài hơn maxLineLength, chia nhỏ và in ra từng phần
  while (line.length > maxLineLength) {
    final wrappedLine = line.substring(0, maxLineLength);
    if (kDebugMode) {
      print('║ ${wrappedLine.padRight(maxLineLength)} ║');
    }
    line = line.substring(maxLineLength);
  }

  // In phần còn lại (nếu có)
  if (line.isNotEmpty) {
    if (kDebugMode) {
      print('║ ${line.padRight(maxLineLength)} ║');
    }
  }
}
