# Credit Risk Analysis — Loan Portfolio Audit
  This project analyzes 1,020 loan applications to identify
  hidden risk inside an approved loan portfolio.
  
## Problem statement
Are banks approving loans that they shouldn't be?
Are there any hidden issues in the portfolio that migh affect the bank?

## Tools Used
- Python (pandas) — data cleaning
- MySQL — risk analysis queries  
- Excel — summary visualization

## Key Findings
1. 12 loans (3.8%) showed highest risk profile —
   ₹2,68,671 in potential exposure
2. 25% of approved loans went to unstable income borrowers
   on long tenure loans
3. 15% of approved loans are underpriced for their risk
4. 21% show coborrower loophole signs
5. New York has highest concentration of risky approvals
6. One positive — no debt consolidation loan was
   mispriced. Underwriting got this right.

## Recommendations
1. Implement a dual-trigger hard flag — any application where credit_score < 650 AND dti_ratio > 0.43 
   This rule would have caught all 12 high-risk approvals in this portfolio before disbursement.
   
3. Cap loan tenure at 36 months for any borrower outside full-time employment. A borrower with unstable      income locked into a 60-84 month repayment is a slow-moving default. Income stability and loan tenure     must be evaluated together, not independently.

4. Any borrower with credit_score < 650 should have a minimum interest rate threshold 
   applied automatically. Underpricing risk is as dangerous as approving the wrong borrower — the bank       bears the risk without the return.

5. Policy should require that the primary applicant independently meets minimum credit score requirements    before coborrower income is considered.

6. Replace income-only approval shortcuts with income-to-debt ratio as the primary filter. A borrower        earning ₹2,00,000 annually but carrying 50%+ debt burden is not a safe borrower. Underwriting policy      should mandate DTI evaluation as a non-negotiable step regardless of income level.


## Files
notebooks — pandas data cleaning
sql — all analysis queries with comments
dashboard — visual summary
