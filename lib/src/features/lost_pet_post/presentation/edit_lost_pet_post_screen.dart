import 'package:flutter/material.dart';

import '../../../core/theme/app_glass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/adaptive/breakpoints.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import '../../home_map/domain/entities/missing_pet_entity.dart';
import '../../home_map/domain/providers/nearby_pets_providers.dart';
import '../../home_map/presentation/pet_detail_skeleton.dart';
import '../../profile/domain/providers/profile_providers.dart';
import '../domain/providers/lost_pet_post_repository_provider.dart';
import 'widgets/collar_marker_widget.dart' show PetImageEyedropperDialog;

const Color _kAccent = kBrandDeep;
final RegExp _kHexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');

// Swatch shown while a report has no coat colour. Display only, never sent.
const String _kNoColorSwatch = '#D0D0D0';

/// Owner-facing "Edit Report" screen for a lost-pet report. Covers the fields the product captures and the backend accepts on
/// `PATCH /missing-pets/{id}`: name, bounty, primary coat colour, and the
/// characteristics blob (traits). Species, location,
/// last-seen time and the photo are not editable here.
///
/// Closing a recovered case is deliberately NOT here — that stays on the Status
/// Tracker's "my pet came home" button, which also settles the sighting queue.
class EditLostPetPostScreen extends StatelessWidget {
  const EditLostPetPostScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDaylight,
      appBar: AppBar(
        backgroundColor: kDaylight,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit report',
          style: TextStyle(fontFamily: kDisplayFamily, fontSize: 20, fontWeight: FontWeight.w800, color: kInk),
        ),
        centerTitle: true,
      ),
      body: _ResolveReport(petId: petId),
    );
  }
}

/// Always fetches the report fresh from the backend before showing the form —
/// deliberately NOT `PetDetailResolver`, which prefers a possibly-stale
/// in-memory copy from the map list. Editing must start from the current DB
/// values, or a second edit would seed from what the owner saw last time.
class _ResolveReport extends ConsumerStatefulWidget {
  const _ResolveReport({required this.petId});

  final String petId;

  @override
  ConsumerState<_ResolveReport> createState() => _ResolveReportState();
}

class _ResolveReportState extends ConsumerState<_ResolveReport> {
  late Future<MissingPetEntity> _fetch;

  @override
  void initState() {
    super.initState();
    _fetch = ref.read(missingPetRepositoryProvider).getMissingPet(widget.petId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MissingPetEntity>(
      future: _fetch,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PetDetailSkeleton();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load this report.\n${snapshot.error ?? ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kInkMuted),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _fetch = ref
                          .read(missingPetRepositoryProvider)
                          .getMissingPet(widget.petId);
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return ContentWidth(child: EditReportForm(pet: snapshot.data!));
      },
    );
  }
}

/// The form itself, split out from the resolver so widget tests can pump it
/// with a seeded [MissingPetEntity] and a fake repository, no network.
class EditReportForm extends ConsumerStatefulWidget {
  const EditReportForm({super.key, required this.pet});

  final MissingPetEntity pet;

  @override
  ConsumerState<EditReportForm> createState() => _EditReportFormState();
}

