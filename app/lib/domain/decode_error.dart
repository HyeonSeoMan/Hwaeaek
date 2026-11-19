/// 바이너리·백업 형식 검사 실패.
class DecodeError implements Exception {
  const DecodeError(this.message);

  final String message;

  @override
  String toString() => 'DecodeError: $message';
}
