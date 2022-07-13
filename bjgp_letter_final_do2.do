ssc install asdoc, replace
ssc install reformat, replace
clear
** DATA LOADING / CLEANING ***
cd "C:\Users\peter\OneDrive - University of Bristol\NHS data\final"

log using bjgp_final.log, replace
*file from https://files.digital.nhs.uk/6F/0794D8/gp-reg-pat-prac-all.csv 
import delimited "gp-reg-pat-prac-all.csv"
rename code prac_code
rename number_of_patients no_of_pts
keep prac_code no_of_pts
save no_of_pts.dta, replace

clear

** deprivation data from https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id?indicator_ids=93553&child_area_type_id=7
*value is 93553 score = Deprivation score (IMD 2019) English Indices of Deprivation 2019 from https://fingertips.phe.org.uk/profile/general-practice
*this data only includes practices with at least 750 patients
import delimited "indicator-data.csv"
rename value imd_value
label var imd_value "Deprivation score (IMD 2019) from https://fingertips.phe.org.uk/api#/"
*drops England totals
drop if areacode == "E92000001"
sum imd_value
xtile imd_decile = imd_value, n(10)
label var imd_decile "Deciles created from cutting data in stata using xtile n=10"
tab imd_decile

*checking data my practice checking most deprivated
list imd_decile if areacode == "L81054"
*10 = most deprived*
*profile https://fingertips.phe.org.uk/profile/general-practice/data#page/12/ati/7/are/L81054

*practice i used to work at CMC should be second least deprived = group 2
list imd_decile if areacode == "L81040"
*A random practice K83055 should be least deprived = group 1
list imd_decile if areacode == "K83055"
*all pass above testing

rename areacode prac_code
keep prac_code imd_value imd_decile
save prac_dep.dta, replace


clear

import delimited "GPPS_2021_Practice_data_(unweighted)_(csv)_PUBLIC.csv"
keep practice_code	practice_name	stp_code	stp_name	cr_code	cr_name	ccg_code	ccg_name	distributed	received	resprate q18_12 q18base	q18_12pct 	q28base q28_12 q28_12pct	q30_recoded_1pct	q112_1pct	q112_2pct	q112_3pct	q112_4pct	q49_1pct	q48_merged_1pct	q48_merged_2pct	q48_merged_3pct	q48_merged_4pct	q48_merged_5pct	q48_merged_6pct	q48_merged_7pct	q48_merged_8pct	q48_merged_9pct 
rename practice_code prac_code

label variable	prac_code	"Practice code"
label variable	practice_name	"Practice name"
label variable	stp_code	"STP Code from NHS datasets"
label variable	stp_name	"STP Name"
label variable	cr_code	"Commissioning Region Code"
label variable	cr_name	"Commissioning Region Name"
label variable	ccg_code	"CCG code"
label variable	ccg_name	"CCG Name"
label variable	distributed	"Total survey forms distributed"
label variable	received	"Total completed forms received"
label variable	resprate	"Response rate"
label variable	q18_12pct	"Overall experience of making an appointment - % Summary result - Good (Combined 'very good' and 'fairly good' responses, to be used with base for total base)"
label variable	q28_12pct	"Overall experience of GP practice - % Summary result - Good (Combined 'very good' and 'fairly good' responses, to be used with total base)"
label variable	q30_recoded_1pct	"Long-term health condition - % Yes (base excluding 'don't know / can't say')"
label variable	q112_1pct	"Which of the following best describes you - % Female"
label variable	q112_2pct	"Which of the following best describes you - % Male"
label variable	q112_3pct	"Which of the following best describes you - % Non-binary"
label variable	q112_4pct	"Which of the following best describes you - % Prefer to self-describe"
label variable	q49_1pct	"Ethnic group - % White - English/Welsh/Scottish/Northern Irish/British"
label variable	q48_merged_1pct	"Age - % Under 16"
label variable	q48_merged_2pct	"Age - % 16 to 24"
label variable	q48_merged_3pct	"Age - % 25 to 34"
label variable	q48_merged_4pct	"Age - % 35 to 44"
label variable	q48_merged_5pct	"Age - % 45 to 54"
label variable	q48_merged_6pct	"Age - % 55 to 64"
label variable	q48_merged_7pct	"Age - % 65 to 74"
label variable	q48_merged_8pct	"Age - % 75 to 84"
label variable	q48_merged_9pct	"Age - % 85 or over	"

