import 'dart:async';

/// A photo upload that was kicked off at CAPTURE time and is awaited later, on
/// the verification screen.
///
/// Why this exists: the upload and the AI analysis are inherently sequential —
/// `POST /sightings/analyze` takes a URL, so the photo has to be in Storage
/// before analysis can start. The only way to make the user wait less is to
/// start uploading earlier. The shutter press is the earliest possible moment,
/// and it buys back the route transition, the verification screen's build, and
/// (on the targeted path) the entire time the user spends reading the confirm
/// dialog.
///
/// Awaiting [url] more than once is safe, and awaiting it after the upload has
/// already finished returns immediately.
class PendingUpload {
  PendingUpload(this._future) {
    // Nothing awaits `_future` between the shutter press and the verification
    // screen's initState. Without a listener attached right now, an upload that
    // fails inside that window is an unhandled async error, which Flutter
    // reports as a crash in the enclosing zone rather than as the error message
    // the verification screen is built to show. Attaching a no-op handler keeps
    // the failure dormant until someone actually awaits `url`.
    unawaited(_future.then<void>((_) {}, onError: (_, _) {}));
  }

  final Future<String> _future;

  /// The public Storage URL of the uploaded photo. Rethrows the upload's error
  /// to whoever awaits it.
  Future<String> get url => _future;
}
