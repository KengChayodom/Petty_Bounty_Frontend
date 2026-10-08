/// The models of the bounty payment feature (Feature #6), read from the
/// backend's `/bounty` routes.
library;

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

DateTime? _time(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toUtc() : null;

/// One payment the owner submitted against a closed report.
class BountyPayment {
  const BountyPayment({
    required this.id,
    required this.status,
    required this.amount,
    this.slipImageUrl,
    this.referenceNo,
    this.createdAt,
    this.disputedAt,
  });

  final String id;

  /// `Pending_Verification` (awaiting confirmation), `Verified` (confirmed) or
  /// `Rejected`.
  final String status;
  final double amount;
  final String? slipImageUrl;
  final String? referenceNo;
  final DateTime? createdAt;
  final DateTime? disputedAt;

  bool get isAwaiting => status == 'Pending_Verification';
  bool get isConfirmed => status == 'Verified';
  bool get isRejected => status == 'Rejected';
  bool get isDisputed => disputedAt != null;

  /// The hunter may dispute within three days of submission.
  bool canDispute(DateTime now) =>
      isAwaiting &&
      !isDisputed &&
      createdAt != null &&
      now.toUtc().isBefore(createdAt!.add(const Duration(hours: 72)));

  factory BountyPayment.fromJson(Map<String, dynamic> j) => BountyPayment(
        id: '${j['id']}',
        status: '${j['status']}',
        amount: _num(j['amount']),
        slipImageUrl: j['slip_image_url'] as String?,
        referenceNo: j['reference_no'] as String?,
        createdAt: _time(j['created_at']),
        disputedAt: _time(j['disputed_at']),
      );
}

/// The payment state of one closed report, as its owner or returning hunter
/// sees it.
class BountyView {
  const BountyView({
    required this.petId,
    required this.role,
    required this.petStatus,
    required this.bountyAmount,
    required this.unpaid,
    this.foundAt,
    this.unpaidReferredAt,
    this.bountyUnpaid = false,
    this.hunterUsername,
    this.hunterPromptPay,
    this.payment,
  });

  final String petId;

  /// `owner` or `hunter`.
  final String role;
  final String petStatus;
  final double bountyAmount;

  /// "Found", a bounty above zero, and no payment awaiting or confirmed.
  final bool unpaid;
  final DateTime? foundAt;
  final DateTime? unpaidReferredAt;

  /// An Administrator closed the report with the bounty unpaid.
  final bool bountyUnpaid;
  final String? hunterUsername;

  /// The hunter's PromptPay number, given only to an owner who owes them and
  /// only when it is a Thai mobile number. Null means "payout details awaited".
  final String? hunterPromptPay;

  /// The latest payment, whatever its status.
  final BountyPayment? payment;

  bool get isOwner => role == 'owner';
  bool get isHunter => role == 'hunter';
  bool get isReferredUnpaid => unpaidReferredAt != null;

  /// The hunter may refer an unpaid report within three days of "Found".
  bool canReferUnpaid(DateTime now) =>
      unpaid &&
      !isReferredUnpaid &&
      foundAt != null &&
      now.toUtc().isBefore(foundAt!.add(const Duration(hours: 72)));

  factory BountyView.fromJson(Map<String, dynamic> j) => BountyView(
        petId: '${j['pet_id']}',
        role: '${j['role']}',
        petStatus: '${j['pet_status']}',
        bountyAmount: _num(j['bounty_amount']),
        unpaid: j['unpaid'] == true,
        foundAt: _time(j['found_at']),
        unpaidReferredAt: _time(j['unpaid_referred_at']),
        bountyUnpaid: j['bounty_unpaid'] == true,
        hunterUsername: j['hunter_username'] as String?,
        hunterPromptPay: j['hunter_promptpay'] as String?,
        payment: j['payment'] is Map<String, dynamic>
            ? BountyPayment.fromJson(j['payment'] as Map<String, dynamic>)
            : null,
      );
}

/// One report the caller returned the pet for, in their list of bounties.
class HunterBounty {
  const HunterBounty({
    required this.petId,
    required this.petName,
    required this.petStatus,
    required this.bountyAmount,
    this.imageUrl,
    this.paymentStatus,
  });

  final String petId;
  final String petName;
  final String petStatus;
  final double bountyAmount;
  final String? imageUrl;

  /// The latest payment's status, or null when the owner has not paid yet.
  final String? paymentStatus;

  factory HunterBounty.fromJson(Map<String, dynamic> j) => HunterBounty(
        petId: '${j['pet_id']}',
        petName: '${j['pet_name'] ?? ''}',
        petStatus: '${j['pet_status']}',
        bountyAmount: _num(j['bounty_amount']),
        imageUrl: j['image_url'] as String?,
        paymentStatus: j['payment_status'] as String?,
      );
}
