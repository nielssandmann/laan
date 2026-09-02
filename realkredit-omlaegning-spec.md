# Specification: Danish Mortgage Refinancing Calculator (Interest-Only Conversion)

## Purpose

A tool that lets a homeowner model the financial consequences of converting
their current amortizing mortgage (realkreditlån) to an interest-only loan
(afdragsfrit lån) for a period of 5, 10, or 30 years, optionally withdrawing
extra equity at the same time, and investing part of the resulting cash
flow. Over a chosen time horizon, show how the homeowner's net wealth under
the "refinance" scenario compares to keeping the existing loan as-is.

Primary interface: a small number of sliders driving a live-updating
comparison (numbers + chart).

## Core comparison

Two scenarios are simulated month-by-month over a user-chosen horizon,
which is independent of and may exceed either loan's term:

**Scenario A — keep existing loan.** Amortizes normally over its own
remaining term, reaching a 0 balance naturally at term end.

**Scenario B — refinance to interest-only.** New loan principal = old
remaining balance + extra cash withdrawn + refinancing costs (if
financed rather than paid cash). The new loan is 100% interest-only for
its entire term (the slider value *is* the term — there is
no subsequent amortization phase). Its balance therefore stays flat at
the original new-loan principal until either the horizon ends, or the
term ends and it's redeemed in full as a single lump sum.

**Unified monthly mechanic, applied identically to both scenarios:**

- `baseline` = the original Scenario-A monthly payment (ydelse) at the
  moment of the refinancing decision, fixed for the whole horizon.
- `actual_payment(t)` = what that scenario's loan requires that month (0
  once its loan is gone — paid off in Scenario A, redeemed in Scenario B).
- `freed_cash(t) = max(0, baseline − actual_payment(t))`.
- Each month, `invested_share × freed_cash(t)` is added to that
  scenario's investment portfolio (see `invested_share` below). This
  means Scenario A also starts investing once its loan is paid off — it
  isn't paydown-only forever.

**The extra cash withdrawn in Scenario B** is split by the same
`invested_share`: that fraction is invested up front (added to the
portfolio at t=0), the rest is consumption. The loan principal grows by
the full withdrawal regardless of this split — the split only affects
what happens to the cash received.

**Net wealth(scenario, t) = −(loan balance at t) + (investment portfolio
value at t, net of tax).**

**Headline output**: Net wealth(B, t) − Net wealth(A, t) across the
horizon, plus any break-even/crossover points.

## Inputs

### Existing loan (Scenario A)
- Original principal (hovedstol), kr
- Remaining balance (restgæld), kr
- Remaining term (løbetid), years
- Interest rate (rente), annual %
- Bidragssats, annual %
- Current monthly payment (ydelse), kr/month

### New loan (Scenario B)
- Term / interest-only period — **continuous slider**, years (e.g. 1–30,
  not restricted to discrete steps like 5/10/30; this is the full loan
  term, see Core comparison)
- New interest rate, annual %
- New bidragssats, annual %
- Extra cash withdrawn (udbetaling udover restgæld) — **slider or numeric
  input**
- One-time refinancing costs (kursskæring, tinglysningsafgift,
  kurtage/rådgivning), kr, single user-entered amount
- Whether refinancing costs are financed into the new loan or paid cash —
  toggle

### Investment
- `invested_share`: share of available cash invested vs. spent as
  consumption — **single slider**, 0–100%, used everywhere "available
  cash" arises (monthly freed cash in both scenarios, and the one-time
  withdrawal in Scenario B)
- Expected annual return — **slider**, %
- Tax rate on investment return — **slider/input**, single flat
  user-defined rate (not Danish aktie-/kapitalindkomst brackets)

### Horizon
- Time horizon shown — **slider**, years (independent of loan terms)

## Outputs

- Headline net wealth difference (B − A) at the selected horizon
- Chart: net wealth of both scenarios over the full horizon
- Breakdown of Scenario B's net wealth into −loan balance vs.
  +investment portfolio
- Monthly cash flow comparison (old ydelse vs. new interest-only payment,
  amount invested)
- Break-even point(s), if any, within the horizon
- Total interest paid under each scenario, as a supporting number

## Hard constraints (do not deviate)

1. `invested_share` is a single slider used for both the monthly
   freed-cash mechanic (both scenarios) and the one-time withdrawal
   (Scenario B) — not scenario-specific, not split further.
2. The new loan is 100% interest-only for its whole term; that term is
   independent of the old loan's remaining term. No amortization phase
   is modeled for it.
3. If the horizon outlasts the new loan's term, it's redeemed as a lump
   sum at that point, not gradually paid down.
4. Once a scenario's loan balance reaches 0 (naturally in A, by
   redemption in B), its freed cash becomes the full `baseline` and
   continues flowing into `invested_share` for the rest of the horizon.
5. Tax on investment return is a single flat user-supplied rate.

## Out of scope

- Underlying property value / total household net worth
- Danish tax bracket progression (aktieindkomst/kapitalindkomst)
- Multiple simultaneous loans, F-kort/F-lang rate resets over time
- Bond-type-specific mechanics beyond the single refinancing-cost line
