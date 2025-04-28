import 'package:flutter/material.dart';
import 'popup.dart';
import '../models/game_types.dart';

class ProvinceInfoPopup extends StatelessWidget {
  final Province province;
  final VoidCallback onClose;

  const ProvinceInfoPopup({
    super.key,
    required this.province,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Popup(
      title: province.name,
      width: 400,
      height: 500,
      onClose: onClose,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Population', value: province.population.toString()),
          _InfoRow(label: 'Gold Income', value: province.goldIncome.toString()),
          _InfoRow(label: 'Industry', value: province.industry.toString()),
          _InfoRow(label: 'Army', value: province.army.toString()),
          _InfoRow(label: 'Resource', value: province.resourceType.toString()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
} 