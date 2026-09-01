import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fader_app/main.dart';

void main() {
  testWidgets('FADER splash renders the product identity', (WidgetTester tester) async {
    await tester.pumpWidget(const FaderApp());
    expect(find.text('FADER'), findsOneWidget);
    expect(find.text('TAP THE PUPIL TO BEGIN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
