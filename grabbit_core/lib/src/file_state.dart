/// File lifecycle states — from your GRABBIT spec.
/// Maps directly to FLUBBER motion/color tokens via the DesignBridge.
enum FileState {
  /// File is present, readable, no action pending.
  stable,

  /// File needs treatment: rename, move, unpack, choose target.
  adapting,

  /// User must decide: delete, keep, overwrite, choose app.
  actNow,

  /// Action blocked: permission, SAF, clipboard, app target, storage issue.
  failed,

  /// Last safe state restored after a failure.
  recovered;

  String get label => switch (this) {
        stable => 'Stable',
        adapting => 'Adapting',
        actNow => 'Act Now',
        failed => 'Failed',
        recovered => 'Recovered',
      };
}
