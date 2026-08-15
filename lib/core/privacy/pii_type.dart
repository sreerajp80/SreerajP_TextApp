import 'package:flutter/material.dart';

/// Categories of sensitive personally identifiable information (PII) and
/// secret credentials detected by the Offline Privacy Shield.
enum PiiType {
  email(
    id: 'email',
    displayName: 'Email',
    icon: Icons.email_outlined,
    isHighRisk: true,
  ),
  phone(
    id: 'phone',
    displayName: 'Phone Number',
    icon: Icons.phone_outlined,
    isHighRisk: false,
  ),
  creditCard(
    id: 'creditCard',
    displayName: 'Credit Card',
    icon: Icons.credit_card_outlined,
    isHighRisk: true,
  ),
  ipAddress(
    id: 'ipAddress',
    displayName: 'IP Address',
    icon: Icons.lan_outlined,
    isHighRisk: false,
  ),
  jwtToken(
    id: 'jwtToken',
    displayName: 'JWT Token',
    icon: Icons.token_outlined,
    isHighRisk: true,
  ),
  awsKey(
    id: 'awsKey',
    displayName: 'AWS Access Key',
    icon: Icons.cloud_outlined,
    isHighRisk: true,
  ),
  privateKey(
    id: 'privateKey',
    displayName: 'Private Key',
    icon: Icons.lock_outlined,
    isHighRisk: true,
  ),
  apiKeySecret(
    id: 'apiKeySecret',
    displayName: 'API Key / Secret',
    icon: Icons.password_outlined,
    isHighRisk: true,
  );

  final String id;
  final String displayName;
  final IconData icon;
  final bool isHighRisk;

  const PiiType({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.isHighRisk,
  });
}