class _EditReportFormState extends ConsumerState<EditReportForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _traitsController;
  late final TextEditingController _bountyController;

  // Null when the report has no coat colour. Nothing is sent until the owner
  // picks one, so a save never invents a colour that matching would read.
  String? _primaryColorHex;
  late bool _isBountyMode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    final chars = pet.characteristics;

    _nameController = TextEditingController(text: pet.petName);

    final rawTraits = chars['traits']?.toString().trim() ?? '';
    // "Standard" is the sentinel the create flow writes when the owner left
    // traits blank — show it back as empty, not as literal text to keep.
    _traitsController = TextEditingController(
      text: rawTraits == 'Standard' ? '' : rawTraits,
    );

    _isBountyMode = pet.bountyAmount > 0;
    _bountyController = TextEditingController(
      text: pet.bountyAmount > 0 ? pet.bountyAmount.toStringAsFixed(0) : '',
    );

    _primaryColorHex = _seedPrimaryHex(pet, chars);
  }

  String? _seedPrimaryHex(MissingPetEntity pet, Map<String, dynamic> chars) {
    final fromColumn = pet.primaryColorHex?.toUpperCase();
    if (fromColumn != null && _kHexColor.hasMatch(fromColumn)) return fromColumn;
    final fromChars = chars['color']?.toString().toUpperCase();
    if (fromChars != null && _kHexColor.hasMatch(fromChars)) return fromChars;
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _traitsController.dispose();
    _bountyController.dispose();
    super.dispose();
  }

  double get _bountyAmount =>
      double.tryParse(_bountyController.text.replaceAll(',', '')) ?? 0.0;

  void _openColorPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PetImageEyedropperDialog(
        imageUrl: widget.pet.imageUrl,
        initialHex: _primaryColorHex ?? _kNoColorSwatch,
        onColorConfirmed: (hex) {
          setState(() => _primaryColorHex = hex.toUpperCase());
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final pet = widget.pet;
    final traits = _traitsController.text.trim();

    // Start from the existing blob so keys we don't touch (breed, size,
    // markings, description...) survive the edit.
    final characteristics = Map<String, dynamic>.from(pet.characteristics);
    if (_primaryColorHex != null) {
      characteristics['color'] = _primaryColorHex;
    }
    characteristics['traits'] = traits.isNotEmpty ? traits : 'Standard';
    // The secondary colour is no longer offered; drop any value an older
    // build saved so it stops showing in the description.
    characteristics.remove('secondary_color');

    final patch = <String, dynamic>{
      'pet_name': _nameController.text.trim(),
      'bounty_amount': _isBountyMode ? _bountyAmount : 0.0,
      if (_primaryColorHex != null) 'primary_color_hex': _primaryColorHex,
      'characteristics': characteristics,
    };

    setState(() => _isSaving = true);
    try {
      await ref
          .read(lostPetPostRepositoryProvider)
          .updateLostPetPost(pet.id, patch);
      if (!mounted) return;
      // Owner's "My Posted" list re-fetches, and the map list is re-pulled so
      // the pet-detail view (which reads the in-memory nearby list first) no
      // longer shows the pre-edit name / bounty / colour.
      ref.invalidate(ownerPostsProvider);
      ref.read(nearbyPetsProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
      // Navigator.pop (not context.pop) so the create screen's pattern is
      // matched and go_router's push future still completes with `true`.
      Navigator.of(context).maybePop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: kBrandErrorDeep,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(
                title: 'Name',
                icon: Icons.text_fields_rounded,
                child: TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration("Pet's name"),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter pet name'
                      : null,
                ),
              ),
              _card(
                title: 'Coat colour',
                icon: Icons.palette_outlined,
                child: _ColorTile(
                  primaryHex: _primaryColorHex ?? _kNoColorSwatch,
                  onPickPrimary: _openColorPicker,
                ),
              ),
              _card(
                title: 'Marks and traits',
                icon: Icons.pets_outlined,
                child: TextFormField(
                  controller: _traitsController,
                  maxLines: 3,
                  decoration: _fieldDecoration(
                    'e.g., White patch on chest, friendly, responds to Luna',
                  ),
                ),
              ),
              _card(
                title: 'Reward',
                icon: Icons.card_giftcard_outlined,
                child: _BountyEditor(
                  isBountyMode: _isBountyMode,
                  minAmount: widget.pet.bountyAmount,
                  controller: _bountyController,
                  onModeChanged: (mode) => setState(() => _isBountyMode = mode),
                  onAdd: (amount) {
                    final next = _bountyAmount + amount;
                    setState(() =>
                        _bountyController.text = next.toStringAsFixed(0));
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  disabledBackgroundColor: kInkMuted.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const BusyButtonLabel(width: 120)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kInkMuted),
        filled: true,
        fillColor: kFieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInkMuted.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: kInk.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _kAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// The primary coat-colour tile (mirrors `CollarMarkerWidget`'s look, but
/// drives local state instead of the create form provider).
class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.primaryHex,
    required this.onPickPrimary,
  });

  final String primaryHex;
  final VoidCallback onPickPrimary;

  Color _parse(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return kBrandDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _tile(
      onTap: onPickPrimary,
      borderColor: _kAccent,
      borderWidth: 2,
      swatch: _parse(primaryHex),
      label: 'Main',
    );
  }

  Widget _tile({
    required VoidCallback onTap,
    required Color borderColor,
    required double borderWidth,
    required Color? swatch,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: swatch ?? Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: kInkMuted.withValues(alpha: 0.3)),
              ),
              child: swatch == null
                  ? const Icon(Icons.block, size: 16, color: kInkMuted)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: swatch == null
                      ? kInkMuted.withValues(alpha: 0.45)
                      : kInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HELP FREE / BOUNTY toggle + (bounty mode) amount field and quick-add chips.
/// A trimmed local-state version of `BountySectionWidget`.
class _BountyEditor extends StatelessWidget {
  const _BountyEditor({
    required this.isBountyMode,
    required this.minAmount,
    required this.controller,
    required this.onModeChanged,
    required this.onAdd,
  });

  final bool isBountyMode;

  /// The bounty the report already carries. It may be raised, never
  /// lowered, so a reward once set cannot be switched off either.
  final double minAmount;
  final TextEditingController controller;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<double> onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _modeButton(
                selected: !isBountyMode,
                icon: Icons.favorite,
                label: 'Points only',
                activeColor: kSuccessDeep,
                onTap: minAmount > 0 ? null : () => onModeChanged(false),
              ),
              _modeButton(
                selected: isBountyMode,
                icon: Icons.monetization_on_outlined,
                label: 'Bounty',
                activeColor: kBrandDeep,
                onTap: () => onModeChanged(true),
              ),
            ],
          ),
        ),
        if (isBountyMode) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: kFieldFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kBrandDeep,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                    validator: (value) {
                      if (!isBountyMode) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final parsed =
                          double.tryParse(value.replaceAll(',', ''));
                      if (parsed == null) return 'Invalid amount';
                      if (parsed < 0) return 'Bounty cannot be negative';
                      if (parsed < minAmount) {
                        return 'Cannot be lower than '
                            '฿${minAmount.toStringAsFixed(0)}';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          if (minAmount > 0)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'The reward can be raised, not lowered.',
                style: TextStyle(color: kInkMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _chip('+1,000', 1000),
              _chip('+5,000', 5000),
              _chip('+10,000', 10000),
            ],
          ),
        ],
      ],
    );
  }

  Widget _modeButton({
    required bool selected,
    required IconData icon,
    required String label,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    // A choice that is locked out (onTap null) is shown faded.
    return Expanded(
      child: Opacity(
        opacity: onTap == null && !selected ? 0.4 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? activeColor : kInkMuted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? activeColor : kInkMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, double amount) {
    return InkWell(
      onTap: () => onAdd(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kInk,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
