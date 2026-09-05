import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/skeleton/skeleton.dart';
import '../../home_map/data/repositories/missing_pet_repository_impl.dart';
import '../../home_map/domain/entities/missing_pet_entity.dart';
import '../../home_map/domain/providers/nearby_pets_providers.dart';
import '../../home_map/presentation/pet_detail_skeleton.dart';
import '../../profile/domain/providers/profile_providers.dart';
import '../data/lost_pet_post_repository.dart';
import 'widgets/collar_marker_widget.dart' show PetImageEyedropperDialog;

const Color _kAccent = Color(0xFF0022FF);
final RegExp _kHexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// Owner-facing "Edit Report" screen for a lost-pet report (MD-39 /
/// UD-11). Covers the fields the product captures and the backend accepts on
/// `PATCH /missing-pets/{id}`: name, bounty, primary coat colour, and the
/// characteristics blob (traits + optional secondary colour). Species, location,
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EDIT REPORT',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
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
class _ResolveReport extends StatefulWidget {
  const _ResolveReport({required this.petId});

  final String petId;

  @override
  State<_ResolveReport> createState() => _ResolveReportState();
}

class _ResolveReportState extends State<_ResolveReport> {
  late Future<MissingPetEntity> _fetch;

  @override
  void initState() {
    super.initState();
    _fetch = MissingPetRepositoryImpl().getMissingPet(widget.petId);
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
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _fetch = MissingPetRepositoryImpl()
                          .getMissingPet(widget.petId);
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return EditReportForm(pet: snapshot.data!);
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

  late String _primaryColorHex;
  String? _secondaryColorHex;
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
    final secondary = chars['secondary_color']?.toString().trim();
    _secondaryColorHex =
        (secondary != null && _kHexColor.hasMatch(secondary.toUpperCase()))
            ? secondary.toUpperCase()
            : null;
  }

  String _seedPrimaryHex(MissingPetEntity pet, Map<String, dynamic> chars) {
    final fromColumn = pet.primaryColorHex?.toUpperCase();
    if (fromColumn != null && _kHexColor.hasMatch(fromColumn)) return fromColumn;
    final fromChars = chars['color']?.toString().toUpperCase();
    if (fromChars != null && _kHexColor.hasMatch(fromChars)) return fromChars;
    return '#D4AF37'; // same neutral default the create form starts from
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

  void _openColorPicker({required bool isSecondary}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PetImageEyedropperDialog(
        imageUrl: widget.pet.imageUrl,
        initialHex: isSecondary
            ? (_secondaryColorHex ?? '#FFFFFF')
            : _primaryColorHex,
        isSecondary: isSecondary,
        otherColorHex: isSecondary ? _primaryColorHex : _secondaryColorHex,
        onColorConfirmed: (hex) {
          setState(() {
            final upper = hex.toUpperCase();
            if (isSecondary) {
              _secondaryColorHex = upper;
            } else {
              if (_secondaryColorHex != null &&
                  upper == _secondaryColorHex!.toUpperCase()) {
                _secondaryColorHex = null;
              }
              _primaryColorHex = upper;
            }
          });
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
    characteristics['color'] = _primaryColorHex;
    characteristics['traits'] = traits.isNotEmpty ? traits : 'Standard';
    if (_secondaryColorHex != null) {
      characteristics['secondary_color'] = _secondaryColorHex;
    } else {
      characteristics.remove('secondary_color');
    }

    final patch = <String, dynamic>{
      'pet_name': _nameController.text.trim(),
      'bounty_amount': _isBountyMode ? _bountyAmount : 0.0,
      'primary_color_hex': _primaryColorHex,
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
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
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
                title: 'NAME',
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
                title: 'COAT COLOURS',
                icon: Icons.palette_outlined,
                child: _ColorTilesRow(
                  primaryHex: _primaryColorHex,
                  secondaryHex: _secondaryColorHex,
                  onPickPrimary: () => _openColorPicker(isSecondary: false),
                  onPickSecondary: () => _openColorPicker(isSecondary: true),
                  onClearSecondary: () =>
                      setState(() => _secondaryColorHex = null),
                ),
              ),
              _card(
                title: 'CHARACTERISTICS / TRAITS',
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
                title: 'BOUNTY & REWARD',
                icon: Icons.card_giftcard_outlined,
                child: _BountyEditor(
                  isBountyMode: _isBountyMode,
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
                  disabledBackgroundColor: Colors.grey.shade300,
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
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
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
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
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
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                  letterSpacing: 0.8,
                  color: Colors.black87,
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

/// Primary + secondary coat-colour tiles (mirrors `CollarMarkerWidget`'s look,
/// but drives local state instead of the create form provider).
class _ColorTilesRow extends StatelessWidget {
  const _ColorTilesRow({
    required this.primaryHex,
    required this.secondaryHex,
    required this.onPickPrimary,
    required this.onPickSecondary,
    required this.onClearSecondary,
  });

  final String primaryHex;
  final String? secondaryHex;
  final VoidCallback onPickPrimary;
  final VoidCallback onPickSecondary;
  final VoidCallback onClearSecondary;

  Color _parse(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        secondaryHex != null ? _parse(secondaryHex!) : null;
    return Row(
      children: [
        Expanded(
          child: _tile(
            onTap: onPickPrimary,
            borderColor: _kAccent,
            borderWidth: 2,
            swatch: _parse(primaryHex),
            label: 'PRIMARY',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tile(
            onTap: onPickSecondary,
            borderColor: secondaryColor != null
                ? Colors.teal
                : Colors.grey.shade300,
            borderWidth: secondaryColor != null ? 2 : 1.2,
            swatch: secondaryColor,
            label: secondaryColor != null ? 'SECONDARY' : 'NONE',
            trailing: secondaryColor != null
                ? GestureDetector(
                    onTap: onClearSecondary,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required VoidCallback onTap,
    required Color borderColor,
    required double borderWidth,
    required Color? swatch,
    required String label,
    Widget? trailing,
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: swatch == null
                  ? const Icon(Icons.block, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: swatch == null
                      ? Colors.grey.shade400
                      : Colors.black87,
                ),
              ),
            ),
            ?trailing,
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
    required this.controller,
    required this.onModeChanged,
    required this.onAdd,
  });

  final bool isBountyMode;
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
                label: 'HELP FREE',
                activeColor: Colors.green,
                onTap: () => onModeChanged(false),
              ),
              _modeButton(
                selected: isBountyMode,
                icon: Icons.monetization_on_outlined,
                label: 'BOUNTY',
                activeColor: Colors.orange,
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
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
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
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
                      return null;
                    },
                  ),
                ),
              ],
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
    required VoidCallback onTap,
  }) {
    return Expanded(
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
              Icon(icon, size: 18, color: selected ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
