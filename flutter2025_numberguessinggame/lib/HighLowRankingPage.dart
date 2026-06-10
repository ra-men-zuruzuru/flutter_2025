import 'package:flutter/material.dart';

import 'HighLowRankingService.dart';

class HighLowRankingPage extends StatefulWidget {
  const HighLowRankingPage({super.key});

  @override
  State<HighLowRankingPage> createState() => _HighLowRankingPageState();
}

class _HighLowRankingPageState extends State<HighLowRankingPage> {
  final HighLowRankingService _rankingService = HighLowRankingService();
  late Future<List<HighLowScoreEntry>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _rankingService.fetchRanking();
  }

  void _reload() {
    setState(() {
      _rankingFuture = _rankingService.fetchRanking();
    });
  }

  String _formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High & Low ランキング'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: '再読み込み',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<HighLowScoreEntry>>(
          future: _rankingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _RankingMessage(
                message: 'ランキングを読み込めませんでした。',
                actionLabel: '再読み込み',
                onPressed: _reload,
              );
            }

            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return _RankingMessage(
                message: 'まだスコアがありません。',
                actionLabel: '再読み込み',
                onPressed: _reload,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final avatarUrl = entry.avatarPath == null
                    ? null
                    : _rankingService.avatarUrl(entry.avatarPath!);

                return Card(
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RankingAvatar(url: avatarUrl),
                      ],
                    ),
                    title: Text(
                      entry.handleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _RankingTitleChip(title: entry.resultTitle),
                        const SizedBox(height: 4),
                        Text(_formatDate(entry.createdAt)),
                      ],
                    ),
                    trailing: Text(
                      _formatScore(entry.score),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RankingTitleChip extends StatelessWidget {
  final String title;

  const _RankingTitleChip({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.deepPurple.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RankingAvatar extends StatelessWidget {
  final String? url;

  const _RankingAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.person));
    }

    return ClipOval(
      child: Image.network(
        url!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const CircleAvatar(child: Icon(Icons.person));
        },
      ),
    );
  }
}

class _RankingMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _RankingMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
