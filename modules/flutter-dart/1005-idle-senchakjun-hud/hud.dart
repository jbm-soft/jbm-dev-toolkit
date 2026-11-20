import 'package:flutter/material.dart';

import '../../core/level_curve.dart';
import '../../data/asset_paths.dart';
import '../theme.dart';
import 'portrait.dart';

class CurrencyChip extends StatelessWidget {
  const CurrencyChip({
    super.key,
    required this.icon,
    required this.value,
    this.color = AppTheme.gold,
    this.onPlusTap,
  });

  final Widget icon;
  final String value;
  final Color color;
  final VoidCallback? onPlusTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlusTap,
      child: Container(
        height: 28,
        padding: EdgeInsets.fromLTRB(6, 2, onPlusTap != null ? 4 : 9, 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 68),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
            if (onPlusTap != null) ...[
              const SizedBox(width: 4),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 상용 방치형 게임 스타일 상단 재화 HUD (계정 레벨·전투력 + 잔돈 + 별사탕 + 도토리)
class TopHud extends StatelessWidget {
  const TopHud({
    super.key,
    required this.leaderId,
    required this.level,
    required this.squadPower,
    required this.coins,
    required this.gems,
    required this.acorns,
    required this.xpProgress,
    this.titleEmoji = '🌱',
    this.rankAlert = false,
    this.vipActive = false,
    this.onTapProfile,
    this.onTapGems,
  });

  final String leaderId;
  final int level;
  final int squadPower;
  final int coins;
  final int gems;
  final int acorns;
  final double xpProgress;
  final String titleEmoji;
  final bool rankAlert;
  final bool vipActive;
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapGems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppTheme.cream.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.ink.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile, Title & Honor Ranking pill
          GestureDetector(
            onTap: onTapProfile,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 34,
                  padding: const EdgeInsets.fromLTRB(3, 2, 9, 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: vipActive ? AppTheme.pink : AppTheme.amber,
                      width: 1.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpriteActor(
                        assetPath: AssetPaths.character(leaderId),
                        size: 27,
                        showShadow: false,
                      ),
                      const SizedBox(width: 4),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$titleEmoji Lv.$level',
                                style: AppFonts.nunito(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  color: AppTheme.ink,
                                ),
                              ),
                              if (vipActive) ...[
                                const SizedBox(width: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3.5, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pink,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'VIP',
                                    style: AppFonts.nunito(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '⚔️${LevelCurve.formatCompact(squadPower)}',
                            style: AppFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: AppTheme.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (rankAlert)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyChip(
                      icon: Image.asset(
                        AssetPaths.coinCute,
                        width: 17,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                      value: LevelCurve.formatCompact(coins),
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 5),
                    CurrencyChip(
                      icon: Image.asset(
                        AssetPaths.starCandy,
                        width: 17,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                      value: LevelCurve.formatCompact(gems),
                      color: AppTheme.pink,
                      onPlusTap: onTapGems,
                    ),
                    const SizedBox(width: 5),
                    CurrencyChip(
                      icon: Image.asset(
                        AssetPaths.acorn,
                        width: 17,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                      value: LevelCurve.formatCompact(acorns),
                      color: AppTheme.mint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.accent = AppTheme.pink,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color accent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.panel.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// FittedBox 보호가 내장되어 어떠한 길이의 한글 텍스트도 절대 잘리지 않는 버튼
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppTheme.pink,
    this.icon,
    this.expanded = true,
    this.compact = false,
    this.height = 44,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool expanded;
  final bool compact;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final effColor = onPressed == null ? const Color(0xFFB5ACA6) : color;
    final effHeight = compact ? 34.0 : height;
    final child = Container(
      width: expanded ? double.infinity : null,
      height: effHeight,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: effColor,
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
        border: Border.all(color: Colors.white, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: effColor.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AppFonts.blackHanSans(
                fontSize: fontSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: GestureDetector(onTap: onPressed, child: child),
    );
  }
}
