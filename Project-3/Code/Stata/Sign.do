/*------------------------------------------------------------------------------
Project: 		Oil Supply News and Sovereign Default Risk
Author: 		Carlos Rojas Quiroz
Institution: 	European University Institute
Date: 			2024-06-25
Method: 		Local Projection Panel Data
Description: 	Negative/Positive shocks
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
local SIGN = -1.0
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
* Oil Supply News Shock
gen s_ = shock
gen idxn_ = 0 // negative shock
replace idxn_ = 1 if shock<0
gen idxp_ = 0 // positive shock
replace idxp_ = 1 if shock>0
* Interactive terms
gen sp_ = s_*idxp_
gen sn_ = s_*idxn_
label variable sp_ "s>0"
label variable sn_ "s<0"
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
* Bank Credit (GDP)
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
gen res_ = reservesgdp
label variable res_ "Reserves/GDP"		
*-------------------------------------------------------------------------------
* Log file to save output
cd "$dir/Results"
log using "Sign.log", text replace
*-------------------------------------------------------------------------------
* Section 5: Local projection analysis
*-------------------------------------------------------------------------------
* List of endogenous variables 
local varendo rer_ pb_ shr_ oil_ nonoil_ c_ i_ cg_ tb_ d_ g_ u_ r_
* Loop over variables
foreach var of local varendo {
	* Endogenous variable
	gen dy_ = d.`var'
	gen dyp_ = dy_*idxp_
	gen dyn_ = dy_*idxn_
	quietly forvalues h = 0/`HOR' {
		gen y_`h' = f`h'.`var' - l.`var'
		label variable y_`h' "`h'"
	}
	*---------------------------------------------------------------------------
	* Full sample
	*---------------------------------------------------------------------------
	eststo clear
	cap drop bp up90 lp90 up68 lp68 bn un90 ln90 un68 ln68 q zeros
	gen bp=.
	gen up90=.
	gen lp90=.
	gen up68=.
	gen lp68=.
	gen bn=.
	gen un90=.
	gen ln90=.
	gen un68=.
	gen ln68=.	
	gen q=.
	gen zeros=.
	* Loop over horizons
	quietly forvalues h = 0/`HOR' {	
		xtscc y_`h' sp_ sn_ L(1/`LAG').(dyp_ sp_) L(1/`LAG').(dyn_ sn_) F`h'.(dum1-dum11)  if quarter >= tq(1998q1), fe lag(`h')
		replace bp = _b[sp_] if _n == `h'+1
		replace up90 = _b[sp_] + `T90'*_se[sp_]  if _n == `h'+1
		replace lp90 = _b[sp_] - `T90'*_se[sp_]  if _n == `h'+1
		replace up68 = _b[sp_] + `T68'*_se[sp_]  if _n == `h'+1
		replace lp68 = _b[sp_] - `T68'*_se[sp_]  if _n == `h'+1
		replace bn = `SIGN'*_b[sn_] if _n == `h'+1
		replace un90 = `SIGN'*_b[sn_] + `T90'*_se[sn_]  if _n == `h'+1
		replace ln90 = `SIGN'*_b[sn_] - `T90'*_se[sn_]  if _n == `h'+1
		replace un68 = `SIGN'*_b[sn_] + `T68'*_se[sn_]  if _n == `h'+1
		replace ln68 = `SIGN'*_b[sn_] - `T68'*_se[sn_]  if _n == `h'+1
		replace q = `h'	if _n == `h'+1
		replace zeros = 0 if _n == `h'+1	
		quietly eststo
	}
	local varlab : variable label `var'
	nois esttab, se nocons keep(sp_ sn_) ti("`varlab' - Full Sample") label star(* 0.32 ** 0.10) t(3) nogaps b(`FORMATT')
	*---------------------------------------------------------------------------
	* Graph - positive shocks
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lp90 up90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lp68 up68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bp q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:`varlab'}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea lp90 up90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lp68 up68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bp q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:`varlab'}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lp90 up90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lp68 up68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bp q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:`varlab'}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'p.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'p.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - negative shocks
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea ln90 un90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea ln68 un68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bn q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Basis Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:`varlab'}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea ln90 un90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea ln68 un68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bn q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Change", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:`varlab'}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea ln90 un90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea ln68 un68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bn q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:`varlab'}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'n.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'n.pdf", replace			
	drop dyp_ dyn_ dy_ y_*
}
*-------------------------------------------------------------------------------
* Close log file
log close
*-------------------------------------------------------------------------------
* Combine graphs
*-------------------------------------------------------------------------------
cd "$dir/Results/Figures/GPH"
graph combine g_p.gph c_p.gph i_p.gph tb_p.gph rer_p.gph cg_p.gph pb_p.gph d_p.gph u_p.gph nonoil_p.gph oil_p.gph r_p.gph, cols(4) rows(3) iscale(*.8)
graph save "$dir/Results/Figures/GPH/all_p.gph", replace
graph export "$dir/Results/Figures/PDF/all_p.pdf", replace	
graph combine g_n.gph c_n.gph i_n.gph tb_n.gph rer_n.gph cg_n.gph pb_n.gph d_n.gph u_n.gph nonoil_n.gph oil_n.gph r_n.gph, cols(4) rows(3) iscale(*.8)
graph save "$dir/Results/Figures/GPH/all_n.gph", replace
graph export "$dir/Results/Figures/PDF/all_n.pdf", replace	
set graph on			
*-------------------------------------------------------------------------------
