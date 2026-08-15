import 'package:flutter/material.dart';

/// Supported masking transformations for detected sensitive information.
enum PiiMaskMode {
  redact(
    id: 'redact',
    displayName: 'Redact',
    description: 'Replaces sensitive items with [REDACTED: TYPE]',
    icon: Icons.visibility_off_outlined,
  ),
  hash(
    id: 'hash',
    displayName: 'Salted Hash',
    description: 'Replaces with consistent SHA-256 hashes [HASH:xxxx]',
    icon: Icons.tag_outlined,
  ),
  anonymize(
    id: 'anonymize',
    displayName: 'Pseudo-Anonymize',
    description: 'Replaces with realistic dummy entities (User_01, 10.0.0.1)',
    icon: Icons.masks_outlined,
  );

  final String id;
  final String displayName;
  final String description;
  final IconData icon;

  const PiiMaskMode({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}
