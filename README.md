# Commissary

Commissary is a household larder for people who buy ahead. Each scanned tin gets a best-before date, then a cook day. Finish it on that day so the date is a promise, not a surprise in the back of the cupboard.

## Architecture

Pantry state is a deterministic fold over tin records, not a list the views mutate. A tin is Stock after a scan (`packageDaykey` in YYYYMMDD form), Assigned after an `AssignMark` that names a `cookDaykey`, and Cleared after a `FinishMark` or a `WasteMark`. The home board is that fold grouped into cook-day tickets, with the use-soon ladder ordered by calendar days left. Finish on Stock writes an `EarlyMark` and is refused. A second Assign while Assigned writes a `DuplicateMark` and is refused. At local midnight, Stock or Assigned whose package day is already past becomes Lapsed until Pantry culls it. If nothing live remains, the board is Blank.

This suits the product because the cook-day promise is a state change with illegal edges. Storing the phase as a free-form flag would let the log and the board disagree. The mark log is the source of truth, `LarderStore` is the only seam to `UserDefaults` key `cms.larder.v1` and the atomic Application Support file, and the screen reads `CookDayBoard`.

## Why someone would pick this

Assign, then finish. The home verb seats a tin on a cook-day ticket before it is used. Waste can clear a tin without that claim. Undo peels the last assign, finish, or waste. It is a scheduling verb on the expiry ladder, not a quantity peel, an opened-jar timer, or a freezer pause.

## Art

Style: paper cut origami collage. Section 13 assets are filled by a later generate step. Prompts:

Base, reused on every asset: Surreal magazine-grade paper cut origami collage (`atelier-zero`): layered tactile folded paper edges, crisp scissor-cut silhouettes, subtle paper grain relief, and dimensional shadows assembled as clean centered subject cutouts with real transparent PNG alpha corners and solid interiors.

- `cms_Onboarding1`: base prompt, a person or object that is this product in one glance. Cutout, 1024x1536.
- `cms_Onboarding2`: base prompt, the primary action of this product, mid-gesture. Cutout, 1024x1536.
- `cms_Onboarding3`: base prompt, a later moment when the product has accumulated meaning. Cutout, 1024x1536.
- `cms_EmptyHome`: base prompt, a solid closed bowl, crate or folded cloth waiting to be used. Cutout, 1024x1024.
- `cms_TwistHero`: base prompt, an emblem representing assign-then-finish. Cutout, 1024x1024.
- `cms_EmptyLarderCutout`: Paper cut origami collage illustration of an open wooden pantry crate with folded paper tin cans and a stamped day ticket tag, centered solid subject with crisp layered paper shadows and a fully transparent PNG background around the outer silhouette.
- `cms_TicketStampEmblem`: Paper cut origami collage illustration of a vintage kitchen date-stamp ticket and folded tin lid, tactile layered paper edges, solid centered composition with real transparent PNG alpha corners.

## How this differs

Gallipot peels FIFO lots. Breakseal spends opened shelf life. Icebox pauses freezer state. Commissary commits an expiring tin to a cook day before use. Open Food Facts is used for product identity only. Home is the ticket board and the use-soon ladder, with no meal slots and no calorie log.

## Build

```bash
cd apps/Commissary
xcodegen generate
xcodebuild build-for-testing -scheme Commissary -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

The app target has no third-party packages. Tokens live in `DesignTokens.swift` (Verdana, atelier-zero palette).
