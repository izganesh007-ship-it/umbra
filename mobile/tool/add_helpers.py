import re

# Read the main file
with open('lib/screens/chat_screen_new.dart', 'r') as f:
    content = f.read()

helper_methods = '''

  // ===========================================
  // SEARCH
  // ===========================================

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchCtrl.clear();
        _query = '';
        _matches.clear();
        _matchPos = 0;
      }
    });
  }

  Widget _buildSearchBar(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = context.l10n;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: UmbraSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: UmbraTypography.textBase,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.chatSearchHint,
                hintStyle: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: UmbraTypography.textBase,
                  color: colors.textMuted,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted, size: 22),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 22),
            onPressed: _toggleSearch,
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.toLowerCase();
      _matches.clear();
      _matchPos = 0;
      if (_query.isNotEmpty) {
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].text.toLowerCase().contains(_query)) {
            _matches.add(i);
          }
        }
      }
    });
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _matchPos = (_matchPos + 1) % _matches.length;
      _scrollToMatch(_matches[_matchPos]);
    });
  }

  void _prevMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _matchPos = (_matchPos - 1) % _matches.length;
      if (_matchPos < 0) _matchPos = _matches.length - 1;
      _scrollToMatch(_matches[_matchPos]);
    });
  }

  void _scrollToMatch(int index) {
    // TODO: Implement scroll to match
  }

  // ===========================================
  // KEY VERIFICATION
  // ===========================================

  void _openKeyVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeyVerificationScreen(
          peerName: widget.peerName,
          peerHaloId: widget.peerHaloId,
        ),
      ),
    );
  }

  // ===========================================
  // REPLY QUOTE BAR
  // ===========================================

  Widget _buildReplyQuoteBar(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.fromLTRB(UmbraSpacing.space4, UmbraSpacing.space2, UmbraSpacing.space4, UmbraSpacing.space2),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border(bottom: BorderSide(color: colors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.chatReplyingTo,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontMono,
                    fontSize: UmbraTypography.textXs,
                    fontWeight: UmbraTypography.weightMedium,
                    color: colors.accent,
                  ),
                ),
                SizedBox(height: UmbraSpacing.space1),
                Text(
                  _replyTo!.text,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontSans,
                    fontSize: UmbraTypography.textSm,
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // STICKY DATE HEADERS
  // ===========================================

  Widget _buildMessageWithDateHeader(
    ChatMessage message,
    ChatMessage? prevMessage,
    ChatMessage? nextMessage,
    int index,
  ) {
    final showDateHeader = _shouldShowDateHeader(message, prevMessage);

    if (showDateHeader) {
      final dateLabel = _getDateLabel(message.when);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateSeparator(dateLabel),
          _buildMessage(message, prevMessage, nextMessage),
        ],
      );
    }

    return _buildMessage(message, prevMessage, nextMessage);
  }

  bool _shouldShowDateHeader(ChatMessage message, ChatMessage? prevMessage) {
    if (prevMessage == null) return true;
    if (message.when == null || prevMessage.when == null) return false;
    return !_isSameDay(message.when!, prevMessage.when!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateLabel(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDay == today) {
      return context.l10n.chatToday;
    } else if (msgDay == yesterday) {
      return context.l10n.chatYesterday;
    } else {
      final weekdays = [
        context.l10n.dayMonday,
        context.l10n.dayTuesday,
        context.l10n.dayWednesday,
        context.l10n.dayThursday,
        context.l10n.dayFriday,
        context.l10n.daySaturday,
        context.l10n.daySunday,
      ];
      if (now.difference(msgDay).inDays < 7) {
        return weekdays[dateTime.weekday - 1];
      }
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Widget _buildDateSeparator(String label) {
    final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: UmbraSpacing.space2),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.separator, thickness: 0.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: UmbraSpacing.space3),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: UmbraTypography.fontMono,
                fontSize: UmbraTypography.textXs,
                fontWeight: UmbraTypography.weightMedium,
                color: colors.textMuted,
                letterSpacing: UmbraTypography.trackingWide,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.separator, thickness: 0.5)),
        ],
      ),
    );
  }

  // ===========================================
  // BURN TIMER
  // ===========================================

  void _startBurnTimer() {
    _burnTick?.cancel();
    _burnTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkBurnTimers();
    });
  }

  void _checkBurnTimers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bool hasChanges = false;

    for (final message in _messages) {
      if (message.burnAt != null &&
          message.burnAt! <= now &&
          !message.removing &&
          !message.sending &&
          !message.failed) {
        message.removing = true;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      setState(() {
        _messages.removeWhere((m) => m.removing);
      });
    }
  }
'''

# Insert after _checkInbox method
pattern = r'(void _checkInbox\(\) \{\s*// Check for new messages\s*\})'
replacement = r'\1' + helper_methods

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/screens/chat_screen_new.dart', 'w') as f:
    f.write(content)

print('Helper methods added')