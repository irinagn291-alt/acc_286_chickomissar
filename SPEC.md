# Commissary — Build Specification

> Portfolio app 260, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Scan pantry tins, promise them to a cook day, and mark them finished when you use them.

| Field | Value |
| --- | --- |
| Product name | Commissary |
| Bundle identifier | `com.commissary.larder` |
| Domain | https://commissary-larder.pro |
| Contact URL | https://commissary-larder.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone (portrait, landscape left, landscape right) and iPad (all orientations) |
| Interface style | Light |
| Asset prefix | `cms_` |
| User-Agent | `Commissary/1.0 (iOS; +https://commissary-larder.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Commissary -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A household cook assigns each scanned pantry tin to a cook day, then finishes it on that day so best-before dates become scheduled commitments instead of surprise waste.

### 2.1 User flow

1. Open home and tap Assign on the seeded tin expiring in two days to seat it on today's cook-day row.
2. Scan a barcode, confirm best-before, and let the tin land on the use-soon ladder as Stock.
3. On cook day, tap Finish on an Assigned tin when it is actually used.
4. Open the Pantry sheet to cull Lapsed tins or edit a tin's package date.
5. Open Scan to search Open Food Facts when the barcode fails, then save the tin to the ladder.
6. Open Settings to export a CSV of assign and finish history or reset demo data.

### 2.2 Essential behaviour

- Use-soon ladder sorted by days-left with a cook-day ticket board overlay.
- Barcode scan, manual barcode entry, and bundled local shelf fallback without a WebView.
- Assign, Finish, and Waste marks with undo peel and EarlyMark when Finish is illegal.
- Local midnight rollover of past-date Stock or Assigned tins to Lapsed with Pantry cull.
- UserDefaults+Codable single-root Commissary store with debounced save after each mark.
- Settings CSV export of tin identity, dates, and marks with no macros or meal slots.

---

## 3. Uniqueness assignment for Commissary

| Axis | Assigned value |
| --- | --- |
| Architecture | **Commissary ADT fold (Stock | Assigned | Cleared); the board is a fold over Tins keyed by cookDaykey; Scan writes Stock Tin with packageDaykey; Assign writes AssignMark and folds Stock to Assigned; Finish writes FinishMark and folds Assigned to Cleared; Finish on Stock writes EarlyMark and is refused; Assign on Assigned writes DuplicateMark and is refused; midnight folds Stock or Assigned past packageDaykey to Lapsed; empty live board writes Blank** |
| UI approach | **SwiftUI Metal shaders · timeline** |
| Naming convention | **Commissary / day-ticket lexicon (Larder, Tin, CookDay, AssignMark, FinishMark, WasteMark, EarlyMark, DuplicateMark, Lapsed, Blank)** |
| File organization | **By commissary role (Larder, Tin, CookDay, AssignMark, FinishMark, WasteMark, Lapsed)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **atelier-zero · featured-stack · branded** |
| Typography | **Verdana** |
| Navigation pattern | **Larder-locked chrome (the cook-day ticket board and use-soon ladder never leave; Pantry and Scan arrive as sheets; assign and finish fuse on the focused Tin; Settings from gear; no tab bar)** |
| AI art style | **Paper cut origami collage · collage** |
| Functional twist | **Assign-then-finish (Assign writes AssignMark with cookDaykey and folds Stock to Assigned on that board row; Finish writes FinishMark and clears the tin; Finish on Stock is refused; a second Assign on the same Tin while Assigned is refused; midnight folds past-date Stock or Assigned to Lapsed; seed leaves one Stock tin on the ladder so Assign is the first live verb)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — pantry_expiry

**Core** — A household cook assigns each scanned pantry tin to a cook day, then finishes it on that day so best-before dates become scheduled commitments instead of surprise waste.

**Audience** — People who buy ahead, watch a use-soon pile grow, and need a dated cook-this-then promise—not calorie counting or meal-slot logging.

**User flow**

1. Open home and tap Assign on the seeded tin expiring in two days to seat it on today's cook-day row.
2. Scan a barcode, confirm best-before, and let the tin land on the use-soon ladder as Stock.
3. On cook day, tap Finish on an Assigned tin when it is actually used.
4. Open the Pantry sheet to cull Lapsed tins or edit a tin's package date.
5. Open Scan to search Open Food Facts when the barcode fails, then save the tin to the ladder.
6. Open Settings to export a CSV of assign and finish history or reset demo data.

**Essential features**

- Use-soon ladder sorted by days-left with a cook-day ticket board overlay.
- Barcode scan, manual barcode entry, and bundled local shelf fallback without a WebView.
- Assign, Finish, and Waste marks with undo peel and EarlyMark when Finish is illegal.
- Local midnight rollover of past-date Stock or Assigned tins to Lapsed with Pantry cull.
- UserDefaults+Codable single-root Commissary store with debounced save after each mark.
- Settings CSV export of tin identity, dates, and marks with no macros or meal slots.

**Twist** — Assign-then-finish fold (Stock | Assigned | Cleared). Home is the cook-day ticket board plus use-soon ladder. Scan writes a Stock Tin with packageDaykey. Assign writes AssignMark with cookDaykey and folds Stock to Assigned on that board row. Finish writes FinishMark and folds Assigned to Cleared. Waste writes WasteMark and clears without a cook-day claim. Finish on Stock writes EarlyMark and is refused—unit tests must reject Finish on Stock. A second Assign on the same Tin while Assigned writes DuplicateMark and is refused. At local midnight a Stock or Assigned Tin past packageDaykey folds to Lapsed on Pantry until cull. Undo peels the last AssignMark, FinishMark, or WasteMark. Simulator seed writes one Stock Tin on the ladder with two days left and leaves today's Assigned row empty so Assign is the first live verb before the first frame—not an empty rail and not already assigned. Home verb: assign-to-cook-day, not pull-the-face, not breach-the-seal, not chill-the-cell, and not log-a-calorie.

**Why this is not a repeat** — Gallipot is face-then-pull FIFO lots; Breakseal is breach-then-spend opened shelf life; Icebox is chill-then-thaw freezer states. This product commits expiring tins to a cook day before use—a scheduling verb on the expiry ladder—not qty peel, jar warp, freezer pause, or OFF macro slots.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Use-soon rail is home. Not Today macros.
- Invariant: Best-before → days left. Use-soon ordered by date. Mark used. No kcal, no slots.
- Never: OFF is allowed for identity, not for macros.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.
- Scan: AVFoundation + Vision; symbologies include `.qr`; digit runs 8–14 from QR/URL; UPC-A pad; Simulator chips + manual; stop session. Pre-permission CTA is Continue or Next (Guideline 5.1.1 — never Allow/Enable camera).
- OFF: `GET /api/v2/product/<code>.json`; decoder without `convertFromSnakeCase`; tappable Open Food Facts link (1.4.1).
- Mini-ref `FoodFlow (identity only)`: steal OFF product-by-barcode and search for identity. Home is the use-soon rail. Never Do not copy Today macros or meal slots. No wrapper. New types and layout — do not reskin.

### 3.1 Architecture contract

Commissary models pantry state as a deterministic ADT fold over `Tin` records across three live phases (`Stock | Assigned | Cleared`) plus a terminal `Lapsed` state and `Blank` when the board has no live tins. Scanning or choosing a product writes a `Stock` `Tin` stamped with its `packageDaykey` (`Int` in `YYYYMMDD` form) onto the use-soon ladder ordered by days remaining. The home verb is `assignToCookDay`: tapping Assign on a `Stock` tin appends an `AssignMark` carrying the target `cookDaykey` and folds that tin from `Stock` into `Assigned` on the corresponding `CookDay` ticket row. Tapping Finish on an `Assigned` tin appends a `FinishMark` and folds `Assigned` to `Cleared`, while tapping Waste appends a `WasteMark` and clears the tin without a cook-day claim. Illegal transitions are explicitly refused by the fold and unit-tested: calling Finish on an unassigned `Stock` tin records an `EarlyMark` and leaves the tin in `Stock`, calling Assign on an already `Assigned` tin records a `DuplicateMark` and is refused, and local midnight rollover folds any `Stock` or `Assigned` tin whose `packageDaykey` is past today into `Lapsed` until culled.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Home renders as a `featured-stack` under the `atelier-zero` DNA with a `TimelineView` and subtle SwiftUI Metal shader paper grain over the featured `CookDay` ticket board above the quiet use-soon ladder. The live metric using `.contentTransition(.numericText())` is the big days-left countdown badge and assigned ticket tally on the featured cook-day header as tins fold between `Stock`, `Assigned`, and `Cleared`. A single `UIImpactFeedbackGenerator(style: .medium)` haptic fires only when an `AssignMark` or `FinishMark` commit succeeds, with zero haptics on sheet presentation or navigation. Dragging or pressing a `Stock` tin toward a `CookDay` ticket row drives live interactive scale (`0.97` over `160ms` ease-out, gated to opacity-only when `accessibilityReduceMotion` is enabled) and highlights the target `CookDay` drop ticket before release.

### 3.3 Naming contract

Convention: Commissary / day-ticket lexicon (Larder, Tin, CookDay, AssignMark, FinishMark, WasteMark, EarlyMark, DuplicateMark, Lapsed, Blank).

Examples to follow: Larder, Tin, CookDay, AssignMark, FinishMark, WasteMark, EarlyMark, DuplicateMark, Lapsed, Blank

### 3.4 Dependency contract

Zero external dependencies (`None`): no Swift Package Manager entries, no CocoaPods, and no vendored third-party source. The target imports only system frameworks: `SwiftUI`, `UIKit`, `CoreGraphics`, `AVFoundation` (for `AVCaptureMetadataOutput` barcode and QR scanning), and `Foundation` (`URLSession` for Open Food Facts `/cgi/search.pl` and `/api/v2/product/<barcode>.json` identity lookups, plus `JSONEncoder`/`JSONDecoder` for `UserDefaults` persistence).

### 3.5 Navigation contract

Larder-locked chrome with no `TabView` and no root back button. Home (`UseSoon`) permanently anchors the `CookDay` ticket board and the use-soon `Stock` ladder; `Assign` and `Finish` controls fuse directly onto the focused `Tin` card on the board. `Pantry` (full inventory, `Lapsed` cull, and package date editor), `Scan` (camera barcode scanner, sample chips, and Open Food Facts identity search), and `Settings` (CSV export, demo reset, Open Food Facts source link, and support contact link) open as modal sheets with `0.96` to `1.0` scale-plus-fade transitions and explicit `Close` buttons.

### 3.6 Screen composition contract

Board-root UseSoon (Home holds the cook-day ticket board, use-soon ladder, and fused assign and finish; Pantry and Scan are sheets; Settings from gear; maps Pantry|UseSoon|Scan|Settings without TabView)

Four destinations mapped without a `TabView` (`UseSoon`, `Pantry`, `Scan`, `Settings`) and reachable via `-ReviewScreen` launch keys (`today`, `log`, `goals`, `pantry`, `scan`, `settings`) read once after onboarding completes: 1) `UseSoon` (Home / `today`): featured `CookDay` ticket board at top, use-soon `Stock` ladder sorted by days remaining below, inline fused `Assign`, `Finish`, `Waste`, and `Undo` peel actions, plus a full-page empty state (`Blank`) with cutout art and bottom full-width CTA when no tins exist. 2) `Pantry` (`log` / `pantry` sheet): full larder ledger grouped by `Assigned`, `Stock`, `Lapsed`, and `Cleared` history, with one-tap `Lapsed` cull and `packageDaykey` adjustment. 3) `Scan` (`scan` sheet): `AVCaptureMetadataOutput` camera preview (`.qr`, `.ean13`, `.ean8`, `.upce`), Simulator sample-barcode chips, manual 8-14 digit entry, debounced Open Food Facts `/cgi/search.pl` identity search with bundled local shelf fallback, and `packageDaykey` picker. 4) `Settings` (`goals` / `settings` sheet): cook-day horizon preferences, CSV history export of tin identity and marks, Simulator demo reset, tappable Open Food Facts attribution link (`https://world.openfoodfacts.org`), and tappable support contact URL.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By commissary role (Larder, Tin, CookDay, AssignMark, FinishMark, WasteMark, Lapsed)**

