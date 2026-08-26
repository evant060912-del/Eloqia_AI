import 'package:flutter/material.dart';

/// Centralized visual identity for Eloqia AI.
///
/// This class contains the complete color language used throughout
/// the application. Keeping colors here allows every screen to share
/// the same visual identity and makes future design evolution easier.
class AppColors {
  AppColors._();

  // ============================================================
  // 🌌 ELOQIA — DEEP SPACE BACKGROUND
  // ============================================================

  /// Main application background.
  static const Color background = Color(0xFF050817);

  /// Slightly lighter background layer.
  static const Color backgroundSecondary = Color(0xFF080D20);

  /// Elevated background used behind important sections.
  static const Color backgroundElevated = Color(0xFF0C132A);

  /// Deepest layer used for visual depth.
  static const Color backgroundDeep = Color(0xFF03050D);

  // ============================================================
  // 💎 ELOQIA — SURFACE SYSTEM
  // ============================================================

  /// Standard elevated surface.
  static const Color surface = Color(0xFF111A34);

  /// Higher elevation surface.
  static const Color surfaceElevated = Color(0xFF172341);

  /// Premium interactive surface.
  static const Color surfaceInteractive = Color(0xFF1B294B);

  /// Subtle translucent glass surface.
  static const Color glass = Color(0x14FFFFFF);

  /// Stronger glass layer.
  static const Color glassMedium = Color(0x1FFFFFFF);

  /// High-emphasis glass layer.
  static const Color glassStrong = Color(0x29FFFFFF);

  // ============================================================
  // 🪟 LIQUID GLASS
  // ============================================================

  /// Main glass border.
  static const Color glassBorder = Color(0x38FFFFFF);

  /// Strong glass border for highlighted components.
  static const Color glassBorderStrong = Color(0x5CFFFFFF);

  /// Soft internal glass highlight.
  static const Color glassHighlight = Color(0x18FFFFFF);

  /// Bright glass reflection.
  static const Color glassReflection = Color(0x26FFFFFF);

  /// Dark glass overlay.
  static const Color glassDark = Color(0x66030712);

  // ============================================================
  // 💎 ELOQIA — PRIMARY BRAND
  // ============================================================

  /// Main Eloqia cyan.
  static const Color primary = Color(0xFF00E5FF);

  /// Brighter cyan used for highlights.
  static const Color primaryBright = Color(0xFF5CF4FF);

  /// Deep cyan used for visual depth.
  static const Color primaryDeep = Color(0xFF0097A7);

  /// AI purple.
  static const Color secondary = Color(0xFF8B5CF6);

  /// Brighter AI purple.
  static const Color secondaryBright = Color(0xFFB79AFF);

  /// Deep AI purple.
  static const Color secondaryDeep = Color(0xFF5B21B6);

  /// Human warmth.
  static const Color warmth = Color(0xFFFFB86C);

  /// Futuristic electric blue.
  static const Color electricBlue = Color(0xFF2563EB);

  // ============================================================
  // ✨ AI AURA & LIGHT
  // ============================================================

  /// Main Eloqia glow.
  static const Color glow = Color(0x5200E5FF);

  /// Strong cyan aura.
  static const Color glowStrong = Color(0x7A00E5FF);

  /// AI purple aura.
  static const Color aura = Color(0x528B5CF6);

  /// Strong AI aura.
  static const Color auraStrong = Color(0x788B5CF6);

  /// Warm ambient light.
  static const Color warmthGlow = Color(0x4DFFB86C);

  // ============================================================
  // 📝 TEXT SYSTEM
  // ============================================================

  /// Primary text.
  static const Color textPrimary = Color(0xFFF8FAFF);

  /// Secondary text.
  static const Color textSecondary = Color(0xFFA8B3CF);

  /// Muted text.
  static const Color textMuted = Color(0xFF66728F);

  /// Extremely subtle text.
  static const Color textDisabled = Color(0xFF46516A);

  /// Text placed on bright primary surfaces.
  static const Color textOnPrimary = Color(0xFF031016);

  // ============================================================
  // 🚀 PROGRESSION
  // ============================================================

  /// Experience points.
  static const Color xp = Color(0xFFFFD54F);

  /// Learning streak.
  static const Color streak = Color(0xFFFF7043);

  /// Rewards.
  static const Color reward = Color(0xFFFFC107);

  /// Level progression.
  static const Color level = Color(0xFF00E5FF);

  /// Progress completion.
  static const Color progress = Color(0xFF00E676);

  // ============================================================
  // 🎓 LEARNING CATEGORIES
  // ============================================================

  /// Speaking and conversation.
  static const Color speaking = Color(0xFF00E5FF);

  /// Vocabulary.
  static const Color vocabulary = Color(0xFF8B5CF6);

  /// Grammar.
  static const Color grammar = Color(0xFFFF6B9D);

  /// Writing.
  static const Color writing = Color(0xFF00E676);

  /// Reading.
  static const Color reading = Color(0xFFFFB86C);

  /// Listening.
  static const Color listening = Color(0xFF60A5FA);

  /// Academic English.
  static const Color academic = Color(0xFFF59E0B);

  // ============================================================
  // 👩‍🏫 AI TUTOR
  // ============================================================

  /// Mia's primary visual identity.
  static const Color mia = Color(0xFF00E5FF);

  /// Mia's secondary aura.
  static const Color miaAura = Color(0xFF8B5CF6);

  /// Online / available state.
  static const Color online = Color(0xFF00E676);

  // ============================================================
  // ✅ SYSTEM STATES
  // ============================================================

  static const Color success = Color(0xFF00E676);

  static const Color warning = Color(0xFFFFC107);

  static const Color error = Color(0xFFFF5252);

  static const Color info = Color(0xFF60A5FA);

  // ============================================================
  // 🌑 SHADOWS
  // ============================================================

  /// Standard premium shadow.
  static const Color shadow = Color(0x99000000);

  /// Deeper shadow for floating elements.
  static const Color shadowDeep = Color(0xCC000000);

  // ============================================================
  // 🌫️ NEUTRAL TRANSPARENCY
  // ============================================================

  static const Color white05 = Color(0x0DFFFFFF);

  static const Color white08 = Color(0x14FFFFFF);

  static const Color white12 = Color(0x1FFFFFFF);

  static const Color white18 = Color(0x2EFFFFFF);

  static const Color black35 = Color(0x59000000);

  static const Color black55 = Color(0x8C000000);
}