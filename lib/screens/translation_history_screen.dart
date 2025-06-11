import 'package:flutter/material.dart';
import '../models/translation_history.dart';
import '../services/translation_history_service.dart';

class TranslationHistoryScreen extends StatefulWidget {
  final TranslationHistoryService historyService;

  const TranslationHistoryScreen({
    super.key,
    required this.historyService,
  });

  @override
  State<TranslationHistoryScreen> createState() =>
      _TranslationHistoryScreenState();
}

class _TranslationHistoryScreenState extends State<TranslationHistoryScreen> {
  List<TranslationHistory> _history = [];
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await widget.historyService.getHistory();
    setState(() {
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История переводов'),
        actions: [
          IconButton(
            icon: Icon(
                _showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Очистить историю'),
                  content: const Text(
                      'Вы уверены, что хотите очистить всю историю переводов?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Очистить'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await widget.historyService.clearHistory();
                _loadHistory();
              }
            },
          ),
        ],
      ),
      body: _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    final filteredHistory = _showFavoritesOnly
        ? _history.where((item) => item.isFavorite).toList()
        : _history;

    if (filteredHistory.isEmpty) {
      return Center(
        child: Text(
          _showFavoritesOnly
              ? 'Нет избранных переводов'
              : 'История переводов пуста',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final item = filteredHistory[index];
        return Dismissible(
          key: Key(item.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await widget.historyService.deleteTranslation(item.id);
            _loadHistory();
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                item.sourceText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.translatedText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.sourceLanguage} → ${item.targetLanguage}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatDate(item.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: item.isFavorite ? Colors.red : null,
                ),
                onPressed: () async {
                  await widget.historyService.toggleFavorite(item.id);
                  _loadHistory();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}