```
Commissary/
  Commissary/
  App/
    CommissaryApp.swift
    ThemeTokens.swift
    MetalPaperShader.metal
  Larder/
    LarderStore.swift
    LarderFold.swift
    LocalShelfCatalog.swift
    OpenFoodFactsClient.swift
  Tin/
    Tin.swift
    TinPhase.swift
    TinLadderRowView.swift
  CookDay/
    CookDay.swift
    UseSoonBoardView.swift
    CookDayTicketCard.swift
  AssignMark/
    AssignMark.swift
    AssignTicketControl.swift
  FinishMark/
    FinishMark.swift
    EarlyMark.swift
    DuplicateMark.swift
  WasteMark/
    WasteMark.swift
  Lapsed/
    Lapsed.swift
    PantrySheetView.swift
  Scan/
    BarcodeScannerView.swift
    ScanSheetView.swift
  Settings/
    SettingsSheetView.swift
    CSVExporter.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Pantry
A first-class screen for **Pantry**. Must render empty, populated and error states.

### 5.3 UseSoon
A first-class screen for **UseSoon**. Must render empty, populated and error states.

### 5.4 Scan
Live camera capture via AVFoundation + Vision `VNDetectBarcodesRequest`. Symbologies include `.qr` plus EAN/UPC. Extract 8–14 digit runs from QR/URL. 12-digit UPC-A → prefix `0`. Try every candidate before miss. Permission: Continue/Next only before the system alert (5.1.1 — never Allow/Enable camera). Denied routes to Settings. Simulator: chips + manual field. Cooldown 1.5–2 s; ignore the same payload while loading. `stopRunning` on disappear and background.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.
Tappable Open Food Facts link (https://world.openfoodfacts.org). A static OpenFoodFacts label fails 1.4.1.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


**Scan (camera families). Mechanics from the white book scanner — add `.qr`.**

Capture:
- AVFoundation session + Vision `VNDetectBarcodesRequest` (or `AVCaptureMetadataOutput` with the same set).
- Symbologies must include `.qr` plus `.ean13`, `.ean8`, `.upce` (Code 128/39/93 if the domain uses them). Linear-only misses QR packs and QR-encoded EANs.
- Permission: notDetermined → `requestAccess` (system alert is the first ask). A pre-screen is allowed only if the proceed button is **Continue** or **Next**.
- Guideline 5.1.1 reject: any CTA that directs the grant — `Allow camera`, `Enable camera`, `Grant camera`, `Allow camera access`, or a bare `Allow` / `Enable` / `Grant` on the button that calls `requestAccess`.
- Denied/restricted → copy + Open Settings (`UIApplication.openSettingsURLString`). Never a second Allow/Enable button.
- No capture device (Simulator): sample-code chips + mandatory manual field. Fully usable without a camera.
- Start the session on appear; `stopRunning` on disappear and on background.
- Cooldown 1.5–2.0 s after a decode. Skip frames (every 3rd is enough). Ignore the same payload while a lookup is in flight.
- Continuous autofocus / autoexposure when supported. `alwaysDiscardsLateVideoFrames`. Preview `resizeAspectFill`.

Payload (camera, typed, pasted URL):
- Keep digit runs of length 8–14. A QR/URL may be text — extract those runs; do not require the whole payload to be digits.
- 12-digit UPC-A → prefix `0`.
- Try every candidate before miss. EAN-8/13, UPC-A/E, QR carrying any of those.

**Open Food Facts. Mechanics from white food_reference.**

- Host: `https://world.openfoodfacts.org`
- Search: `GET /cgi/search.pl` with `search_terms`, `json=1`, `page`, `page_size`, `fields`.
- Product: `GET /api/v2/product/<barcode>.json` — dedicated lookup, not a search filter.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` — keys like `energy-kcal_100g` break.
- Nutriments: accept Double / Int / String; read `energy-kcal_100g` (and `energy_kcal_100g`); kcal = kcal100 ?? (kJ / 4.184).
- Search: debounce ~500 ms, cancel the previous `Task`, paginate. Empty query does not hit the network.
- `status == 0` → not found → manual entry, not a crash.
- Settings/About: tappable Open Food Facts link (`https://world.openfoodfacts.org`). A dead "OpenFoodFacts" label fails 1.4.1.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **PantryItem** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **atelier-zero · featured-stack · branded**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F7F1DE` | Screen background |
| `surface` | `#FAF7EC` | Cards, rows, sheets |
| `ink` | `#15140F` | Primary text and icons |
| `accent` | `#E94F37` | Primary action, key figure, progress fill |
| `muted` | `#68655B` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Commissary/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Verdana**

