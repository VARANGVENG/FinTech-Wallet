import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/transfer_provider.dart';

/// Shows the list of contacts a user can pick as a transfer recipient.
/// Deliberately has no Riverpod provider/notifier of its own — this is a
/// one-shot "load a list, tap one, pop back with the result" screen, not
/// ongoing feature state anything else needs to react to, so plain local
/// `setState` is enough rather than inventing a notifier just for this.
class RecipientPickerScreen extends ConsumerStatefulWidget {
  const RecipientPickerScreen({super.key});

  @override
  ConsumerState<RecipientPickerScreen> createState() => _RecipientPickerScreenState();
}

class _RecipientPickerScreenState extends ConsumerState<RecipientPickerScreen> {
  List<Recipient>? _recipients;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(transferRepositoryProvider);
      final recipients = await repository.getRecipients();
      if (!mounted) return;
      setState(() => _recipients = recipients);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not load contacts.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Select Recipient',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _load();
              },
              child: const Text('Retry', style: TextStyle(color: AppColors.accentBlue)),
            ),
          ],
        ),
      );
    }

    final recipients = _recipients;
    if (recipients == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: recipients.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        return RecipientCard(
          recipient: recipient,
          showChevron: false,
          onTap: () => Navigator.pop(context, recipient),
        );
      },
    );
  }
}