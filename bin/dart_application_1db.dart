// ignore_for_file: avoid_print

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_io.dart';

void main() async {
  final idbFactory = getIdbFactoryPersistent('test/tmp/out');

  // define the store name
  final storeName = 'users';

  // open the database
  final db = await idbFactory.open('my_records.db', version: 1,
      onUpgradeNeeded: (VersionChangeEvent event) {
    final db = event.database;
    // create the store

    ObjectStore store = db.createObjectStore(storeName, autoIncrement: true);

    // Create initial indexes
    store.createIndex('last_name', 'last_name', unique: false);
    store.createIndex('categoryId', 'categoryId', unique: false);
    store.createIndex('venue_id', 'venue_id', unique: false);
    store.createIndex(
        'last_name_categoryId_venueId', ['last_name', 'categoryId', 'venue_id'],
        unique: false);

    store.createIndex('categoryId_venueId', ['categoryId', 'venue_id'],
        unique: false);

    store.createIndex(
        'categoryId_venueId_lastName', ['categoryId', 'venue_id', 'last_name'],
        unique: false);

    // if (event.oldVersion < 2) {
    //   print("need upggrade");
    //   ObjectStore store = event.transaction.objectStore(storeName);
    //   store.createIndex('categoryId_venueId', ['categoryId', 'venue_id'],
    //       unique: false);
    // }
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

  transaction = db.transaction('users', 'readonly');
  store = transaction.objectStore('users');
  Index categoryIndex = store.index('categoryId');

  List<Map<String, dynamic>> usersWithCategory10 = [];

  await categoryIndex.openCursor(key: 10).forEach((cursor) {
    usersWithCategory10.add(cursor.value as Map<String, dynamic>);
    cursor.advance(1);
  });

  // Print the selected users
  print('Users with categoryId 10:');
  for (var user in usersWithCategory10) {
    print(
        '${user['name']} ${user['last_name']} - Venue ID: ${user['venue_id']}');
  }

  Index categoryVenueIndex = store.index('categoryId_venueId');

  List<Map<String, dynamic>> usersWithCategory10AndVenue61 = [];

  await categoryVenueIndex.openCursor(key: [10, 61]).forEach((cursor) {
    usersWithCategory10AndVenue61.add(cursor.value as Map<String, dynamic>);
    cursor.advance(1);
  });

  // Print the selected users
  print('\nUsers with categoryId 10 and venue_id 61:');
  for (var user in usersWithCategory10AndVenue61) {
    print('${user['name']} ${user['last_name']}');
  }

  transaction = db.transaction(storeName, 'readonly');
  store = transaction.objectStore(storeName);

  List<Map<String, dynamic>> matchingUsers = [];

  try {
    Index complexIndex = store.index('categoryId_venueId_lastName');

    // Define the range for the query
    var lowerBound = [10, 61, 'S'];
    var upperBound = [10, 61, 'T']; // 'T' comes after all 'S' names

    await complexIndex
        .openCursor(range: KeyRange.bound(lowerBound, upperBound, false, true))
        .forEach((cursor) {
      print("FOUND");
      matchingUsers.add(cursor.value as Map<String, dynamic>);
      cursor.advance(1);
    });
  } catch (e) {
    print('Error: $e');
    print('Falling back to manual filtering...');

    // Fallback: manual filtering if the index doesn't exist
    await store.openCursor().forEach((cursor) {
      Map<String, dynamic> user = cursor.value as Map<String, dynamic>;
      if (user['categoryId'] == 10 &&
          user['venue_id'] == 20 &&
          user['last_name'].startsWith('S')) {
        matchingUsers.add(user);
      }
      cursor.advance(1);
    });
  }

  // Print the matching users
  print('\nUsers with category_id = 10 61 , and last name starting with S:');
  for (var user in matchingUsers) {
    print('${user['name']} ${user['last_name']}--');
  }

  // Close the database when done
  db.close();
}
