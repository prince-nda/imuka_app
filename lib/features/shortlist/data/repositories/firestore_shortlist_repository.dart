import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_paths.dart';
import '../../../../core/data/uid_provider.dart';
import '../../domain/repositories/shortlist_repository.dart';

/// Saved homes in `users/{uid}/shortlist/{propertyId}`.
///
/// The document id is the property id (foreign key), so a home can't be
/// saved twice.
class FirestoreShortlistRepository implements ShortlistRepository {
  FirestoreShortlistRepository(this._uid, {FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final UidProvider _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.doc(FirestorePaths.user(_uid())).collection(FirestorePaths.shortlist);

  @override
  Future<List<String>> fetchIds() async {
    final snapshot = await _collection.orderBy('addedAt').get();
    return [for (final doc in snapshot.docs) doc.id];
  }

  @override
  Future<void> add(String propertyId) => _collection.doc(propertyId).set({
    'propertyId': propertyId,
    'addedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> remove(String propertyId) =>
      _collection.doc(propertyId).delete();
}
