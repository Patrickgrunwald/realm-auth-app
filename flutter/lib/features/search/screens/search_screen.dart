import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/supabase_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isLoading = false;
  List<_SearchResult> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() {
        _results = [];
        _query = q;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = q;
    });

    try {
      final data = await SupabaseService.client
          .from(AppConstants.usersTable)
          .select('id, username, display_name, avatar_url')
          .or('username.ilike.%$q%,display_name.ilike.%$q%')
          .limit(20);

      setState(() {
        _results = data.map((raw) => _SearchResult(
          id: raw['id'] as String,
          username: raw['username'] as String? ?? '',
          displayName: raw['display_name'] as String? ?? '',
          avatarUrl: raw['avatar_url'] as String?,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[SearchScreen] search error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nutzer suchen...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: _search,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Wonach suchst du?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 12),
            Text(
              'Keine Ergebnisse für "$_query"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: r.avatarUrl != null
                ? CachedNetworkImageProvider(r.avatarUrl!)
                : null,
            child: r.avatarUrl == null
                ? Text(
                    r.username.isNotEmpty ? r.username[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary),
                  )
                : null,
          ),
          title: Text(
            r.username,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            r.displayName,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: () {
            context.push('/profile?userId=${r.id}');
          },
        );
      },
    );
  }
}

class _SearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const _SearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });
}
