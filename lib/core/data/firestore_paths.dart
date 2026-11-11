/// Collection and field names shared by every Firestore data source, so the
/// database structure (and the ERD) is defined in one place.
abstract final class FirestorePaths {
  static const users = 'users';
  static const shortlist = 'shortlist'; // users/{uid}/shortlist/{propertyId}
  static const properties = 'properties';
  static const landlords = 'landlords';
  static const movers = 'movers';
  static const viewings = 'viewings';
  static const moves = 'moves'; // moves/{uid}
  static const items = 'items'; // moves/{uid}/items/{itemId}
  static const tasks = 'tasks'; // moves/{uid}/tasks/{taskId}

  static String user(String uid) => '$users/$uid';
  static String move(String uid) => '$moves/$uid';
}
