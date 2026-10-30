# Beacon · changelog

Every change someone can notice in Beacon: the iPhone and Apple Watch apps, **Watch from iPhone** on the Mac and the
BeaconKit™ catalog. Newest day first, and each day's newest line first. The Turkish original is `CHANGELOG.beacon.md`.
Vorssaint's own log is `CHANGELOG.md`; Beacon is never written there.

## 2026-10-31

- **BeaconKit:** The catalog's setup on the Mac mini stands on its own: its own Caddy serves the site, tied to no
  other project's files, server or ports on the machine. It picks free ports itself when its own are taken, and posts
  the address to the "BeaconKit adresi" issue in `0x-d2/beacon-kit-runner` when it changes.
- **Development:** Agents start every piece of work from `custom` and send its PR to `custom`, even when Conductor
  shows the workspace another target branch.

## 2026-10-30

- **BeaconKit:** The catalog is now built from a separate private repo (`0x-d2/beacon-kit-runner` › Actions ›
  BeaconKit™); the home Mac mini's runner never joins the public repo, so nobody's pull request can reach the Mac.
- **Development:** On GitHub, Beacon now gathers on its own `custom` branch and `main` is an exact copy of Vorssaint;
  Vorssaint's news arrives on `custom` as a pull request every morning, and updates that change a workflow ask you
  first.
- **Development:** Working rules and a project map for agents: `AGENTS.md` and the `ref/` docs; this log, and a
  check that asks Claude Code, as it finishes, about changes the log doesn't cover yet.
- **iPhone:** The status dot that pulses while connecting no longer drifts off and stays somewhere else.
- **iPhone:** Settings › Privacy says the readings also go to the Apple Watch and that the Macs' keys never go to the
  watch.
- **Apple Watch:** A Mac complication for the watch face: CPU, memory, GPU or temperature, as a ring, corner, line or
  rectangle. It shows the last reading the watch had with its time, dims after 10 minutes, and opens that Mac when
  tapped.
- **Apple Watch:** Beacon on the Apple Watch: the Mac's eight readings in one list, each opening a page with the same
  rows as on the iPhone. The watch reaches the Mac through the iPhone; the iPhone must be nearby, Beacon needn't be
  open.
- **BeaconKit:** The catalog shows the Beacon iPhone app too: its components, screens and colours (each colour beside
  its Mac counterpart), in Turkish and English, dark and light.
- **Mac:** Paired phones are read from the keychain correctly; the list used to come back empty and Watch from iPhone
  never started listening.
- **iPhone:** A pairing link opened from outside the app (the Camera, a web page) shows the Mac's name and addresses
  and asks before it is saved. Another Mac with the same name and address is no longer removed.
- **iPhone:** Beacon, the iPhone app that watches the Mac: pairing by QR code, a dashboard, each reading's last four
  minutes as a chart with its details, Tailscale away from home, a sample Mac to try it without one. Turkish and
  English.
- **Mac:** Settings › Monitor › Watch from iPhone: a phone pairs by QR code, and the Mac sends its readings only to
  paired phones, encrypted with each one's own key, sampling only while a phone watches. Off by default.
- **BeaconKit:** The process row specimen writes its decimals in the render's language (a comma in Turkish).
- **BeaconKit:** The catalog shows the app's own pixels: every component and some surfaces photographed in Turkish and
  English, dark and light.
- **BeaconKit:** The BeaconKit™ catalog site: the app's colours, components, surfaces and inline values, each with the
  line that writes it; a "where do I change it" guide; "Not bırak" for revision notes.
