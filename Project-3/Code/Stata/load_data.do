*-------------------------------------------------------------------------------
* Section 1: Load data
*-------------------------------------------------------------------------------
* Set the new file directory
cd "$dir/Data/Raw"
* Import excel file
import excel "DataBase_May2024.xlsx", sheet("Panel6") firstrow
* Small changes in time variable
replace quarter = qofd(quarter)
format quarter %tq
* Save and use the dta file
save "$dir/Data/Analytic/DataPanel6.dta", replace
clear 
use "$dir/Data/Analytic/DataPanel6.dta", clear
* Declaring the panel data
tsset code quarter
* Go back to the initial file directory
cd "$dir/Code/Stata"
*-------------------------------------------------------------------------------
