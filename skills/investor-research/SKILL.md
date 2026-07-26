---
name: investor-research
description: Structure read-only equity, macro, valuation, earnings, crypto, and prediction-market research using live sources and optional server-side tools. Never use for autonomous trading.
---

# Investor Research

Use live data for prices, filings, earnings, ownership, macro series, and material news. Use `research-router` for evidence collection and `toolbox` for approved specialist databases.

## Workflow

1. Define security, market, currency, time horizon, and the decision being evaluated.
2. Establish a factual baseline: business, financials, valuation, balance sheet, catalysts, and risks.
3. Separate reported facts, consensus assumptions, and your own estimates.
4. Identify the main contradiction and the 1–3 variables that drive the conclusion.
5. Run a downside case and a falsification check before making a recommendation.
6. Give a concrete action or monitoring plan with dates and thresholds where appropriate.

For pharma or biotech assumptions, use `pharma-research` for clinical and regulatory evidence before valuation.

## Output

Lead with conclusion, confidence, main contradiction, and what would change the view. Cite dated sources near claims. Distinguish price facts from valuation judgments.

All brokerage and exchange access is read-only by default. Never place an order, move cash, expose account data, or use trading credentials unless the user explicitly requests the exact action and separately confirms it.
