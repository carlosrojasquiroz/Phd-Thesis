/*------------------------------------------------------------------------------
Project: 		Oil Supply News and Sovereign Default Risk
Author: 		Carlos Rojas Quiroz
Institution: 	European University Institute
Date: 			2024-06-25
Method: 		Local Projection Panel Data
Description: 	Simple linear regression
------------------------------------------------------------------------------*/
* Clear previous data and set options
clear all
cls
set more off
set graph off
graph set window fontface "Helvetica"
graph set print fontface "Helvetica"
* Housekeeping
global dir "/Users/carlosrojasquiroz/Desktop/EUI-Phd-Thesis/Project-3"
cd "$dir/Data"
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
*-------------------------------------------------------------------------------
* Section 2: Local projection specifics
*-------------------------------------------------------------------------------
* Forecast horizon
local HOR = 12
* Lag order
local LAG = 4
* Shock sign
local SIGN = 1.0
* Critical value at 90 percent level
local T90 = 1.644853626951472
* Critical value at 68 percent level
local T68 = 0.994457883209753
*-------------------------------------------------------------------------------
* Section 3: Graph specifics
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
* Section 4: Definition of variables
*-------------------------------------------------------------------------------
quietly {
* Oil Supply News Shock
gen s_ = shock
label variable s_ "Oil Supply News"
* Real Oil Price
gen p_ = wti
label variable p_ "Crude Oil Price"
* Total Population
gen o_ = pop/1000000
label variable o_ "Population"
* Sovereign Default Risk
gen r_ = embi
label variable r_ "Sovereign Default Risk"
* GDP
gen g_ = ln(gdp2010_100/o_)*100
label variable g_ "Gross Domestic Product"
* Investment
gen i_ = ln(fbk100/o_)*100
label variable i_ "Investment"
* Private Consumption
gen c_  = ln(ch100/o_)*100
label variable c_ "Private Consumption"
* Public Consumption
gen cg_ = ln(cg100/o_)*100
label variable cg_ "Public Consumption"
* Trade Balance
gen tb_ = tradegdp
label variable tb_ "Net Exports/GDP"
* Real Exchange Rate
gen rer_ = ln(rer)*100
label variable rer_ "Real Exchange Rate"
* Public Spending
gen gg_ = gggdp
label variable gg_ "Public Spending/GDP"
* Fiscal Revenues
gen rev_ = revgdp
label variable rev_ "Fiscal Revenues/GDP"
* Primary Balance
gen pb_ = revgdp-gggdp
label variable pb_ "Primary Balance/GDP"
* Public Debt
gen d_ = debtgdp
label variable d_ "Public Debt/GDP"
* Bank Credit/GDP
gen crg_ = creditgdp
label variable crg_ "Bank Credit/GDP"
* Banking Spread
gen spr_ = (tactive-tpasive)*100
label variable spr_ "Private Default Risk"
* GVA Oil
gen oil_ = ln(vaboil/o_)*100
label variable oil_ "GVA Oil Sector"
* GVA NonOil
gen nonoil_ = ln(vabnonoil/o_)*100
label variable nonoil_ "GVA Non-Oil Sector"
* Share of Tradable Sector
gen shr_ = shrt
label variable shr_ "Share of Tradable Sector"
* Unemployment
gen u_  = unem
label variable u_ "Unemployment Rate"	
* Consumer Price Index
gen cpi_ = ln(cpi)*100
label variable cpi_ "Consumer Price Index"
* Relative Prices
gen relp_ = ln(cpiusa/cpi)*100
label variable relp_ "Relative Consumer Prices"
* Reserves/GDP
gen res_ = ln(realreserves100/o_)*100
label variable res_ "Foreign Reserves"
* Current Account/GDP
gen ca_ = cagdp
label variable ca_ "Current Account/GDP"
* Exports/GDP
gen exp_ = exportgdp
label variable exp_ "Exports/GDP"
* Import/GDP
gen imp_ = importgdp
label variable imp_ "Imports/GDP"
}		
*-------------------------------------------------------------------------------
* Log file to save output
cd "$dir/Results"
log using "Base.log", text replace
*-------------------------------------------------------------------------------
* Section 5: Local projection analysis
*-------------------------------------------------------------------------------
* List of endogenous variables 
local varendo rer_ pb_ shr_ oil_ nonoil_ c_ i_ cg_ tb_ d_ g_ u_ r_ spr_ crg_ ca_ res_ gg_ exp_ imp_
* Loop over variables
foreach var of local varendo {
	* Endogenous variable
	quietly gen dy_ = d.`var'
	quietly forvalues h = 0/`HOR' {
		gen y_`h' = f`h'.`var' - l.`var'
		label variable y_`h' "`h'"
	}
	*---------------------------------------------------------------------------
	* Full sample
	*---------------------------------------------------------------------------
	eststo clear
	cap drop b u90 l90 u68 l68 q zeros
	quietly gen b=.
	quietly gen u90=.
	quietly gen l90=.
	quietly gen u68=.
	quietly gen l68=.
	quietly gen q=.
	quietly gen zeros=.
	* Loop over horizons
	quietly forvalues h = 0/`HOR' {	
		xtscc y_`h' s_ L(1/`LAG').(dy_ s_) F`h'.(dum1-dum11) if quarter >= tq(1998q1), fe lag(`h')
		replace b = `SIGN'*_b[s_] if _n == `h'+1
		replace u90 = `SIGN'*_b[s_] + `T90'*_se[s_]  if _n == `h'+1
		replace l90 = `SIGN'*_b[s_] - `T90'*_se[s_]  if _n == `h'+1
		replace u68 = `SIGN'*_b[s_] + `T68'*_se[s_]  if _n == `h'+1
		replace l68 = `SIGN'*_b[s_] - `T68'*_se[s_]  if _n == `h'+1	
		replace q = `h'	if _n == `h'+1
		replace zeros = 0 if _n == `h'+1	
		quietly eststo
	}
	local varlab : variable label `var'
	nois esttab, se nocons keep(s_) ti("`varlab' - Sample: 1998Q1-2023Q3") label star(* 0.32 ** 0.10) t(3) nogaps b(`FORMATT')
	* Graph
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea l90 u90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea l68 u68 q, fcolor("`DARK'") lwidth(none)) ///
		(line b q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Basis Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cg_" | "`var'" == "nonoil_" | "`var'" == "res_" {
	twoway ///
		(rarea l90 u90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea l68 u68 q, fcolor("`DARK'") lwidth(none)) ///
		(line b q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Change", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea l90 u90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea l68 u68 q, fcolor("`DARK'") lwidth(none)) ///
		(line b q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	quietly graph save "$dir/Results/Figures/GPH/`var'full.gph", replace	
	quietly graph export "$dir/Results/Figures/PDF/`var'full.pdf", replace
	drop dy_ y_*
}
*-------------------------------------------------------------------------------
* Close log file
log close
*-------------------------------------------------------------------------------
