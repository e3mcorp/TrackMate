import 'package:flutter/material.dart';
import 'package:trackmate/data/tracker.dart';

class SetupWizardData {
  // Controllers
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController pinController;
  final TextEditingController apnController;
  final TextEditingController apnUserController;
  final TextEditingController apnPasswordController;
  final TextEditingController serverHostController;
  final TextEditingController serverPortController;
  final TextEditingController batteryThresholdController;
  final TextEditingController updateMovingController;
  final TextEditingController updateStoppedController;

  // State variables
  String timezone;
  bool sending;
  bool useExistingConfig;
  final Tracker tracker;

  SetupWizardData({
    required this.nameController,
    required this.phoneController,
    required this.pinController,
    required this.apnController,
    required this.apnUserController,
    required this.apnPasswordController,
    required this.serverHostController,
    required this.serverPortController,
    required this.batteryThresholdController,
    required this.updateMovingController,
    required this.updateStoppedController,
    this.timezone = 'Central European Standard Time', // Default timezone
    this.sending = false,
    this.useExistingConfig = true,
    required this.tracker,
  });

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    pinController.dispose();
    apnController.dispose();
    apnUserController.dispose();
    apnPasswordController.dispose();
    serverHostController.dispose();
    serverPortController.dispose();
    batteryThresholdController.dispose();
    updateMovingController.dispose();
    updateStoppedController.dispose();
  }
}
