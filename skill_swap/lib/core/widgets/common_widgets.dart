import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

ImageProvider? avatarImageProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('data:')) {
    final base64Str = photoUrl.contains(',')
        ? photoUrl.split(',').last
        : photoUrl;
    try {
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(photoUrl);
}

/// Renders a CircleAvatar that handles both http URLs and base64 data URIs.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final Color? bgColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 20,
    this.bgColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final image = avatarImageProvider(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor ?? AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: image,
      child: image == null
          ? Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style:
                  textStyle ??
                  TextStyle(
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            )
          : null,
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final Widget? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [icon!, const SizedBox(width: 8), Text(label)],
          )
        : Text(label);

    Widget button;
    if (outlined) {
      button = OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      );
    } else {
      button = ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      );
    }

    // Wrap with ConstrainedBox to prevent infinite width
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400, // Maximum width for the button
        minHeight: 52,
      ),
      child: button,
    );
  }
}

class AppTextField extends StatelessWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class SkillChip extends StatelessWidget {
  final String label;
  final bool removable;
  final VoidCallback? onRemove;
  final Color? bgColor;
  final Color? textColor;

  const SkillChip({
    super.key,
    required this.label,
    this.removable = false,
    this.onRemove,
    this.bgColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.tagBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? AppColors.tagText,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (removable) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: textColor ?? AppColors.tagText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MatchBadge extends StatelessWidget {
  final int percent;
  const MatchBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80 ? AppColors.matchHigh : AppColors.matchMed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$percent% Match',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
