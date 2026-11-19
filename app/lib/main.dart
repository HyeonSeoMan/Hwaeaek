import 'package:material_ui/material_ui.dart';

/// 구현 단계 1: 도메인만 있는 상태. 화면은 단계 4에서 작성한다(Spec §20).
void main() {
  runApp(
    const MaterialApp(
      title: '회애액',
      home: Scaffold(body: Center(child: Text('회애액'))),
    ),
  );
}
