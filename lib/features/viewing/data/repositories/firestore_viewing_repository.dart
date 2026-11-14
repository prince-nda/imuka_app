import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_codec.dart';
import '../../../../core/data/firestore_paths.dart';
import '../../../../core/data/uid_provider.dart';
import '../../../../core/data/value_codec.dart';
import '../../../properties/domain/repositories/property_repository.dart';
import '../../domain/entities/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';

/// Viewing requests in `viewings/{viewingId}`.
///
/// Only foreign keys (`userId`, `propertyId`, `landlordId`) are stored;
/// titles and owner names are joined from the listings when reading.
class FirestoreViewingRepository implements ViewingRepository {
  FirestoreViewingRepository(
    this._uid,
    this._properties, {
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final UidProvider _uid;
  final PropertyRepository _properties;
  final FirebaseFirestore _db;
  static const _codec = FirestoreCodec();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(FirestorePaths.viewings);

  @override
  Future<ViewingRequest> requestViewing(ViewingRequest request) async {
    final doc = await _collection.add({
      'userId': _uid(),
      'propertyId': request.propertyId,
      'landlordId': request.landlordId,
      'scheduledAt': _codec.encodeDate(request.scheduledAt),
      'channel': request.channel.name,
      'message': request.message,
      'status': ViewingStatus.requested.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return request.copyWith(id: doc.id);
  }

  /// Uses the composite index `viewings (userId ASC, scheduledAt ASC)`.
  @override
  Future<List<ViewingRequest>> fetchMyViewings() async {
    final (snapshot, properties) = await (
      _collection
          .where('userId', isEqualTo: _uid())
          .orderBy('scheduledAt')
          .get(),
      _properties.fetchProperties(),
    ).wait;
    final byId = {for (final p in properties) p.id: p};
    return [
      for (final doc in snapshot.docs)
        if (byId[doc.data()['propertyId']] case final property?)
          ViewingRequest(
            id: doc.id,
            propertyId: property.id,
            propertyTitle: property.title,
            landlordId: property.owner.id,
            ownerName: property.owner.name,
            ownerReplyMinutes: property.owner.typicalReplyMinutes,
            scheduledAt: _codec.decodeDate(doc.data()['scheduledAt']),
            channel: enumByName(
              ContactChannel.values,
              doc.data()['channel'],
              ContactChannel.whatsapp,
            ),
            message: doc.data()['message'] as String? ?? '',
            status: enumByName(
              ViewingStatus.values,
              doc.data()['status'],
              ViewingStatus.requested,
            ),
          ),
    ];
  }

  @override
  Future<void> cancelViewing(String id) =>
      _collection.doc(id).update({'status': ViewingStatus.cancelled.name});
}
