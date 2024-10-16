/*------------------------------------------------------------------------------
Project: 		The transmission of oil supply news in net oil exporting 
				economies: the role of sovereign default risk
Author: 		Carlos Rojas Quiroz
Institution: 	European University Institute
Date: 			2024-10-14
Method: 		Local Projection Panel Data
Description: 	High/Low Debt Regimes
------------------------------------------------------------------------------*/
// Step 0: Housekeeping
clear all
cls
set more off
set graph off
global dir "/Users/carlosrojasquiroz/Desktop/EUI-Phd-Thesis/Project-3"
cd "$dir/Code/Stata"
timer on 1
*-------------------------------------------------------------------------------
// Step 1: Load data and save as dta file
do "load_data.do"
// Step 2: Declare global variables
do "global_variables.do"
// Step 3: Compute the smooth transition function
do "smooth_transition.do"
// Step 4: Transform the initial variables
do "transformation_variables.do"
// Step 5: Run local projection
do "lp_analysis.do"
*-------------------------------------------------------------------------------
* Robustness exercise 1: changing the variable in the smt
*-------------------------------------------------------------------------------
// Step 2: Declare global variables
global VARSTF "embi" // <- new variable in the smt
global VERSION "v1" // <- new name for results 
// Step 3: Compute the smooth transition function
drop p10 p25 p50 p75 p90 desvest promedio X Fd // <- erase old variables
do "smooth_transition.do"
// Step 4: Transform the initial variables
replace id_low = (1-Fd)
replace id_high = Fd
replace sl_ = s_*id_low
replace sh_ = s_*id_high
// Step 5: Run local projection
do "lp_analysis.do"
*-------------------------------------------------------------------------------
* Robustness exercise 2: changing the average by the median in the smt
*-------------------------------------------------------------------------------
// Step 2: Declare global variables
global VARSTF "debtgdp" // <- variable in the smt
global VERSION "v2" // <- new name for results
// Step 3: Compute the smooth transition function
drop p10 p25 p50 p75 p90 desvest promedio X Fd // <- erase old variables
do "smooth_transition.do"
quietly replace X = (L.$VARSTF - p50)/desvest // <- use of the median
local theta 3
quietly replace Fd = exp(`theta'*X)/(1+exp(`theta'*X))
// Step 4: Transform the initial variables
replace id_low = (1-Fd)
replace id_high = Fd
replace sl_ = s_*id_low
replace sh_ = s_*id_high
// Step 5: Run local projection
do "lp_analysis.do"
*-------------------------------------------------------------------------------
* Robustness exercise 3: use a new definition of the shock (CTOT)
*-------------------------------------------------------------------------------
// Step 2: Declare global variables
global VARSTF "debtgdp" // <- new variable in the smt
global VERSION "v3" // <- new name for results
// Step 3: Compute the smooth transition function
drop p10 p25 p50 p75 p90 desvest promedio X Fd // <- erase old variables 
do "smooth_transition.do"
// Step 4: Transform the initial variables
replace s_ = shock2/10 // <- commodity export price as a new shock
replace sl_ = s_*id_low
replace sh_ = s_*id_high
// Step 5: Run local projection
do "lp_analysis.do"
*-------------------------------------------------------------------------------
* Robustness exercise 4: positive/negative shocks (report only negative shocks)
*-------------------------------------------------------------------------------
// Step 2: Declare global variables
global VERSION "v4" // <- new name for results
global SIGN = -1.0 // <- sign of the shock
global SHOCKTYPE "negative" // <- report only this type of shock
// Step 4: Transform the initial variables
gen id_neg = 0
replace id_neg = 1 if shock<0
gen id_pos = 0 
replace id_pos = 1-id_neg 
gen lowneg = id_low*id_neg
gen highneg = id_high*id_neg
gen lowpos = id_low*id_pos
gen highpos = id_high*id_pos
replace s_ = shock // <- Original shock
gen sln_ = s_*id_low*id_neg
gen shn_ = s_*id_high*id_neg
gen slp_ = s_*id_low*id_pos
gen shp_ = s_*id_high*id_pos
label variable sln_ "Ll regime, s<0"
label variable shn_ "Hl regime, s<0"
label variable slp_ "Ll regime, s>0"
label variable shp_ "Hl regime, s>0"
// Step 5: Run local projection
do "lp_analysis_v2.do"
*-------------------------------------------------------------------------------
* Robustness exercise 5: positive/negative shocks (report only positive shocks)
*-------------------------------------------------------------------------------
// Step 2: Declare global variables
global VERSION "v5" // <- new name for results
global SIGN = 1.0 // <- sign of the shock
global SHOCKTYPE "positive" // <- report only this type of shock
// Step 5: Run local projection
do "lp_analysis_v2.do"
*-------------------------------------------------------------------------------
timer off 1
timer list
