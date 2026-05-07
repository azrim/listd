/// Represents the synchronization status of a task or task list.
///
/// This enum tracks whether an entity has been synced with the remote
/// Google Tasks API or needs to be pushed/pulled.
enum SyncStatus {
  /// Entity has been synced with remote (no pending changes)
  synced(0),

  /// Entity was created locally and needs to be pushed to remote
  created(1),

  /// Entity was updated locally and needs to be pushed to remote
  updated(2),

  /// Entity was deleted locally and needs to be removed from remote
  deleted(3);

  const SyncStatus(this.value);

  /// Numeric value for database storage
  final int value;

  /// Create SyncStatus from database integer value
  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.synced,
    );
  }

  /// Extension for database companion column
  static SyncStatus get defaultValue => SyncStatus.synced;
}

/// Extension methods for SyncStatus
extension SyncStatusExtension on SyncStatus {
  /// Returns true if this entity has pending local changes to sync
  bool get hasPendingChanges =>
      this == SyncStatus.created ||
      this == SyncStatus.updated ||
      this == SyncStatus.deleted;

  /// Returns true if this entity is marked for deletion
  bool get isDeleted => this == SyncStatus.deleted;
}
