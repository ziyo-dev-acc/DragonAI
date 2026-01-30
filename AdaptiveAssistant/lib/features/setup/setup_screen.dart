import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/android_bridge.dart';
import '../../core/storage/app_database.dart';

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Setup & Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _permissionTile(
            title: 'Microphone',
            permission: Permission.microphone,
          ),
          _permissionTile(
            title: 'Media (Images/Video)',
            permission: Permission.photos,
          ),
          ListTile(
            title: const Text('Folder access (PDF/Docs)'),
            subtitle: const Text('Pick a folder to index documents'),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              final result = await AndroidBridge.pickDocumentTree();
              if (result != null) {
                final items = await AndroidBridge.indexDocumentTree(result['uri'] as String);
                for (final item in items) {
                  await db.raw.insert('document_index', {
                    'name': item['name'],
                    'uri': item['uri'],
                    'modified_at': item['modifiedAt'],
                    'mime_type': item['mimeType'],
                  });
                }
              }
            },
          ),
          ListTile(
            title: const Text('Notification access'),
            subtitle: const Text('Enable Telegram notification reading'),
            trailing: const Icon(Icons.notifications_active),
            onTap: () => AndroidBridge.openNotificationAccess(),
          ),
          ListTile(
            title: const Text('Write system settings'),
            subtitle: const Text('Needed for brightness control'),
            trailing: const Icon(Icons.settings),
            onTap: () => AndroidBridge.openDisplaySettings(),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile({required String title, required Permission permission}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await permission.request();
      },
    );
  }
}
