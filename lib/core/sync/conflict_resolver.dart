/// 冲突解决结果中的胜出方。
enum ConflictWinner { local, server }

/// 单个模块的冲突解决结果。
class ConflictResolution {
  const ConflictResolution({
    required this.winner,
    required this.data,
    required this.lastModified,
    this.archive,
  });

  /// 胜出方。
  final ConflictWinner winner;

  /// 应当保留的数据。
  final Map<String, dynamic> data;

  /// 保留数据的最后修改时间。
  final DateTime lastModified;

  /// 需要归档到 /archive/ 的旧版本数据，为 `null` 时无需归档。
  final Map<String, dynamic>? archive;
}

/// 冲突解决器。
///
/// 采用设计文档约定的“最后修改时间优先（Last Write Wins）”策略：
/// - 仅本地有数据 → 保留本地并上传。
/// - 仅服务器有数据 → 用服务器数据更新本地。
/// - 本地与服务器最后修改时间相差小于 1 分钟，视为同时修改，保留较新版本，旧版本归档。
/// - 否则保留时间较新的版本，旧版本归档。
class ConflictResolver {
  static const _simultaneousThreshold = Duration(minutes: 1);

  ConflictResolution resolve({
    required Map<String, dynamic> localData,
    required DateTime localLastModified,
    Map<String, dynamic>? serverData,
    DateTime? serverLastModified,
  }) {
    // 服务器无数据，直接保留本地。
    if (serverData == null || serverLastModified == null) {
      return ConflictResolution(
        winner: ConflictWinner.local,
        data: localData,
        lastModified: localLastModified,
      );
    }

    final diff = localLastModified.difference(serverLastModified).abs();

    // 视为同时修改：按毫秒级精确比较，保留较新的一方。
    if (diff <= _simultaneousThreshold) {
      if (localLastModified.isAfter(serverLastModified) ||
          localLastModified.isAtSameMomentAs(serverLastModified)) {
        return ConflictResolution(
          winner: ConflictWinner.local,
          data: localData,
          lastModified: localLastModified,
          archive: serverData,
        );
      }
      return ConflictResolution(
        winner: ConflictWinner.server,
        data: serverData,
        lastModified: serverLastModified,
        archive: localData,
      );
    }

    // 本地较新。
    if (localLastModified.isAfter(serverLastModified)) {
      return ConflictResolution(
        winner: ConflictWinner.local,
        data: localData,
        lastModified: localLastModified,
        archive: serverData,
      );
    }

    // 服务器较新。
    return ConflictResolution(
      winner: ConflictWinner.server,
      data: serverData,
      lastModified: serverLastModified,
      archive: localData,
    );
  }
}
