import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum CustomButtonVariant {
  primary,
  secondary,
  outlined,
  text,
}

enum CustomButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final String? label; // Added for backward compatibility
  final bool small; // Added for backward compatibility
  final bool isOutlined; // Added for backward compatibility
  final bool isSmall; // Added for backward compatibility

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.label, // Added for backward compatibility
    this.small = false, // Added for backward compatibility
    this.isOutlined = false, // Added for backward compatibility
    this.isSmall = false, // Added for backward compatibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For backward compatibility, use the label if text is not provided
    final displayText = text.isNotEmpty ? text : label ?? 'Button';

    // For backward compatibility, determine size from small or isSmall
    final buttonSize = small || isSmall ? CustomButtonSize.small : size;

    // For backward compatibility, determine variant from isOutlined
    final buttonVariant = isOutlined ? CustomButtonVariant.outlined : variant;

    return _buildButton(
      text: displayText,
      size: buttonSize,
      variant: buttonVariant,
    );
  }

  Widget _buildButton({
    required String text,
    required CustomButtonSize size,
    required CustomButtonVariant variant,
  }) {
    switch (variant) {
      case CustomButtonVariant.primary:
        return _buildElevatedButton(
          text: text,
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          size: size,
        );
      case CustomButtonVariant.secondary:
        return _buildElevatedButton(
          text: text,
          backgroundColor: AppColors.secondary,
          textColor: Colors.white,
          size: size,
        );
      case CustomButtonVariant.outlined:
        return _buildOutlinedButton(
          text: text,
          size: size,
        );
      case CustomButtonVariant.text:
        return _buildTextButton(
          text: text,
          size: size,
        );
    }
  }

  Widget _buildElevatedButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required CustomButtonSize size,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: _getPadding(size),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 0) : null,
      ),
      child: _buildButtonContent(
        text: text,
        textColor: textColor,
        size: size,
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String text,
    required CustomButtonSize size,
  }) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: _getPadding(size),
        side: BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 0) : null,
      ),
      child: _buildButtonContent(
        text: text,
        textColor: AppColors.primary,
        size: size,
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required CustomButtonSize size,
  }) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: _getPadding(size),
        minimumSize: fullWidth ? const Size(double.infinity, 0) : null,
      ),
      child: _buildButtonContent(
        text: text,
        textColor: AppColors.primary,
        size: size,
      ),
    );
  }

  Widget _buildButtonContent({
    required String text,
    required Color textColor,
    required CustomButtonSize size,
  }) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _getIconSize(size)),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: _getFontSize(size),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _getFontSize(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return 14;
      case CustomButtonSize.medium:
        return 16;
      case CustomButtonSize.large:
        return 18;
    }
  }

  double _getIconSize(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.medium:
        return 20;
      case CustomButtonSize.large:
        return 24;
    }
  }

  EdgeInsets _getPadding(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CustomButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case CustomButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }
}
