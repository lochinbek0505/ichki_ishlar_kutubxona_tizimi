import 'package:flutter_test/flutter_test.dart';
import 'package:ichki_ishlar_litseyi_kutubxona_tizimi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KutubxonaApp());
  });
}
