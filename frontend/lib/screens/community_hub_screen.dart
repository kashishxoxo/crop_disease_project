import 'package:flutter/material.dart';

import '../models/community_comment_model.dart';
import '../models/community_post_model.dart';
import '../services/auth_service.dart';
import '../services/community_hub_service.dart';
import '../services/user_service.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  String _selectedTopic = CommunityPostModel.topics.first;
  String _selectedType = CommunityPostModel.typeFilters.first;

  Future<void> _openComposer() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePostSheet(),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your community post is now live.')),
      );
    }
  }

  void _openGuidelines() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CommunityGuidelinesSheet(),
    );
  }

  void _openPostDetails(CommunityPostModel post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostDetailSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farmer Community Hub')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Please login to join the farmer community hub.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EC),
      appBar: AppBar(
        title: const Text('Farmer Community Hub'),
        actions: [
          IconButton(
            tooltip: 'Community guidelines',
            onPressed: _openGuidelines,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.forum_rounded),
        label: const Text('New Post'),
      ),
      body: StreamBuilder<List<CommunityPostModel>>(
        stream: CommunityHubService.postsStream(),
        builder: (context, snapshot) {
          final allPosts = snapshot.data ?? const <CommunityPostModel>[];
          final filteredPosts = allPosts
              .where((post) => post.matchesTopicFilter(_selectedTopic))
              .where((post) => post.matchesTypeFilter(_selectedType))
              .toList();

          final questionCount = allPosts
              .where((post) => post.postType == CommunityPostType.question)
              .length;
          final resolvedCount =
              allPosts.where((post) => post.isResolved).length;
          final activeLocations = allPosts
              .map((post) => post.authorLocation.trim())
              .where((location) => location.isNotEmpty)
              .toSet()
              .length;

          return Stack(
            children: [
              Positioned(
                top: -90,
                right: -30,
                child: _GlowOrb(
                  size: 220,
                  color: const Color(0x263F8F55),
                ),
              ),
              Positioned(
                top: 260,
                left: -70,
                child: _GlowOrb(
                  size: 180,
                  color: const Color(0x22B66A1E),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CommunityHero(
                        questionCount: questionCount,
                        resolvedCount: resolvedCount,
                        activeLocations: activeLocations,
                      ),
                      const SizedBox(height: 18),
                      _ComposerCard(onTap: _openComposer),
                      const SizedBox(height: 20),
                      Text(
                        'Browse discussions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ask field questions, compare disease patterns, and share practical fixes with other growers.',
                        style: TextStyle(
                          color: Color(0xFF5F7362),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29412D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CommunityPostModel.typeFilters
                            .map(
                              (filter) => FilterChip(
                                label: Text(filter),
                                selected: _selectedType == filter,
                                onSelected: (_) {
                                  setState(() => _selectedType = filter);
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Topic',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29412D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CommunityPostModel.topics
                            .map(
                              (topic) => FilterChip(
                                label: Text(topic),
                                selected: _selectedTopic == topic,
                                onSelected: (_) {
                                  setState(() => _selectedTopic = topic);
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (filteredPosts.isEmpty)
                        _EmptyCommunityState(
                          hasPosts: allPosts.isNotEmpty,
                          onCreate: _openComposer,
                        )
                      else
                        ListView.builder(
                          itemCount: filteredPosts.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _CommunityPostCard(
                                post: post,
                                currentUid: uid,
                                onLike: () async {
                                  await CommunityHubService.toggleLike(
                                    postId: post.id,
                                    uid: uid,
                                  );
                                },
                                onOpenComments: () => _openPostDetails(post),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({
    required this.questionCount,
    required this.resolvedCount,
    required this.activeLocations,
  });

  final int questionCount;
  final int resolvedCount;
  final int activeLocations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4022), Color(0xFF255E34), Color(0xFF3A7A46)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniBadge(label: 'REAL FARMER DISCUSSIONS'),
          const SizedBox(height: 10),
          const Text(
            'Learn from nearby growers,\nnot just the model.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Share what you are seeing in the field, compare outcomes, and close the loop on treatments that worked.',
            style: TextStyle(
              color: Color(0xD8FFFFFF),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(
                icon: Icons.quiz_outlined,
                label: '$questionCount questions',
              ),
              _StatPill(
                icon: Icons.task_alt,
                label: '$resolvedCount resolved',
              ),
              _StatPill(
                icon: Icons.location_on_outlined,
                label: '$activeLocations locations',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: const Color(0xFFFFFCF7),
            border: Border.all(color: const Color(0xFFE1D8C9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB66A1E), Color(0xFF7B4612)],
                  ),
                ),
                child: const Icon(Icons.campaign_outlined, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a field discussion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF203425),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Post a disease question, prevention tip, or local field alert for other farmers.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF5D6E61),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF29412D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({
    required this.post,
    required this.currentUid,
    required this.onLike,
    required this.onOpenComments,
  });

  final CommunityPostModel post;
  final String currentUid;
  final Future<void> Function() onLike;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    final liked = post.isLikedBy(currentUid);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4DDCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                child: Text(
                  _initials(post.authorName),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF203425),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _authorMeta(post),
                      style: const TextStyle(
                        color: Color(0xFF66786A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatRelativeTime(post.createdAt),
                style: const TextStyle(
                  color: Color(0xFF6E7F72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TopicTag(label: post.typeLabel, filled: true),
              _TopicTag(label: post.topic),
              if (post.isResolved) const _TopicTag(label: 'Resolved'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17331D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.body,
            style: const TextStyle(
              color: Color(0xFF4C6150),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenComments,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('${post.commentsCount} comments'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: liked
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFE7EFE5),
                    foregroundColor: liked
                        ? Colors.white
                        : const Color(0xFF23422A),
                  ),
                  onPressed: onLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text('${post.likesCount} likes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _authorMeta(CommunityPostModel post) {
    final meta = <String>[
      if (post.authorCropType.trim().isNotEmpty) post.authorCropType.trim(),
      if (post.authorLocation.trim().isNotEmpty) post.authorLocation.trim(),
    ];
    return meta.isEmpty ? 'Community member' : meta.join(' • ');
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'F';
    return trimmed.characters.first.toUpperCase();
  }
}

class _PostDetailSheet extends StatefulWidget {
  const _PostDetailSheet({required this.post});

  final CommunityPostModel post;

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isTogglingResolved = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) return;
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final profile = await UserService.getProfile(uid);
      await CommunityHubService.addComment(
        postId: widget.post.id,
        uid: uid,
        profile: profile,
        body: body,
      );
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _toggleResolved() async {
    setState(() => _isTogglingResolved = true);
    try {
      await CommunityHubService.setResolved(
        postId: widget.post.id,
        resolved: !widget.post.isResolved,
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingResolved = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid ?? '';
    final isOwner = uid == widget.post.authorUid;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F6EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 12,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFCDC4B6),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.post.title,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17331D),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TopicTag(label: widget.post.typeLabel, filled: true),
                          _TopicTag(label: widget.post.topic),
                          if (widget.post.isResolved)
                            const _TopicTag(label: 'Resolved'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.post.body,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.55,
                          color: Color(0xFF425647),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Posted by ${widget.post.authorName} • ${_formatAbsoluteTime(widget.post.createdAt)}',
                        style: const TextStyle(
                          color: Color(0xFF708171),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isOwner &&
                          widget.post.postType == CommunityPostType.question) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isTogglingResolved
                                ? null
                                : _toggleResolved,
                            icon: Icon(
                              widget.post.isResolved
                                  ? Icons.refresh
                                  : Icons.task_alt,
                            ),
                            label: Text(
                              widget.post.isResolved
                                  ? 'Mark as open again'
                                  : 'Mark as resolved',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D3321),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<List<CommunityCommentModel>>(
                          stream: CommunityHubService.commentsStream(
                            widget.post.id,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final comments =
                                snapshot.data ?? const <CommunityCommentModel>[];
                            if (comments.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No comments yet.\nShare the first response to help this farmer.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF69796C),
                                    height: 1.45,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                final meta = <String>[
                                  if (comment.authorCropType.trim().isNotEmpty)
                                    comment.authorCropType.trim(),
                                  if (comment.authorLocation.trim().isNotEmpty)
                                    comment.authorLocation.trim(),
                                ].join(' • ');

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE5DDCF),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF203425),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        meta.isEmpty
                                            ? _formatRelativeTime(
                                                comment.createdAt,
                                              )
                                            : '$meta • ${_formatRelativeTime(comment.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6E7E71),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment.body,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: Color(0xFF425647),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Add a practical suggestion or follow-up question...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submitComment,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  CommunityPostType _postType = CommunityPostType.question;
  String _topic = CommunityPostModel.topics[1];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);
    try {
      final profile = await UserService.getProfile(uid);
      await CommunityHubService.createPost(
        uid: uid,
        profile: profile,
        title: _titleController.text,
        body: _bodyController.text,
        topic: _topic,
        postType: _postType,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFCDC4B6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Create a community post',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17331D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Keep it practical: what you saw, what you tried, and what kind of help you need.',
                    style: TextStyle(
                      color: Color(0xFF5C6D61),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<CommunityPostType>(
                    initialValue: _postType,
                    items: CommunityPostType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_typeTitle(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _postType = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Post type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _topic,
                    items: CommunityPostModel.topics
                        .where((topic) => topic != 'All')
                        .map(
                          (topic) => DropdownMenuItem(
                            value: topic,
                            child: Text(topic),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _topic = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Example: Brown spots spreading after last rainfall',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return 'Add a short title.';
                      if (trimmed.length < 8) {
                        return 'Please make the title a bit more descriptive.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bodyController,
                    minLines: 5,
                    maxLines: 7,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      hintText: 'Describe the crop stage, symptoms, weather, what treatment you tried, and what advice you need.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return 'Add details for the community.';
                      if (trimmed.length < 24) {
                        return 'Add a little more context so others can help.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.publish_rounded),
                      label: Text(
                        _isSubmitting ? 'Posting...' : 'Publish post',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _typeTitle(CommunityPostType type) {
    switch (type) {
      case CommunityPostType.question:
        return 'Question';
      case CommunityPostType.tip:
        return 'Tip';
      case CommunityPostType.alert:
        return 'Alert';
    }
  }
}

class _CommunityGuidelinesSheet extends StatelessWidget {
  const _CommunityGuidelinesSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFCDC4B6),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Community guidelines',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17331D),
                ),
              ),
              const SizedBox(height: 12),
              const _GuidelineRow(
                icon: Icons.photo_camera_back_outlined,
                text: 'Mention the crop stage, recent weather, and visible symptoms clearly.',
              ),
              const _GuidelineRow(
                icon: Icons.task_alt,
                text: 'Share what treatment or preventive step actually worked in your field.',
              ),
              const _GuidelineRow(
                icon: Icons.verified_user_outlined,
                text: 'Avoid posting private details or unsafe chemical advice without context.',
              ),
              const _GuidelineRow(
                icon: Icons.forum_outlined,
                text: 'Be respectful and keep replies practical so other farmers can act on them quickly.',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EFE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.45,
                color: Color(0xFF485C4C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState({
    required this.hasPosts,
    required this.onCreate,
  });

  final bool hasPosts;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final title = hasPosts
        ? 'No posts match these filters yet.'
        : 'Your community hub is ready for the first discussion.';
    final subtitle = hasPosts
        ? 'Try another topic or type, or start a new thread yourself.'
        : 'Ask a field question, share a prevention tip, or post a local disease alert to get the hub moving.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE4DDCF)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF3F8F55), Color(0xFF255E34)],
              ),
            ),
            child: const Icon(Icons.groups_2_outlined, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D3420),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5B6D60),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Start a discussion'),
          ),
        ],
      ),
    );
  }
}

class _TopicTag extends StatelessWidget {
  const _TopicTag({
    required this.label,
    this.filled = false,
  });

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: filled ? const Color(0xFF1B5E20) : const Color(0xFFE6EFE2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : const Color(0xFF1F3A24),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _formatAbsoluteTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/$year • $hour:$minute $amPm';
}
