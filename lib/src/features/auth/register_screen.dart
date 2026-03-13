import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'auth_page_scaffold.dart';
import 'auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _role = 'student';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Passwords do not match.'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthRepository().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Register'))),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Something went wrong'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      title: AppStrings.t('Register'),
      subtitle: AppStrings.t('Start your Learning Journey Today!'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppStrings.t('Full Name')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppStrings.t('Full Name')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: AppStrings.t('Email')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppStrings.t('Email is required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: AppStrings.t('Phone')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppStrings.t('Phone')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: AppStrings.t('Password')),
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Password is required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: AppStrings.t('Confirm Password')),
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Confirm Password')
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('Role'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.t('Student')),
                    selected: _role == 'student',
                    onSelected: (_) => setState(() => _role = 'student'),
                    selectedColor: AppColors.brand.withValues(alpha: 0.18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.t('Instructor')),
                    selected: _role == 'instructor',
                    onSelected: (_) => setState(() => _role = 'instructor'),
                    selectedColor: AppColors.brand.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting
                      ? AppStrings.t('Submitting')
                      : AppStrings.t('Sign Up'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                '${AppStrings.t('Already have an account?')} ${AppStrings.t('Login')}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
