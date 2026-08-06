import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/transfer_provider.dart';

/// Content of the recipient-picker bottom sheet — pushed via
/// `showModalBottomSheet` from `TransferScreen`, not `Navigator.push`, so
/// it overlays Transfer with the bottom nav still visible underneath,
/// matching the mockup. Still has no Riverpod provider/notifier of its
/// own — loading + local search filtering is transient, one-shot UI
/// state, not ongoing feature state anything else needs to react to.
class RecipientPickerSheet extends ConsumerStatefulWidget {
  const RecipientPickerSheet({super.key});

  @override
  ConsumerState<RecipientPickerSheet> createState() =>
      _RecipientPickerSheetState();
}

class _RecipientPickerSheetState extends ConsumerState<RecipientPickerSheet> {
  List<Recipient>? _recipients;
  String? _errorMessage;
  String _query = '';

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

  List<Recipient> _filtered(List<Recipient> recipients) {
    if (_query.trim().isEmpty) return recipients;
    final query = _query.trim().toLowerCase();
    return recipients
        .where(
          (r) =>
              r.name.toLowerCase().contains(query) ||
              r.subtitle.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Recipient',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildList(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(ScrollController scrollController) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _load();
              },
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.accentBlue),
              ),
            ),
          ],
        ),
      );
    }

    final recipients = _recipients;
    if (recipients == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }

    final filtered = _filtered(recipients);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No contacts match.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipient = filtered[index];
        return RecipientCard(
          recipient: recipient,
          showChevron: false,
          onTap: () => Navigator.pop(context, recipient),
        );
      },
    );
  }
}
