import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/status_pill.dart';
import '../projection/discovery_service.dart';
import '../spaces/space.dart';
import '../spaces/spaces_service.dart';

/// Onglet Spaces : un Space regroupe des récepteurs (PC/TV exécutant déjà
/// « Recevoir une projection ») pour diffuser vers tous en un seul geste
/// depuis l'écran de projection, au lieu de se connecter un par un.
///
/// Construit sur la découverte/l'appairage direct déjà réels (voir
/// projection/discovery_service.dart et pairing_service.dart) — un Space
/// n'est qu'un groupement **local à cet appareil**, persistant entre les
/// lancements de l'app, pas une session partagée sur un serveur.
class SpacesTab extends StatefulWidget {
  const SpacesTab({
    super.key,
    this.spacesService = const SpacesService(),
    this.enableScanning = true,
    this.receiversOverride,
  });

  final SpacesService spacesService;

  /// Désactivé dans les tests : la découverte UDP réelle dépend du réseau de
  /// la machine qui exécute la suite.
  final bool enableScanning;

  final List<DiscoveredReceiver>? receiversOverride;

  @override
  State<SpacesTab> createState() => _SpacesTabState();
}

class _SpacesTabState extends State<SpacesTab> {
  List<Space> _spaces = const [];
  bool _loading = true;

  ReceiverScanner? _scanner;
  StreamSubscription<List<DiscoveredReceiver>>? _scanSubscription;
  List<DiscoveredReceiver> _discovered = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
    if (widget.receiversOverride != null) {
      _discovered = widget.receiversOverride!;
    } else if (widget.enableScanning) {
      unawaited(_startScanning());
    }
  }

  Future<void> _startScanning() async {
    final scanner = ReceiverScanner();
    _scanner = scanner;
    try {
      await scanner.start();
      _scanSubscription = scanner.receivers.listen((list) {
        if (mounted) setState(() => _discovered = list);
      });
    } catch (_) {
      // Découverte indisponible sur ce réseau : la liste reste simplement
      // vide, les Spaces déjà créés restent consultables.
    }
  }

  Future<void> _reload() async {
    final spaces = await widget.spacesService.list();
    if (!mounted) return;
    setState(() {
      _spaces = spaces;
      _loading = false;
    });
  }

  bool _isOnline(SpaceMember member) =>
      _discovered.any((r) => r.name.trim().toLowerCase() == member.key);

  Future<void> _createSpace() async {
    final name = await _promptName(context, title: 'Nouveau Space', initial: '');
    if (name == null || name.trim().isEmpty) return;
    await widget.spacesService.create(name.trim());
    await _reload();
  }

  Future<void> _renameSpace(Space space) async {
    final name = await _promptName(
      context,
      title: 'Renommer le Space',
      initial: space.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await widget.spacesService.rename(space.id, name.trim());
    await _reload();
  }

  Future<void> _deleteSpace(Space space) async {
    await widget.spacesService.delete(space.id);
    await _reload();
  }

  Future<void> _addToSpace(DiscoveredReceiver receiver) async {
    if (_spaces.isEmpty) {
      final created = await _promptName(
        context,
        title: 'Nouveau Space',
        initial: '',
        helperText: 'Aucun Space encore créé — donne-lui un nom.',
      );
      if (created == null || created.trim().isEmpty) return;
      final space = await widget.spacesService.create(created.trim());
      await widget.spacesService.addMember(
        space.id,
        SpaceMember(
          name: receiver.name,
          lastAddress: receiver.address,
          lastPairPort: receiver.pairPort,
        ),
      );
      await _reload();
      return;
    }
    final spaceId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ajouter « ${receiver.name} » à…',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final space in _spaces)
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: Text(space.name),
                onTap: () => Navigator.pop(context, space.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nouveau Space…'),
              onTap: () => Navigator.pop(context, '__new__'),
            ),
          ],
        ),
      ),
    );
    if (spaceId == null) return;
    var targetId = spaceId;
    if (spaceId == '__new__') {
      if (!mounted) return;
      final created = await _promptName(context, title: 'Nouveau Space', initial: '');
      if (created == null || created.trim().isEmpty) return;
      final space = await widget.spacesService.create(created.trim());
      targetId = space.id;
    }
    await widget.spacesService.addMember(
      targetId,
      SpaceMember(
        name: receiver.name,
        lastAddress: receiver.address,
        lastPairPort: receiver.pairPort,
      ),
    );
    await _reload();
  }

  Future<void> _removeMember(Space space, SpaceMember member) async {
    await widget.spacesService.removeMember(space.id, member.key);
    await _reload();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanner?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Un Space regroupe des récepteurs pour diffuser vers tous en un '
          'geste depuis l\'écran de projection (section « Spaces » du mode '
          'B). Local à cet appareil — pas de session partagée sur un '
          'serveur.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Récepteurs détectés', style: theme.textTheme.titleMedium)),
            FilledButton.tonalIcon(
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size.zero)),
              onPressed: _createSpace,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Space'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_discovered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Aucun récepteur détecté pour le moment. Ouvre « Recevoir une '
                'projection » sur le PC/TV cible, sur le même réseau Wi-Fi.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          )
        else
          ..._discovered.map(
            (r) => Card(
              child: ListTile(
                leading: const Icon(Icons.tv),
                title: Text(r.name),
                subtitle: Text(r.address),
                trailing: IconButton(
                  icon: const Icon(Icons.playlist_add),
                  tooltip: 'Ajouter à un Space',
                  onPressed: () => _addToSpace(r),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('Mes Spaces', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_spaces.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucun Space encore créé', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'Ajoute un récepteur détecté ci-dessus, ou crée un Space vide '
                  'avec le bouton « Space ».',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          ..._spaces.map((space) => _SpaceCard(
                space: space,
                isOnline: _isOnline,
                onRename: () => _renameSpace(space),
                onDelete: () => _deleteSpace(space),
                onRemoveMember: (member) => _removeMember(space, member),
              )),
      ],
    );
  }
}

Future<String?> _promptName(
  BuildContext context, {
  required String title,
  required String initial,
  String? helperText,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(helperText: helperText, hintText: 'Nom du Space'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.isOnline,
    required this.onRename,
    required this.onDelete,
    required this.onRemoveMember,
  });

  final Space space;
  final bool Function(SpaceMember) isOnline;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<SpaceMember> onRemoveMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onlineCount = space.members.where(isOnline).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(space.name, style: theme.textTheme.titleMedium),
                ),
                StatusPill(
                  label: '$onlineCount/${space.members.length} en ligne',
                  tone: onlineCount > 0 ? StatusTone.positive : StatusTone.neutral,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renommer')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            if (space.members.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Aucun membre. Ajoute un récepteur détecté ci-dessus.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ...space.members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        isOnline(m) ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: isOnline(m) ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis)),
                      IconButton(
                        iconSize: 18,
                        icon: const Icon(Icons.close),
                        tooltip: 'Retirer du Space',
                        onPressed: () => onRemoveMember(m),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
