// SPDX-License-Identifier: GPL-3.0-or-later
// Shared preview models for chat list items

class ContactPreview {
  final String haloId;
  final String? nickname;
  final String? preview;
  final DateTime? when;
  final String avatarSeed;
  // the face they picked, if they have. null means draw from their id.
  final int? avatar;
  final bool blocked;
  final bool archived;
  final bool muted;
  final bool verified;
  final int unread;
  final bool pinned;
  final String? supporterBadge;

  ContactPreview({
    required this.haloId,
    this.nickname,
    this.preview,
    this.when,
    required this.avatarSeed,
    this.avatar,
    this.blocked = false,
    this.archived = false,
    this.muted = false,
    this.verified = false,
    this.unread = 0,
    this.pinned = false,
    this.supporterBadge,
  });
}

class GroupPreview {
  final String groupId;
  final String name;
  final int memberCount;
  final bool isAdmin;
  final DateTime createdAt;
  final int unread;
  final bool mentioned;
  final int? expiresAt; // milliseconds since epoch

  const GroupPreview({
    required this.groupId,
    required this.name,
    required this.memberCount,
    required this.isAdmin,
    required this.createdAt,
    this.unread = 0,
    this.mentioned = false,
    this.expiresAt,
  });
}
