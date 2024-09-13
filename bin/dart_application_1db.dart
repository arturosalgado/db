// ignore_for_file: avoid_print

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_io.dart';

void main() async {
  final idbFactory = getIdbFactoryPersistent('test/tmp/out');

  // define the store name
  final storeName = 'records';

  // open the database
  final db = await idbFactory.open('my_records.db', version: 1,
      onUpgradeNeeded: (VersionChangeEvent event) {
    final db = event.database;
    // create the store
    ObjectStore store = db.createObjectStore('users', autoIncrement: true);

    // Create indexes
    store.createIndex('last_name', 'last_name', unique: false);
    store.createIndex('categoryId', 'categoryId', unique: false);
    store.createIndex('venue_id', 'venue_id', unique: false);
    store.createIndex(
        'last_name_categoryId_venueId', ['last_name', 'categoryId', 'venue_id'],
        unique: false);
  });

  List<Map<String, dynamic>> sampleUsers = [
    {'name': 'John', 'last_name': 'Smith', 'categoryId': 10, 'venue_id': 61},
    {'name': 'Emma', 'last_name': 'Johnson', 'categoryId': 10, 'venue_id': 62},
    {
      'name': 'Michael',
      'last_name': 'Williams',
      'categoryId': 11,
      'venue_id': 61
    },
    {'name': 'Olivia', 'last_name': 'Brown', 'categoryId': 10, 'venue_id': 63},
    {'name': 'William', 'last_name': 'Jones', 'categoryId': 12, 'venue_id': 64}
  ];

  // Add sample users to the database
  Transaction transaction = db.transaction('users', 'readwrite');
  ObjectStore store = transaction.objectStore('users');

  for (var user in sampleUsers) {
    await store.add(user);
  }

  // Close the database when done
  db.close();
}