Verdana drives the `atelier-zero` typographic hierarchy with oversized single-word tactical headers and warm editorial legibility: display titles use bold custom-scaled `Verdana-Bold` with `.fixedSize(horizontal: false, vertical: true)` so headlines never clip, body copy sits at 17pt `Verdana` with generous line spacing on solid paper plates, and all days-left counts, `YYYYMMDD` day badges, and ticket tallies format strictly via Swift `FormatStyle` (`Text(daysLeft, format: .number.precision(.fractionLength(0)))`) and `@ScaledMetric` so AX5 Dynamic Type never truncates.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **18pt** for cards, sheets and primary surfaces; **8pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **material** — SwiftUI `Material` (`.regularMaterial` / `.thinMaterial`), reused everywhere a surface sits above another.

Primary control: **tinted glass** — primary chrome sits on a tinted translucent surface (`Material` plus the accent colour at low opacity), never plain flat colour.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI Metal shaders · timeline**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI Metal shaders · timeline** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **warm** (Warm soft: friendly radii, comfortable pad, one playful moment.)

Reference system: **atelier-zero** — steal rhythm and restraint, not their colours or logos.

Mood: **A magazine-grade, collage-driven visual system: warm paper canvas, surreal**.

Home rhythm (`featured-stack`, dense): One featured card, then a quiet list. No equal trio.

