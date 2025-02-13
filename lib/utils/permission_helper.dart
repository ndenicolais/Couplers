import 'dart:io';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission(
    BuildContext context, Function pickImage) async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdkVersion = androidInfo.version.sdkInt;

    // If SDK version is <= 32 (Android 12 or earlier)
    if (sdkVersion <= 32) {
      PermissionStatus filePermission = await Permission.storage.status;

      if (filePermission.isGranted) {
        pickImage();
      } else {
        filePermission = await Permission.storage.request();

        if (filePermission.isGranted) {
          pickImage();
        } else if (filePermission.isDenied) {
          if (context.mounted) {
            showErrorToast(
              context,
              AppLocalizations.of(context)!.storage_permission_error,
            );
          }
        } else if (filePermission.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    }
    // If SDK version is >= 33 (Android 13+)
    else {
      PermissionStatus filePermission = await Permission.photos.status;

      if (filePermission.isGranted) {
        pickImage();
      } else {
        filePermission = await Permission.photos.request();

        if (filePermission.isGranted) {
          pickImage();
        } else if (filePermission.isDenied) {
          if (context.mounted) {
            showErrorToast(
              context,
              AppLocalizations.of(context)!.storage_permission_error,
            );
          }
        } else if (filePermission.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    }
  }
}

Future<void> requestLocationPermission(
    BuildContext context, Function loadMarkers) async {
  PermissionStatus locationPermission = await Permission.location.request();

  if (locationPermission.isGranted) {
    loadMarkers();
  } else if (locationPermission.isDenied) {
    if (context.mounted) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!.location_permission_error,
      );
    }
  } else if (locationPermission.isPermanentlyDenied) {
    openAppSettings();
  }
}
