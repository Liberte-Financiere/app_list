import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';

/// Vue d'accueil immersive à 2 étapes (Consentement puis Choix du profil utilisateur).
class OnboardingView extends StatefulWidget {
  final bool initialHasConsent;
  final Future<void> Function() onAcceptConsent;
  final Future<void> Function(String userName) onCompleteProfile;

  const OnboardingView({
    super.key,
    required this.initialHasConsent,
    required this.onAcceptConsent,
    required this.onCompleteProfile,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late int _currentStep;
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialHasConsent ? 1 : 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptConsent() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onAcceptConsent();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _currentStep = 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSubmitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.length < 2) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onCompleteProfile(trimmedName);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _currentStep == 0
                    ? _buildConsentStep(context)
                    : _buildProfileStep(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey<int>(0),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconContainer(
          icon: Icons.shield_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.consentTitle,
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.consentSubtitle,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark.withAlpha(120)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
            ),
          ),
          child: Text(
            AppStrings.consentBody,
            textAlign: TextAlign.justify,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: const Text(AppStrings.consentButtonAccept),
            onPressed: _isSubmitting ? null : _handleAcceptConsent,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey<int>(1),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconContainer(
            icon: Icons.badge_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.profileTitle,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.profileSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: AppStrings.profileInputLabel,
              hintText: AppStrings.profileInputHint,
              helperText: AppStrings.profileInputHelper,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameController,
                builder: (_, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    tooltip: 'Effacer',
                    onPressed: () => _nameController.clear(),
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return AppStrings.profileInputError;
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleSubmitProfile(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: const Text(AppStrings.profileButtonSubmit),
              onPressed: _isSubmitting ? null : _handleSubmitProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer({required IconData icon, required Color color}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }
}
