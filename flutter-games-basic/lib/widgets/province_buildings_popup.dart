import 'package:flutter/material.dart';
import 'popup.dart';
import '../models/game_types.dart';

class ProvinceBuildingsPopup extends StatelessWidget {
  final Province province;
  final VoidCallback onClose;

  const ProvinceBuildingsPopup({
    super.key,
    required this.province,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Popup(
      title: '${province.name} Buildings',
      width: 400,
      height: 500,
      onClose: onClose,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BuildingItem(
            name: 'Factory',
            description: 'Increases industry output',
            icon: Icons.factory,
            onBuild: () {},
          ),
          _BuildingItem(
            name: 'Market',
            description: 'Increases gold income',
            icon: Icons.store,
            onBuild: () {},
          ),
          _BuildingItem(
            name: 'Barracks',
            description: 'Increases army capacity',
            icon: Icons.security,
            onBuild: () {},
          ),
          _BuildingItem(
            name: 'University',
            description: 'Increases research points',
            icon: Icons.school,
            onBuild: () {},
          ),
        ],
      ),
    );
  }
}

class _BuildingItem extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final VoidCallback onBuild;

  const _BuildingItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            transform: Matrix4.translationValues(0, -2, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF6EC53E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF4A9E1C),
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onBuild,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Build',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 