Warm soft: friendly radii, comfortable pad, one playful moment. Layout `featured-stack`, density dense. Kit 18/8, material, tinted glass. Palette recipe `branded`. Press scale 0.97, 140-180ms ease-out. Sheets scale 0.96 to 1 plus fade. Reduce Motion: opacity only. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Oversized single word, then silence. Reference type feel: warm.

Motion (`snap`): Press scale 0.97, 140-180ms ease-out. Sheets scale 0.96 to 1 plus fade. Reduce Motion: opacity only.

Voice (`tactical`): Status-first. Noun plus state. 'Scan failed. Try again.'

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- iPhone allows portrait, landscape left, and landscape right. iPad allows all
  four orientations. Keep both lists in the Info settings, and let a rotated
  screen scroll instead of clipping.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Every headline, amount, and button title is fully visible. Do not give display
  type a fixed height shorter than the font, and do not let a sibling with
  `maxHeight: .infinity` compress it. When the column is taller than the screen,
  scroll it. `.clipped()` frames an image cell; it never wraps text.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Spacing uses a base of 4: 4, 8, 12, 16, 20, 24, 32, 40, 48, in one `Spacing`
  enum next to `DesignTokens`. No other values.

**Keyboard**

- Decimal fields use `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with a `FormatStyle`, never `NumberFormatter` or
  `String(format:)`. Example:
  `Text(value, format: .number.precision(.fractionLength(0...1)))`.
  Group separators and decimal separators follow the locale.
- Whole units show no decimals. Measured values show at most one decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown values render as a dash or the word "unknown", never as 0.
- A changing metric uses `.contentTransition(.numericText(value:))` with the
  shared spring, on the same value the text shows.
- A custom drag, magnification, or rotation shows its in-flight value through
  `@GestureState` and `.updating`. The committed value changes in `.onEnded`.
- Loading rows use `.redacted(reason: .placeholder)` at the size they will have
  when the data arrives.
- A form with more than one field chains focus with an `@FocusState` enum.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- State changes use one shared spring token. A `PhaseAnimator` or
  `KeyframeAnimator` is only the single signature moment on a view, triggered
  by a value, never a loop on appear.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- The root screen has no back button. `.navigationTitle` is a screen name, never
  the product name. A back control titled with the app name is a defect: it
  reads as a button that returns to this same app.
- A sheet dismisses with Close and owns its stack. Do not push it onto a stack
  whose title is the product name.
- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- A ring or a gauge uses the same `lineWidth` for the track and the fill.
- Display type does not use `.minimumScaleFactor`. Adapt with `ViewThatFits`
  or `dynamicTypeSize.isAccessibilitySize`, and scroll the column.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.
- An actor method re-checks its state after every `await`. Do not force-unwrap
  a lookup that happened before the await. The value may be gone.
- Filter `CancellationError` out before showing error UI or retrying.
  Cancellation is a normal end, not a failure.
- Build streams with `AsyncStream.makeStream(of:)` or the throwing variant.
  Pass a bounded `bufferingPolicy`, and set `onTermination` so the producer
  stops when the consumer does.
- CPU work uses `@concurrent`. Do not run it on `@MainActor`. The scaffold does
  not turn on default main-actor isolation, so UI types still need an explicit
  `@MainActor`.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

`UserDefaults` + `Codable` single-root `LarderRecord` stored under key `cms.larder.v1` with a 250ms debounced save after every `AssignMark`, `FinishMark`, `WasteMark`, `EarlyMark`, `DuplicateMark`, or undo peel. On Simulator (`#if targetEnvironment(simulator)`), `cms.demo.v1` seeds once on first launch, marks onboarding complete, and writes a realistic larder (including a primary `Stock` tin expiring in two days with today's `CookDay` row open so `Assign` is immediately enabled on the first frame, plus three additional stocked and scheduled tins from the bundled local shelf).

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Commissary/1.0 (iOS; +https://commissary-larder.pro)` on every request. Never reuse another app's string.
Use the **/cgi/search.pl, page_size 20** search endpoint for this app.


---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- iPhone: portrait, landscape left, landscape right. iPad: all four orientations (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.food-and-drink`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Commissary uses the camera to scan product barcodes so you can add tins to your use-soon ladder with the correct best-before date.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.food-and-drink
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Assign-then-finish (Assign writes AssignMark with cookDaykey and folds Stock to Assigned on that board row; Finish writes FinishMark and clears the tin; Finish on Stock is refused; a second Assign on the same Tin while Assigned is refused; midnight folds past-date Stock or Assigned to Lapsed; seed leaves one Stock tin on the ladder so Assign is the first live verb)

Home is the `CookDay` ticket board paired with the use-soon ladder, governed by the `Stock | Assigned | Cleared` fold. Under `#if targetEnvironment(simulator)`, `cms.demo.v1` seeds a `Stock` tin expiring in two days (`packageDaykey` = today + 2) while leaving today's `CookDay` ticket row unassigned, ensuring the primary home verb (`Assign`) is live and enabled on the very first frame without an empty rail or pre-completed state. Tapping `Assign` writes an `AssignMark` with the chosen `cookDaykey` and folds the `Tin` from `Stock` to `Assigned` on that day's ticket; tapping `Finish` on that `Assigned` tin writes a `FinishMark` and folds it to `Cleared`. Unit tests enforce the guardrails: attempting `Finish` directly on a `Stock` tin appends an `EarlyMark` and is refused, attempting a second `Assign` on an already `Assigned` tin appends a `DuplicateMark` and is refused, and crossing local midnight (`Calendar.current.startOfDay`) folds any `Stock` or `Assigned` tin with `packageDaykey < todayDaykey` into `Lapsed` for Pantry culling. Tapping `Undo` peels the most recent `AssignMark`, `FinishMark`, or `WasteMark` and recomputes the board fold.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Paper cut origami collage · collage**


Base prompt, reused and extended for every asset:

```
Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors.
```

All 7 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `cms_` prefix.

### 13.1 App icon

Do not generate an app icon. Do not create an AppIcon image set and do not
paint icon artwork. The factory installs the icon later. Leave the empty
AppIcon.appiconset from the scaffold untouched.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `cms_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 2 | `cms_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 3 | `cms_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 4 | `cms_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 5 | `cms_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Assign-then-finish (Assign writes AssignMark with cookDaykey and folds Stock to Assigned on that board row; Finish writes FinishMark and clears the tin; Finish on Stock is refused; a second Assign on the same Tin while Assigned is refused; midnight folds past-date Stock or Assigned to Lapsed; seed leaves one Stock tin on the ladder so Assign is the first live verb)' feature screen. |
| 6 | `cms_EmptyLarderCutout` | 1024x1024 | **required cutout** | Paper cut origami collage illustration of an open wooden pantry crate with folded paper tin cans and a stamped day ticket tag, centered solid subject with crisp layered paper shadows and a fully transparent PNG background around the outer silhouette. |
| 7 | `cms_TicketStampEmblem` | 1024x1024 | **required cutout** | Paper cut origami collage illustration of a vintage kitchen date-stamp ticket and folded tin lid, tactile layered paper edges, solid centered composition with real transparent PNG alpha corners. |

### Prompt per asset

**`cms_Onboarding1`** — 1024x1536

```
Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors., a person or object that is this product in one glance

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cms_Onboarding2`** — 1024x1536

```
Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors., the primary action of this product, mid-gesture

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cms_Onboarding3`** — 1024x1536

```
Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors., a later moment when the product has accumulated meaning

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cms_EmptyHome`** — 1024x1024

```
Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors., a solid closed bowl, crate or folded cloth waiting to be used — ceramic, wood or fabric, fully opaque, not glass

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cms_TwistHero`** — 1024x1024

```
Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors., an emblem representing this app's signature feature

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cms_EmptyLarderCutout`** — 1024x1024

```
Paper cut origami collage illustration of an open wooden pantry crate with folded paper tin cans and a stamped day ticket tag, centered solid subject with crisp layered paper shadows and a fully transparent PNG background around the outer silhouette.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cms_TicketStampEmblem`** — 1024x1024

```
Paper cut origami collage illustration of a vintage kitchen date-stamp ticket and folded tin lid, tactile layered paper edges, solid centered composition with real transparent PNG alpha corners.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`cms.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.
- `AnyView`, or a `View.if` helper that applies modifiers conditionally.
- `Binding(get:set:)` built inline inside `body`.
- `GeometryReader` inside a lazy stack or a lazy grid.
- `@AppStorage` on an `@Observable` class. `@Query` outside a `View`.
- `MagnificationGesture` or `RotationGesture`. Use `MagnifyGesture` and
  `RotateGesture`.
- `String(format:)` or `NumberFormatter` for a number the UI shows. Use a
  `FormatStyle` on `Text`.


---

## 17. Tests

Add a unit test target `CommissaryTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Commissary/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Commissary -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.
- [ ] Do not add a watchOS app target. Apple Watch store images are fitted from the iPhone screenshots.

**Uniqueness**
- [ ] Architecture matches **Commissary ADT fold (Stock | Assigned | Cleared); the board is a fold over Tins keyed by cookDaykey; Scan writes Stock Tin with packageDaykey; Assign writes AssignMark and folds Stock to Assigned; Finish writes FinishMark and folds Assigned to Cleared; Finish on Stock writes EarlyMark and is refused; Assign on Assigned writes DuplicateMark and is refused; midnight folds Stock or Assigned past packageDaykey to Lapsed; empty live board writes Blank** with no leakage across layers.
- [ ] UI approach matches **SwiftUI Metal shaders · timeline**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Larder-locked chrome (the cook-day ticket board and use-soon ladder never leave; Pantry and Scan arrive as sheets; assign and finish fuse on the focused Tin; Settings from gear; no tab bar)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Verdana** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Commissary
xcodegen generate
xcodebuild build-for-testing -scheme Commissary -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.commissary.larder/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Commissary -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.commissary.larder/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Commissary -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.commissary.larder/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
