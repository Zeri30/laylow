import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _infoMessage;
  DateTime? _memberSince;

  String get _email => Supabase.instance.client.auth.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('display_name, created_at')
          .eq('id', userId)
          .single();

      if (!mounted) return;
      setState(() {
        _displayNameController.text = row['display_name'] as String? ?? '';
        final createdAt = row['created_at'] as String?;
        _memberSince = createdAt == null ? null : DateTime.parse(createdAt);
      });
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Could not load your account. Please retry.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'display_name': _displayNameController.text.trim()})
          .eq('id', userId);

      if (!mounted) return;
      setState(() => _infoMessage = 'Saved.');
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your account',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            initialValue: _email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value != null && value.trim().length > 50) {
                                return 'Keep it under 50 characters';
                              }
                              return null;
                            },
                          ),
                          if (_memberSince != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Member since '
                              '${_memberSince!.year}-'
                              '${_memberSince!.month.toString().padLeft(2, '0')}-'
                              '${_memberSince!.day.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (_infoMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _infoMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
