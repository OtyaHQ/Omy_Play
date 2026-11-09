import 'package:flutter/material.dart';

/// Backwards-compatible wrapper for existing feature call sites.
///
/// Otya Media currently has no paid feature entitlement or advertisement
/// check. Every feature wrapped here remains available to the user. Keep this
/// transparent wrapper until all legacy call sites can be removed safely.
class ProGate extends StatelessWidget {
  const ProGate({
    super.key,
    required this.child,
    required this.featureName,
    this.featureDescription,
  });

  final Widget child;

  /// Retained for source compatibility with older callers.
  final String featureName;

  /// Retained for source compatibility with older callers.
  final String? featureDescription;

  @override
  Widget build(BuildContext context) => child;
}