label variable q28base "Overall experience of GP practice - Total responses"
label variable q28_12 "Overall experience of GP practice - Summary result - Good (Combined 'very good' and 'fairly good' responses, to be used with total base)"

label variable q18_12 "Overall experience of making an appointment - Summary result - Good (Combined 'very good' and 'fairly good' responses, to be used with total base)"
label variable q18base "Overall experience of making an appointment - Total responses"

merge 1:1 prac_code using no_of_pts.dta
drop if _merge!=3
drop _merge
merge 1:1 prac_code using prac_dep.dta
drop if _merge!=3
drop _merge

sum no_of_pts

*look at data and drop practices with low numbers
sort no_of_pts
drop if no_of_pts <1000
drop if no_of_pts ==.
drop if q18_12pct ==.
drop if q18_12pct ==0
drop if q18_12pct ==-97
drop if q28_12pct ==.
drop if q28_12pct ==0
drop if q28_12pct ==-97
*

gen no_of_pts_thous = no_of_pts/1000
gen no_of_pts_ten_thous = no_of_pts/10000
gen no_of_pts_five_thous = no_of_pts/5000

egen no_of_pts_cut = cut(no_of_pts_thous), at(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90)
gen no_of_pts_cut2 = no_of_pts_cut+4.999
tab no_of_pts_cut2

egen no_of_pts_cut_tens = cut(no_of_pts_thous), at(0, 10, 20, 30, 40, 50, 90)

label define no_of_pts_cut_tens 0"1000 to 9,999" 10"10,000 to 19,999" 20"20,000 to 29,999" 30"30,000 to 39,999" 40"40,000 to 49,999" 50">=50,000", replace
label values no_of_pts_cut_tens no_of_pts_cut_tens

gen q18_12pct2 = q18_12pct*100
gen q28_12pct2 = q28_12pct*100

save gpq_final.dta, replace
clear

** GP FTE
* data from https://files.digital.nhs.uk/FD/912D30/GPWPracticeCSV.062021.zip
import delimited "20. General Practice – December 2020 Practice Level.csv"
keep prac_code total_gp_fte total_gp_extg_fte total_patients

label var total_gp_fte "Total GPs Full Time Equivalents"
label var total_gp_extg_fte "All Fully Qualified GPs (excludes GPs in Training Grade) Full Time Equivalents"

drop if total_gp_fte == "ND"
drop if total_gp_extg_fte == "ND"
destring total_gp_fte, replace
destring total_gp_extg_fte, replace
save fte.dta, replace

clear
use gpq_final.dta

merge 1:1 prac_code using fte.dta
drop if _merge !=3
list practice_name if total_gp_fte ==0
drop if total_gp_extg_fte ==0
gen gp_pt_ratio = total_patients/total_gp_extg_fte
gen gp_pt_ratio_with_trainees = total_patients/total_gp_fte

gen dif_month_between_dec_jan = total_patients - no_of_pts
sum dif_month_between_dec_jan

gen dif_trainees = total_gp_fte - total_gp_extg_fte
sum dif_trainees
sum dif_trainees if dif_trainees >8
gen dif_trainees_ratio = gp_pt_ratio_with_trainees - gp_pt_ratio
sum dif_trainees_ratio

gen percent_age_over_74 = q48_merged_8pct + q48_merged_9pct

rename total_patients total_patients_from_fte_data

save gpq_final.dta, replace













***** ANALYSIS ******** *** JUST THOSE USED IN LETTER ****

clear
use gpq_final.dta
 
sum no_of_pts





