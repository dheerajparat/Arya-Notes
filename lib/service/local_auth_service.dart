import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

class LocalAuthResult {
  final bool didAuthenticate;
  final String? message;

  const LocalAuthResult._({required this.didAuthenticate, this.message});

  const LocalAuthResult.success() : this._(didAuthenticate: true);

  const LocalAuthResult.failure(String message)
    : this._(didAuthenticate: false, message: message);
}

class LocalAuthService {
  final LocalAuthentication _localAuthentication;

  LocalAuthService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  bool get requiresAppUnlock {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<LocalAuthResult> authenticate() async {
    if (!requiresAppUnlock) {
      return const LocalAuthResult.success();
    }

    try {
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return const LocalAuthResult.failure(
          'This device does not support biometric or screen lock authentication.',
        );
      }

      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: 'Unlock Arya to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        return const LocalAuthResult.success();
      }

      return const LocalAuthResult.failure(
        'Authentication was cancelled. Unlock Arya to continue.',
      );
    } on PlatformException catch (error) {
      return LocalAuthResult.failure(_messageForPlatformException(error));
    } catch (_) {
      return const LocalAuthResult.failure(
        'Local authentication failed. Please try again.',
      );
    }
  }

  Future<void> stopAuthentication() async {
    try {
      await _localAuthentication.stopAuthentication();
    } catch (_) {
      // Nothing to do if the platform cannot stop an in-progress request.
    }
  }

  String _messageForPlatformException(PlatformException error) {
    switch (error.code) {
      case auth_error.passcodeNotSet:
        return 'Set a device PIN, password, or pattern first, then try again.';
      case auth_error.notEnrolled:
        return 'Enroll a fingerprint or face unlock on this device, then try again.';
      case auth_error.notAvailable:
        return 'Local authentication is unavailable on this device.';
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return 'Too many failed attempts. Unlock the device once, then retry.';
      case auth_error.otherOperatingSystem:
        return 'Local authentication is not available on this platform.';
      default:
        return error.message ??
            'Local authentication failed. Please try again.';
    }
  }
}
