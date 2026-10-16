import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts_aplikasi_rekomendasi_destinasi_wisata_kuliner_lokal/main.dart';
import 'package:uts_aplikasi_rekomendasi_destinasi_wisata_kuliner_lokal/models/itinerary_note_model.dart';
import 'package:uts_aplikasi_rekomendasi_destinasi_wisata_kuliner_lokal/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PersistenceService unit test - SharedPreferences and Read/Write Files',
      () async {
    SharedPreferences.setMockInitialValues({});

    // 1. Verifikasi fungsi SharedPreferences pada PersistenceService
    final initialFavs =
        await PersistenceService.loadFavoriteIds(['dest-001', 'dest-002']);
    expect(initialFavs.length, 2);

    final toggled = await PersistenceService.toggleFavoriteId('dest-003');
    expect(toggled, isTrue);

    // 2. Verifikasi fungsi Read and Write Files pada PersistenceService
    const testNote = ItineraryNoteModel(
      destinationId: 'dest-001',
      destinationName: 'Taman Nasional Gunung Bromo',
      plannedDate: '25 Oktober 2026',
      noteText: 'Uji simpan catatan ke file JSON lokal.',
      updatedAt: '16 Okt 2026',
    );
    await PersistenceService.writeNoteToFile(testNote);
    final readBack =
        await PersistenceService.readNoteForDestination('dest-001');
    expect(readBack, isNotNull);
    expect(readBack!.destinationName, 'Taman Nasional Gunung Bromo');
  });

  testWidgets('App smoke test - loads LokaNusantaraApp',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LokaNusantaraApp());
    expect(find.byType(LokaNusantaraApp), findsOneWidget);
  });
}
