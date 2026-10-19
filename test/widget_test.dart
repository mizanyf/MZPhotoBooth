import 'package:flutter_test/flutter_test.dart';
import 'package:mzphotobooth/main.dart';

void main() {
  testWidgets('MZ Photobooth smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify header and headline exist.
    expect(find.text('PHOTOBOOTH STUDIO'), findsOneWidget);

    // Verify 3 steps exist.
    expect(find.text('Atur dulu'), findsOneWidget);
    expect(find.text('Ambil Pose'), findsOneWidget);
    expect(find.text('Simpan Hasil'), findsOneWidget);

    // Verify CTA exists.
    expect(find.text('MULAI SEKARANG'), findsOneWidget);
  });
}
