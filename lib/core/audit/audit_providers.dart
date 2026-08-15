/// Riverpod providers for the audit log (Feature 8).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/audit/audit_models.dart';
import 'package:text_data/core/audit/audit_repository.dart';
import 'package:text_data/core/audit/audit_service.dart';
import 'package:text_data/core/audit/audit_settings.dart';
import 'package:text_data/core/storage/storage_providers.dart';

/// The low-level repository. Most callers should use [auditServiceProvider]
/// instead.
final auditRepositoryProvider = FutureProvider<AuditRepository>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return AuditRepository(database.db);
});

/// The high-level audit service, wired to the repository and the enabled
/// setting.
final auditServiceProvider = FutureProvider<AuditService>((ref) async {
  final repository = await ref.watch(auditRepositoryProvider.future);
  final enabled = ref.watch(auditEnabledProvider);
  return AuditService(repository: repository, enabled: enabled);
});

/// On-demand chain verification result. Invalidate this provider to re-verify.
final auditChainStatusProvider = FutureProvider<AuditVerificationResult>((
  ref,
) async {
  final service = await ref.watch(auditServiceProvider.future);
  return service.verifyChain();
});
