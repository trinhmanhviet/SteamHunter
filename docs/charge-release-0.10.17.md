# Stationary charge release — 0.10.17

Reproduced directly in the user's already-running 0.10.16 hunt: the hunter was
on a platform, had adequate stamina, empty Resolve and route index 2 (three HUD
segments). Holds of 850 / 1400 / 2300 ms all raised the sword, then returned to
ready without a downswing. No movement input or app restart was used.

The route chose Sundering Fall even though its Resolve cost could not be paid.
Release cleared the charge before `start_action` rejected the unaffordable move.
A missed Sundering Fall also leaves this state: it spends Resolve on startup,
but the route reset used to happen only when a hit was confirmed.

Minimal correction: a fresh held charge resets an unfunded third route to the
ordinary Charged Hew; the buffered combo path selects the same fallback. Funded
Sundering Fall keeps its original cost and behavior. No art or animation changes.

The regression test failed with six assertions before the fresh-charge fix and
two assertions before the buffered-path fix. Both now pass. Seven native Godot
charge/input/combo/contact/recovery suites pass. Tests cover a missed finisher,
three hold lengths, an unfunded buffered finisher and a funded finisher.

After installation, the phone was tested in a fresh Moor hunt with three
stationary holds of the same lengths. Screenshots and recording show all three
downswings; no SCRIPT ERROR. The exact unfunded-third-route regression is verified
by the native test, rather than inferred from this fresh-hunt phone check.
The installed APK hash matches the release APK. Device results are recorded in
`charge-release-0.10.17-verification.json`.
