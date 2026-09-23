package com.fintech.wallet

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's Android biometric prompt requires a FragmentActivity host —
// plain FlutterActivity doesn't provide the AndroidX Fragment support it
// needs to show the prompt.
class MainActivity : FlutterFragmentActivity()
