*-------------------------------------------------------------------------------
* Project: Oil Supply News and Sovereign Default Risk
* Author: Carlos Rojas Quiroz
* Institution: European University Institute
* Date: 2024-06-25
* Purpose: Linear Local Projection Panel Data estimation
* Description: Graphs on the Regimes of High Sovereign Risk according to a 
* logistic function following Tenreyro and Whaite 
*-------------------------------------------------------------------------------
* Clear previous data and set options
clear all
cls
set more off
graph set window fontface "Helvetica"
graph set print fontface "Helvetica"
* Housekeeping
global dir "/Users/carlosrojasquiroz/Desktop/EUI-Phd-Thesis/Project-3"
cd "$dir/Data"
clear
*-------------------------------------------------------------------------------
* Section 1: Load data
*------------------------------------------------------------------------------- 
import excel "DataBase_May2024.xlsx", sheet("Panel6") firstrow
replace quarter = qofd(quarter)
format quarter %tq
save DataPanel6.dta, replace
clear 
use DataPanel6.dta, clear
* Declaring the panel data
tsset code quarter
* Generate zero variable
gen zeros = 0
*-------------------------------------------------------------------------------
* Section 2: Graph specifics
*-------------------------------------------------------------------------------
* Font size
local FS = 5
* Line width
local LW = 1.5
* Number of decimals in Tables
local FORMATT %4.3f
* Customized Blue Color
local LIGHT 222 235 247
local DARK 158 202 225
local SOLID 49 130 189
* Customized Red Color
local LIGHT2 254 224 210
local DARK2 252 146 114
local SOLID2 222 45 38
* Customized Green Color
local LIGHT3 229 245 224
local DARK3 161 217 155
local SOLID3 49 163 84
* Customized Orange Color
local LIGHT4 254 230 206
local DARK4 253 174 107
local SOLID4 230 85 13
*-------------------------------------------------------------------------------
* Section 3: Graph
*-------------------------------------------------------------------------------
levelsof country, local(countries)
foreach country of local countries {
    twoway (rarea Fr zeros quarter if country == "`country'" & quarter >= tq(1998q1), fcolor("`LIGHT2'") lcolor("`SOLID2'") lwidth(`LW'')), ///
        title("{bf:`country'}",  position(11) size(vlarge)) ///
        ytitle("High Sovereign Risk Regime", size(`FS')) ///
		ylabel(, angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel(, labsize(`FS') grid)
		* Save graph file
		graph save "$dir/Results/Figures/GPH/`country'_regime.gph", replace	
		graph export "$dir/Results/Figures/PDF/`country'_regime.pdf", replace
}
