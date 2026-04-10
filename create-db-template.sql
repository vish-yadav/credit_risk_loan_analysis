CREATE DATABASE project_risk
DEFAULT CHARACTER SET = 'utf8mb4';

use project_risk;
drop table if exists risk_data;

create table risk_data(
    application_id varchar(20),
    applicant_name varchar(20),
    age int,
    gender varchar(10),
    state varchar(20),
    employment_status varchar(20),
    annual_income float, 
    loan_amount_requested varchar(20),
    loan_purpose varchar(30),
    credit_score int,
    dti_ratio float,
    application_date date,
    num_dependents int,
    has_coborrower varchar(20),
    loan_term_months int,
    interest_rate_offered float,
    application_status varchar(20)
)

SHOW VARIABLES LIKE 'secure_file_priv';

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cleaned_csv.csv"
into table risk_data 
fields terminated by ',' 
optionally enclosed by '"' 
lines terminated by '\r\n'
 ignore 1 lines
 (application_id, applicant_name, age, gender, state, employment_status, 
 @temp_annual_income, loan_amount_requested, loan_purpose, credit_score, 
 @temp_dti, application_date, num_dependents, has_coborrower, loan_term_months, 
 interest_rate_offered, application_status)
SET dti_ratio = NULLIF(@temp_dti, ''),
annual_income = NULLIF(@temp_annual_income,'');

select* from risk_data limit 10;



#Q) ARE BANKS APPROVING THE LOAN THAT THEY SHOULDN'T?

    #1.The customers in this data with highest probability of defaulting on their loans are those with low credit scores. high dti_ratio and low annual income.
       #This query will help us to identify those customers who are at high risk of defaulting on their loans.
select application_id,applicant_name,annual_income,loan_amount_requested,loan_purpose,credit_score, dti_ratio, application_status 
from risk_data
where dti_ratio> 0.43
and credit_score < 700 
and annual_income < 50000 and application_status = 'Approved';

    #2.Expected loss:As this data has no pd,lgd and ead columns so filtering the risky customers
    #calculating the actual loss will also give a realistic image of expected loss.
select sum(loan_amount_requested* dti_ratio) as potential_loss
from risk_data
where dti_ratio> 0.43 
and credit_score < 700 
and annual_income < 50000 and application_status = 'Approved'; 
#============================================================================================
#["There were total 12(3.8%) such customers from 314 total approved loans
# who showed high-risky profile and total expected loss would be around '268671.04' rupees."]
#============================================================================================


    #3.Are customers with unstable income getting loan ? If yes, how many,for how long and what's their average loan amount?
select application_id, applicant_name, age, gender,
loan_amount_requested,employment_status, annual_income, loan_term_months,
avg(loan_amount_requested)over() as avg_loan_amount
from risk_data
where employment_status in ('Contract','Part-time','Unemployed') 
and application_status = 'Approved'and loan_term_months >24 ;
#=====================================================================
#["Around 78(approx. 25%) long term loans of total 314 approved loans 
   #were approved to customers with unstable income "]
#=====================================================================

    #4. Top 3 states with high risk customers
select state , count(credit_score)as cnt
from risk_data
where credit_score<650
group by state
order by cnt desc limit 3;
#===========================================================
#["NewYork city has the highest number of risky customers."]
#===========================================================

    #5. Are high risk borrowers getting lower interest rates? 
select application_id, applicant_name , credit_score , interest_rate_offered 
from risk_data
where credit_score<650 
and application_status='Approved' 
and interest_rate_offered<15;
#=============================================================
#["15%(49  of 314) of total approved loans are under charged"]
#=============================================================

# Q) Although the approval rate looks healthy lets check the risk profile.
#We are trying to find out that what is hidden in details.

    #1.Co-borrower loophole.Some borrower with coborrower seems like low risky customer but if they have low cibil and getting 
        #large amount of loan then it might be risky.

select application_id, applicant_name, credit_score, loan_amount_requested
from risk_data
where credit_score<650 and loan_amount_requested >30000 and has_coborrower = 'YES' and application_status = 'Approved' 
#========================================================================================
#["21%(67 of 314) of total approved loan has seen a possibility of co-borrower loophole"]
#========================================================================================
    

    #2.The high income generally means safe lending but someone with extremely high dti might be riskier. 
select application_id , applicant_name, dti_ratio,annual_income
from risk_data
where dti_ratio>0.5 and annual_income > 50000 and application_status='Approved'
#===========================================================================================================
#["Approx. 26%(84 of 314) of total approved loan belong to customers having high income and high dti ratio"]
#===========================================================================================================

    #3.The purpose-risk mismatch 
select application_id, applicant_name , interest_rate_offered
from risk_data
where loan_purpose = 'Debt consolidation' and interest_rate_offered <15 
#=====================================================================================================
#["Good news was the bank did not approve any loan to this category and kept pending or under-review."]
#=====================================================================================================


======================================
#RECOMMENDATIONS BASED ON ANALYSIS
======================================
#1. Implement a dual-trigger hard flag — any application where credit_score < 650 AND dti_ratio > 0.43 
    #This rule would have caught all 12 high-risk approvals in this portfolio before disbursement.

#2. Cap loan tenure at 36 months for any borrower outside full-time employment. A borrower with unstable income 
    #locked into a 60-84 month repayment is a slow-moving default. Income stability and loan tenure must be evaluated together, not independently.

#3. Any borrower with credit_score < 650 should have a minimum interest rate threshold 
    #applied automatically. Underpricing risk is as dangerous as approving the wrong borrower — the bank bears the risk without the return.

#4. Policy should require that the primary applicant independently meets minimum credit score requirements before coborrower income is considered.

#5. Replace income-only approval shortcuts with income-to-debt ratio as the primary filter. A borrower earning ₹2,00,000 annually but carrying 50%+
    #debt burden is not a safe borrower. Underwriting policy should mandate DTI evaluation as a non-negotiable step regardless of income level.

#SUMMARY : [""This portfolio's approval rate of 314 loans looks healthy. But beneath it, 25% carry unstable income risk, 21% show coborrower loophole signs, 
              #15% are mispriced, and ₹2,68,671 sits in loans that should have been flagged before approval. The data does not suggest the portfolio is broken 
              #— it suggests the underwriting rules have gaps that, if closed, would significantly improve risk-adjusted returns."""]