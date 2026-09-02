# Realkredit-omlægning: afdragsfrihed-beregner

A single-file, dependency-free HTML calculator that compares two scenarios for a Danish
mortgage over a chosen horizon: keeping the existing amortizing realkreditlån, or
converting to a fully interest-only (afdragsfrit) loan — optionally withdrawing equity
and investing part of the freed cash flow.

Published as an Artifact: https://claude.ai/code/artifact/96c72ed9-d120-49bc-96ec-1a52f3863175

## Files

- `realkredit-omlaegning.html` — the whole application: markup, CSS and JS in one file.
  No build step, no package manager, no external JS. Open it directly in a browser.
  The only external resource is the Google Fonts stylesheet.
- `realkredit-omlaegning-spec.md` — the original specification. Its **hard constraints**
  section is authoritative for the model; do not "fix" behaviour that it mandates.

The file is written to be publishable as an Artifact, so it deliberately has no
`<!doctype>`, `<html>`, `<head>` or `<body>` wrapper — `<title>`, the font `<link>` and
`<style>` sit at the top of the file. It still renders correctly as a local file.
Republish with the Artifact tool using the same file path to keep the URL.

## Model conventions

These are decisions layered on top of the spec. Changing one changes every headline
number, so change them deliberately.

- **Everything is after rentefradrag.** A single flat deduction rate (default 33 %)
  applies to renter *and* bidrag in both scenarios. `baseline` is the existing loan's
  after-fradrag ydelse in month 1, held fixed for the whole horizon. Freed cash is
  `max(0, baseline − payment after fradrag)`. Because scenario A's after-fradrag payment
  *rises* as its interest shrinks, A invests nothing until its loan is repaid — which is
  what the spec's constraint 4 describes.
- **The clamp is intentional.** When the interest-only payment exceeds `baseline` (large
  udbetaling, or a much higher rate), `max(0, …)` holds freed cash at zero and the excess
  monthly cost is charged nowhere, flattering the afdragsfri scenario. The user chose to
  keep this; the page raises a warning naming the monthly and cumulative amount instead.
  Do not silently "correct" it.
- **The existing loan is a flat annuity on (rente + bidrag)**, so its ydelse is constant.
  Real realkredit computes the annuity on rente and charges bidrag on the outstanding
  balance, giving a slowly falling payment. The flat form was chosen to match the spec's
  mental model. A user-entered ydelse is only a cross-check that warns on mismatch.
- **The new loan is 100 % interest-only for its whole term.** It is redeemed as a lump sum
  only when the horizon *strictly* outlasts the term. Redemption sells from the portfolio,
  paying tax on the year's untaxed gain pro rata; any shortfall becomes cash debt at a
  user-set borrowing rate, repaid out of the freed cash before anything is invested.
  Never a negative portfolio compounding at the equity return. The model does **not**
  refinance at term end, so a term shorter than the horizon means the whole balance must
  come out of the freed cash — this is the single biggest driver of bad-looking results.
- **Investment tax accrues annually** on the year's gain (lagerprincip), so "efter skat"
  is defined at every point in time. Deferred tax on the current year's gain is subtracted
  when reporting portfolio value and net wealth.
- **Monthly rates are `annual / 12`** throughout, for loans and for returns. Kurs 100 is
  assumed both on the new loan and on redeeming the old one.
- **Opsparing** is the share of freed cash that is *not* invested, plus the non-invested
  part of the udbetaling, minus omkostninger if paid in cash. It stays outside formue but
  is added into the headline Total, counted at nominal value — it does not compound.
- **Summary decomposition:** `opsparing + investeret + gæld = total`, exactly. `investeret`
  is portfolio *value* after tax; `gæld` is `−(restgæld + kontant gæld)`. Keep this
  identity intact — it is the summary's whole point.
- **Naming discipline:** *Investeret* = value of the investment; *Indbetalt* = amount paid
  in. Both appear on the page and must not be conflated.
- Out of scope by design: property value and belåningsgrad (so no 80 % LTV feasibility
  check), Danish tax brackets, multiple loans, rate resets, bond-specific mechanics.

## Code structure

All JS lives in one IIFE at the end of the file.

- `simulate(inputs)` — pure, no DOM. Returns `{rows, A, B, ydelseA, baseline, payB, be,
  beTot, …}`. Exposed as `window.simulate` for console testing. Each row carries
  `netA/netB`, `totA/totB` (net + opsparing) and full per-scenario snapshots in `a` and
  `b` (`net, bal, debt, pf, cons, rente, bidrag, fradrag, inv`), all cumulative — the
  yearly tables take deltas between snapshots rather than accumulating separately.
- `drawChart(sim, kA, kB)` — SVG line chart; the key pair selects formue vs formue+opsparing,
  driven by the segmented control (`measure`).
- `drawBars(last)` — the summary bars, built as HTML/CSS, not SVG: inside a scaled viewBox
  the labels rendered around 6px and negative totals collided with their own bar. Signed
  stacking — positives run right of zero, negatives left, tick marks the total.
- `render()` — reads inputs, runs the model, fills headline, summary, warnings, all three
  tables, then draws. Every input re-runs it; there is no state beyond `measure`.

## Design

- Palette: teal `#008573` (behold lånet) and copper `#BE5518` (afdragsfrit) in light,
  `#12A08A` / `#D06E32` in dark. These pairs were validated for colour-vision deficiency
  separation, lightness band, chroma and contrast against the page surfaces — re-validate
  before substituting anything.
- Within a bar, one hue carries three treatments: hatch = opsparing, tint = investeret,
  solid = gæld. Identity never rests on colour alone; a legend and the table repeat it.
- Type: Newsreader (display), IBM Plex Sans (UI), IBM Plex Mono with tabular figures for
  every number.
- Themes: light values on bare `:root`, dark redefined under both
  `@media (prefers-color-scheme: dark)` (guarded `:root:not([data-theme="light"])`) and
  `:root[data-theme="dark"]`. Define colours as tokens only — never give a colour its sole
  definition inside a media or `[data-theme]` block.
- UI copy is Danish throughout, using the domain's own terms (restgæld, bidragssats,
  ydelse, kurs, rentefradrag).

## Verifying a change

Open the file in a browser and, in the console:

- `simulate` sanity: the derived ydelse must match an independent annuity calculation, and
  scenario A's balance must reach 0 exactly at its term end.
- The no-op case — identical rates, no udbetaling, no omkostninger, 0 % invested, both
  terms equal — must leave B behind by exactly the un-amortized principal.
- `opsparing + investeret + gæld − total` must be 0 for both scenarios, including after a
  redemption with a shortfall.
- Redemption edge cases: horizon shorter than the term (no redemption), horizon longer
  (redemption), and a portfolio too small to cover it (cash debt, never a negative
  portfolio).
- Sweep every slider end to end and confirm no `NaN`, and that the warnings fire when they
  should: afdragsfri ydelse above baseline, underdækning at indfrielse, ydelse mismatch,
  and a horizon reaching past both loans.
- Check both themes and a narrow viewport; wide tables must scroll inside their own
  container without the page body scrolling sideways.
