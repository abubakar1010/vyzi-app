import 'package:flutter/material.dart';

class OfferModel {
  final String title;
  final String subtitle;
  final String imagePath;
  final double monthlyCost;
  final double savings;
  final int savingsPercent;
  final bool hasIndustrialRate;
  final bool hasTaxBenefit;

  const OfferModel({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.monthlyCost,
    required this.savings,
    required this.savingsPercent,
    required this.hasIndustrialRate,
    required this.hasTaxBenefit,
  });
}

enum RequestStatus { processing, readyToSign, completed }

class RequestModel {
  final String title;
  final String subtitle;
  final RequestStatus status;
  final String date;
  final IconData icon;
  final Color iconColor;

  const RequestModel({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.icon,
    required this.iconColor,
  });
}