*Appointment
*q18_12 Overall experience of making an appointment - % Summary result - Good (Combined 'very good' and 'fairly good' responses, to be used with base 

tab no_of_pts_cut_tens, sum(q18_12pct2)

*univariable model categorical pts
melogit q18_12 i.no_of_pts_cut_tens || prac_code:, bin(q18base) or
*univariable model continuous pts five thousand
melogit q18_12 no_of_pts_five_thous || prac_code:, bin(q18base) or



*appointments multivariate model continuous pt nos five thousand
*MAIN USED IN TEXT

xi: melogit q18_12 no_of_pts_five_thous gp_pt_ratio imd_value q30_recoded_1pct q49_1pct q112_1pct percent_age_over_74 ///
|| prac_code: , bin(q18base) or
reformat, output(necp) dpcoef(2) dpp(3) to(-) nocons eform


*appointments multivariate model categorical

xi: melogit q18_12 i.no_of_pts_cut_tens gp_pt_ratio imd_value q30_recoded_1pct q49_1pct q112_1pct percent_age_over_74 ///
|| prac_code: , bin(q18base) or
reformat, output(necp) dpcoef(2) dpp(3) to(-) nocons eform
*wald test
test _Ino_of_pts_10 _Ino_of_pts_20 _Ino_of_pts_30 _Ino_of_pts_40 _Ino_of_pts_50






*Overall satisfaction
******* "Overall experience of GP practice - Summary result - Good (Combined 'very good' and 'fairly good' responses, to be used with total base)"

tab no_of_pts_cut_tens, sum(q28_12pct2)

*univariable modelc categorical
melogit q28_12 i.no_of_pts_cut_tens || prac_code:, bin(q28base) or
*overall univariable model continuous no of patients five thous
melogit q28_12 no_of_pts_five_thous || prac_code:, bin(q28base) or


*overall multivariate model categorical
xi: melogit q28_12 i.no_of_pts_cut_tens gp_pt_ratio imd_value q30_recoded_1pct q49_1pct q112_1pct percent_age_over_74  ///
|| prac_code: , bin(q28base) or
reformat, output(necp) dpcoef(2) dpp(3) to(-) nocons eform
*wald test
test _Ino_of_pts_10 _Ino_of_pts_20 _Ino_of_pts_30 _Ino_of_pts_40 _Ino_of_pts_50

*overall multivariate model no of pts continuous five thousand increase per unit
*USED IN TEXT
xi: melogit q28_12 no_of_pts_five_thous gp_pt_ratio imd_value q30_recoded_1pct q49_1pct q112_1pct percent_age_over_74 ///
|| prac_code: , bin(q28base) or
reformat, output(necp) dpcoef(2) dpp(3) to(-) nocons eform




*put tables in word doc
putdocx clear
putdocx begin, pagesize(A4) font("Garamond", 12, black)
putdocx paragraph, font("", 14) halign(center)
putdocx text ("Multivariate model for overall satisfaction with appointments"), bold
putdocx paragraph, font("", 12, black) halign(right)
melogit q18_12 i.no_of_pts_cut_tens gp_pt_ratio imd_value q30_recoded_1pct q49_1pct q112_1pct percent_age_over_74 ///
|| prac_code: , bin(q18base) or
putdocx table table1 = etable, halign(center) cellmargin(top, 4pt)
putdocx save "multivariate model", replace

putdocx begin, pagesize(A4) font("Garamond", 12, black)
putdocx paragraph, font("", 14) halign(center)
putdocx text ("Multivariate model for overall satisfaction with gp practice"), bold
putdocx paragraph, font("", 12, black) halign(right)
melogit q28_12 i.no_of_pts_cut_tens gp_pt_ratio imd_value q30_recoded_1pct q49_1pct q112_1pct percent_age_over_74 ///
|| prac_code: , bin(q28base) or
putdocx table table2 = etable, halign(center) cellmargin(top, 4pt)
putdocx save "multivariate model", append






















**************** OTHER WORKINGS

*excludes practice with >50k patients and plots as linear effect
melogit q18_12 no_of_pts_cut_tens if no_of_pts_thous <50  || prac_code:, bin(q18base) or
*results suggest per 10k increase in pt pop OR 0.976 of pt reporting good apt exerpience

*checking linear model of appointment satisfaction excluding practices with 50K or more pts
melogit q18_12 no_of_pts_cut_tens if no_of_pts_thous <50  || prac_code:, bin(q18base) or
*generate predicted values from linear model
predict linear_fit, xb 
*put predicted values on odds scale
gen linear_fit_odds = exp(linear_fit)
*tabodds but adding the linear fit line
tabodds q18_12 no_of_pts_cut_tens if no_of_pts_thous <50 , bin(q18base) graph ci yscale(log) addplot(line linear_fit_odds no_of_pts_cut_tens if no_of_pts_thous <50, sort)


*checking linear model of overall satisfaction excluding practices with 50K or more pts
melogit q28_12 no_of_pts_cut_tens if no_of_pts_thous <50  || prac_code:, bin(q28base) or
*generate predicted values from linear model
predict linear_fit2, xb
*put predicted values on odds scale
gen linear_fit_odds2 = exp(linear_fit2)
*tabodds but adding the linear fit line
tabodds q28_12 no_of_pts_cut_tens if no_of_pts_thous <50 , bin(q28base) graph ci yscale(log) addplot(line linear_fit_odds2 no_of_pts_cut_tens if no_of_pts_thous <50, sort)

tabodds q28_12 no_of_pts_cut_tens, bin(q28base) graph ci yscale(log) 

*** summary of practices in groups of 5k
tab no_of_pts_cut, sum(q18_12pct2)
tab no_of_pts_cut, sum(q28_12pct2)



**** ANALYSIS USING LINEAR REGRESSION TO EXPLORE DATA NOTE OUTCOME BINARY (SATISFIED OR NOT CONVERTED TO PERCENTAGE PER PRACTICE THEN FITTED LINEARLY *********

twoway scatter q28_12pct2 no_of_pts_cut2, ///
msize(vtiny) ytitle("Patients reporting good experience (%)", margin(medium)) ///
xtitle("Number of patients registered at practice (1000)", margin(medium)) ///
title("Your Practice") ///
subtitle("Overall Experience") ///
xlabel(0(10)90) ylabel(10(10)100) xmtick(5(10)85) ///
legend(lab(1 "GP Practice (grouped)")) ///
legend(lab(2 "95% Confidence Interveral")) ///
legend(lab(3 "Linear fit (ungrouped data)")) ///
legend(order (1 3 2)) ///
legend(cols(1)) ///
ysize(20) xsize(18)  ///
|| lfitci q28_12pct2 no_of_pts_thous, acolor(%50) alcolor(%0)
regress q28_12pct2 no_of_pts_thous
*The regression coefficient for no_of_pts tells us that for every 1 thousand increase in patients, good_practice_percentage decreases by coef%

twoway scatter q18_12pct2 no_of_pts_cut2, ///
msize(vtiny) ytitle("Patients reporting good experience (%)", margin(medium)) ///
xtitle("Number of patients registered at practice (1000)", margin(medium)) ///
title("Making an Appointment") ///
subtitle("Overall Experience") ///
xlabel(0(10)90) ylabel(10(10)100) xmtick(5(10)85) ///
legend(lab(1 "GP Practice (grouped)")) ///
legend(lab(2 "95% Confidence Interveral")) ///
legend(lab(3 "Linear fit (ungrouped data)")) ///
legend(order (1 3 2)) ///
legend(cols(1)) ///
ysize(20) xsize(18)  ///
|| lfitci q18_12pct2 no_of_pts_thous, acolor(%50) alcolor(%0)  
regress q18_12pct2 no_of_pts_thous


*scatter gp_pt_ratio
twoway scatter q18_12pct2 gp_pt_ratio || lfitci q18_12pct2 gp_pt_ratio, acolor(%50) alcolor(%0)  
twoway scatter q28_12pct2 gp_pt_ratio || lfitci q28_12pct2 gp_pt_ratio, acolor(%50) alcolor(%0)


log close



