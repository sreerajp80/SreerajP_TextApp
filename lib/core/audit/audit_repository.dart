/// SQLite repository for the tamper-evident audit log (Feature 8).
///
/// Owns the `audit_log` table. Every append is transactional so two concurrent
/// calls never read the same `previous_hash`. Chain verification walks the
/// table in insertion order and recomputes each hash.
library;

import 'package:sqflite/sqflite.dart';

import 'package:text_data/core/audit/audit_constants.dart';
import 'package:text_data/core/audit/audit_hasher.dart';
import 'package:text_data/core/audit/audit_models.dart';

/// Low-level CRUD and chain verification over the `audit_log` table.
class AuditRepository {
  final Database db;

  AuditRepository(this.db);

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Appends a new entry, chaining it to the current tail.
  ///
  /// Runs inside a transaction so two concurrent appends never read the same
  /// latest hash. Returns the inserted [AuditEntry] with its assigned [id].
  Future<AuditEntry> append({
    required String eventType,
    required int timestamp,
    String? fileName,
    String? fileFingerprint,
    String? beforeHash,
    String? afterHash,
    String? detail,
  }) async {
    return db.transaction<AuditEntry>((txn) async {
      final previousHash = await _latestHash(txn);

      final entryHash = AuditHasher.computeEntryHash(
        previousHash: previousHash,
        eventType: eventType,
        timestamp: timestamp,
        beforeHash: beforeHash,
        afterHash: afterHash,
        detail: detail,
      );

      final entry = AuditEntry(
        eventType: eventType,
        timestamp: timestamp,
        fileName: fileName,
        fileFingerprint: fileFingerprint,
        beforeHash: beforeHash,
        afterHash: afterHash,
        detail: detail,
        entryHash: entryHash,
        previousHash: previousHash,
      );

      final id = await txn.insert('audit_log', entry.toRow());
      return entry.copyWith(id: id);
    });
  }

  /// Deletes every row in the log. After clearing, the chain restarts from the
  /// genesis hash.
  Future<void> clear() async {
    await db.delete('audit_log');
  }

  /// Deletes all entries that reference [fingerprint]. Used by the ephemeral
  /// wiper to remove traces of a burned document.
  Future<int> clearForFingerprint(String fingerprint) async {
    return db.delete(
      'audit_log',
      where: 'file_fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// The `entry_hash` of the newest row, or [AuditConstants.genesisHash] if
  /// the log is empty.
  Future<String> getLatestHash() => _latestHash(db);

  /// Paginated entries, newest first.
  Future<List<AuditEntry>> getAll({int? limit, int? offset}) async {
    final rows = await db.query(
      'audit_log',
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(AuditEntry.fromRow).toList();
  }

  /// Entries for one file, newest first.
  Future<List<AuditEntry>> getByFingerprint(String fingerprint) async {
    final rows = await db.query(
      'audit_log',
      where: 'file_fingerprint = ?',
      whereArgs: [fingerprint],
      orderBy: 'id DESC',
    );
    return rows.map(AuditEntry.fromRow).toList();
  }

  /// Total number of entries in the log.
  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM audit_log');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Chain verification
  // ---------------------------------------------------------------------------

  /// Walks the chain from oldest to newest, recomputing each entry's hash and
  /// checking it matches the stored value. Returns immediately on the first
  /// corruption.
  ///
  /// [batchSize] controls how many rows are loaded per query, so the full log
  /// is never in memory at once.
  Future<AuditVerificationResult> verifyChain({int batchSize = 200}) async {
    final total = await count();
    if (total == 0) return const AuditVerificationResult.empty();

    var previousHash = AuditConstants.genesisHash;
    var offset = 0;
    var index = 0;

    while (offset < total) {
      final rows = await db.query(
        'audit_log',
        orderBy: 'id ASC',
        limit: batchSize,
        offset: offset,
      );
      if (rows.isEmpty) break;

      for (final row in rows) {
        index++;
        final entry = AuditEntry.fromRow(row);

        // Check that the stored previous_hash matches what we expect.
        if (entry.previousHash != previousHash) {
          return AuditVerificationResult(
            status: AuditChainStatus.corrupted,
            corruptedEntryId: entry.id,
            corruptedEntryIndex: index,
            totalEntries: total,
          );
        }

        // Recompute the hash and check.
        final valid = AuditHasher.verifyEntry(
          storedEntryHash: entry.entryHash,
          previousHash: previousHash,
          eventType: entry.eventType,
          timestamp: entry.timestamp,
          beforeHash: entry.beforeHash,
          afterHash: entry.afterHash,
          detail: entry.detail,
        );

        if (!valid) {
          return AuditVerificationResult(
            status: AuditChainStatus.corrupted,
            corruptedEntryId: entry.id,
            corruptedEntryIndex: index,
            totalEntries: total,
          );
        }

        previousHash = entry.entryHash;
      }

      offset += batchSize;
    }

    return AuditVerificationResult.verified(total);
  }

  /// All entries in insertion order, for export. Capped at [limit] if given.
  Future<List<AuditEntry>> getAllForExport({int? limit}) async {
    final rows = await db.query('audit_log', orderBy: 'id ASC', limit: limit);
    return rows.map(AuditEntry.fromRow).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Returns the latest entry hash, or the genesis hash if the table is empty.
  /// Accepts a [DatabaseExecutor] so it works inside a transaction.
  Future<String> _latestHash(DatabaseExecutor executor) async {
    final rows = await executor.query(
      'audit_log',
      columns: ['entry_hash'],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return AuditConstants.genesisHash;
    return rows.first['entry_hash'] as String;
  }
}
