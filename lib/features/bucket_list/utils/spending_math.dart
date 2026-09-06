import 'package:flutter/material.dart';
import 'currency_formatter.dart';

enum EstimateRelation { under, over, matched }

class EstimateComparison {
  final EstimateRelation relation;
  final double amount;

  const EstimateComparison._(this.relation, this.amount);

  bool get hasRelation => relation != EstimateRelation.matched || amount != 0;
}

/// Compares an item's actual price against its estimated price.
/// Returns null when there is no actual price to compare.
EstimateComparison? compareEstimate(double estimated, double? actual) {
  if (actual == null) {
    return null;
  }
  final diff = actual - estimated;
  if (diff < 0) {
    return EstimateComparison._(EstimateRelation.under, -diff);
  }
  if (diff > 0) {
    return EstimateComparison._(EstimateRelation.over, diff);
  }
  return const EstimateComparison._(EstimateRelation.matched, 0);
}

String differenceLabel(BuildContext context, double estimated, double? actual) {
  final comparison = compareEstimate(estimated, actual);
  if (comparison == null) {
    return 'Not recorded';
  }
  final amount = formatCurrency(comparison.amount);
  switch (comparison.relation) {
    case EstimateRelation.under:
      return 'You saved $amount';
    case EstimateRelation.over:
      return '$amount over estimate';
    case EstimateRelation.matched:
      return 'You spent exactly the estimate';
  }
}
