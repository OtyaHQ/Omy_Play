import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otya_player/shared/widgets/pro_gate.dart';

void main() {
  testWidgets('legacy ProGate keeps every wrapped feature available', (tester) async {
    const feature = Key('unlocked-feature');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProGate(
            featureName: 'Local media tool',
            featureDescription: 'Available to every user',
            child: Text('Feature available', key: feature),
          ),
        ),
      ),
    );

    expect(find.byKey(feature), findsOneWidget);
    expect(find.text('Feature available'), findsOneWidget);
  });
}
