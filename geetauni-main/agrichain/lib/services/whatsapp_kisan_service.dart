import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart';

class WhatsAppKisanService {
  static final WhatsAppKisanService _instance = WhatsAppKisanService._internal();
  factory WhatsAppKisanService() => _instance;
  WhatsAppKisanService._internal();

  static const String _botNumberKey = 'agrichain_whatsapp_bot_number';
  static const String defaultBotNumber = '918307165924'; // Default to configured gateway

  /// Gets the currently configured AgriChain WhatsApp Bot Phone Number (with country code, no +)
  Future<String> getBotNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_botNumberKey) ?? defaultBotNumber;
  }

  /// Sets or updates the official Bot phone number
  Future<void> setBotNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = number.replaceAll(RegExp(r'\D'), '');
    await prefs.setString(_botNumberKey, clean);
  }

  /// Generates the secure handshake payload for auto-login & attribution
  String generateHandshakePayload(FirestoreUser user) {
    final cleanPhone = (user.phone ?? '').replaceAll(RegExp(r'\D'), '');
    final location = user.location ?? 'Haryana';
    return '🌾 *AgriChain किसान खाता लिंक (Account Link)* 🌾\n\n'
        'नमस्ते! मेरा AgriChain खाता WhatsApp से लिंक करें:\n'
        '#UID:${user.id}\n'
        '#NAME:${user.name}\n'
        '#PHONE:$cleanPhone\n'
        '#LOC:$location\n\n'
        '⚠️ _यह संदेश भेजते ही आपकी फसलें सीधे आपके ऐप खाते में जुड़ेंगी।_';
  }

  /// Launches WhatsApp on the user's mobile device with the prefilled handshake
  Future<bool> launchConnectWhatsApp(FirestoreUser user) async {
    final botNumber = await getBotNumber();
    final message = generateHandshakePayload(user);
    final encodedMessage = Uri.encodeComponent(message);

    final Uri deepLink = Uri.parse('whatsapp://send?phone=$botNumber&text=$encodedMessage');
    final Uri webFallback = Uri.parse('https://wa.me/$botNumber?text=$encodedMessage');

    try {
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink, mode: LaunchMode.externalApplication);
        return true;
      } else if (await canLaunchUrl(webFallback)) {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: message));
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ WhatsApp launch error: $e');
      await Clipboard.setData(ClipboardData(text: message));
      return false;
    }
  }

  /// Launches WhatsApp for quick trade message
  Future<bool> launchTradeChat({String? prefillText}) async {
    final botNumber = await getBotNumber();
    final text = prefillText ?? '50 क्विंटल शरबती गेहूं करनाल भाव 2600';
    final encoded = Uri.encodeComponent(text);

    final Uri deepLink = Uri.parse('whatsapp://send?phone=$botNumber&text=$encoded');
    final Uri webFallback = Uri.parse('https://wa.me/$botNumber?text=$encoded');

    try {
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink, mode: LaunchMode.externalApplication);
        return true;
      } else if (await canLaunchUrl(webFallback)) {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check whether the farmer has already linked their WhatsApp in Firestore
  Stream<bool> isWhatsAppLinkedStream(String userId) {
    if (userId.isEmpty) return Stream.value(false);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return false;
          final data = doc.data();
          return (data?['isWhatsAppLinked'] == true || (data?['whatsappNumber'] != null && (data?['whatsappNumber'] as String).isNotEmpty));
        });
  }

  /// Get linked WhatsApp number for farmer
  Future<String?> getLinkedWhatsAppNumber(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['whatsappNumber'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting linked WhatsApp number: $e');
    }
    return null;
  }
}
