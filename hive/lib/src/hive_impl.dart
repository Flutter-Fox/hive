import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

import 'backend/storage_backend.dart';

class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  final _boxes = HashMap<String, Box>();

  String _homePath;

  HiveImpl() {
    registerInternal(DateTimeAdapter(), 16);
    registerInternal(BigIntAdapter(), 17);
  }

  @override
  String get path {
    if (_homePath == null) {
      throw HiveError('Hive not initialized. Call Hive.init() first.');
    }

    return _homePath;
  }

  @override
  void init(String path) {
    _homePath = path;

    _boxes.clear();
  }

  @override
  Future<Box> openBox(
    String name, {
    List<int> encryptionKey,
    CompactionStrategy compactionStrategy,
    bool crashRecovery = true,
    bool lazy = false,
  }) async {
    if (isBoxOpen(name)) {
      return box(name);
    } else {
      if (encryptionKey != null) {
        if (encryptionKey.length != 32 ||
            encryptionKey.any((it) => it < 0 || it > 255)) {
          throw ArgumentError(
              'The encryption key has to be a 32 byte (256 bit) array.');
        }
      }

      var options = BoxOptions(
        encryptionKey: encryptionKey,
        compactionStrategy: defaultCompactionStrategy,
      );

      var lowercaseName = name.toLowerCase();
      var box = await openBoxInternal(this, lowercaseName, lazy, options);
      _boxes[lowercaseName] = box;

      return box;
    }
  }

  @override
  Box box(String name) {
    if (isBoxOpen(name)) {
      return _boxes[name.toLowerCase()];
    } else {
      throw HiveError('Box not found. Did you forget to call Hive.openBox()?');
    }
  }

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name.toLowerCase());
  }

  @override
  Future<void> close() {
    var closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  void unregisterBox(String name) {
    _boxes.remove(name.toLowerCase());
  }

  @override
  Future<void> deleteFromDisk() {
    var deleteFutures = _boxes.values.toList().map((box) {
      return box.deleteFromDisk();
    });

    return Future.wait(deleteFutures);
  }

  @override
  List<int> generateSecureKey() {
    var secureRandom = CryptoHelper.createSecureRandom();
    return secureRandom.nextBytes(32);
  }
}
