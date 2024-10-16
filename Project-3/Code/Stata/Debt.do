/*------------------------------------------------------------------------------
Project: 		Oil Supply News and Sovereign Default Risk
Author: 		Carlos Rojas Quiroz
Institution: 	European University Institute
Date: 			2024-06-25
Method: 		Local Projection Panel Data
Description: 	High/Low Debt Regimes
------------------------------------------------------------------------------*/
* Clear previous data and set options
clear all
cls
set more off
set graph off
graph set print fontface "Helvetica"
graph set window fontface "Helvetica"
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
* Section 4: Smooth transition function
*-------------------------------------------------------------------------------
quietly gen p10 = .
quietly gen p25 = .
quietly gen p50 = .
quietly gen p75 = .
quietly gen p90 = .
quietly gen desvest = .
quietly gen promedio = .
levelsof code, local(cc)
foreach x in `cc' {
	quietly summarize debtgdp if code == `x' & quarter >= tq(1998q1), detail
    replace p10 = r(p10) if code == `x'
	replace p25 = r(p25) if code == `x'
	replace p50 = r(p50) if code == `x'
	replace p75 = r(p75) if code == `x'
	replace p90 = r(p90) if code == `x'
    replace desvest = r(sd) if code == `x'
	replace promedio = r(mean) if code == `x'
}
quietly gen X = (L.debtgdp-promedio)/desvest
* Switching parameter
local theta 3
* Probability function (0<=Fd<=1)
quietly gen Fd = exp(`theta'*X)/(1+exp(`theta'*X))
*-------------------------------------------------------------------------------
* Section 4: Definition of variables
*-------------------------------------------------------------------------------
quietly {
* Regimes
gen id_low = 0 // Low debt regime
replace id_low = (1-Fd)
gen id_high = 0 // High debt regime
replace id_high = Fd
* Oil Supply News Shock
gen s_ = shock
gen sl_ = s_*id_low
gen sh_ = s_*id_high
label variable sl_ "Low Debt"
label variable sh_ "Hight Debt"
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
log using "Debt.log", text replace
*-------------------------------------------------------------------------------
* Section 5: Local projection analysis
*-------------------------------------------------------------------------------
* List of endogenous variables 
local varendo rer_ pb_ shr_ oil_ nonoil_ c_ i_ cg_ tb_ d_ g_ u_ r_ spr_ crg_ ca_ res_ gg_ exp_ imp_
* Loop over variables
foreach var of local varendo {
	* Endogenous variable
	quietly gen dy_ = d.`var'
	quietly gen dyl_ = dy_*id_low
	quietly gen dyh_ = dy_*id_high
	quietly forvalues h = 0/`HOR' {
		gen y_`h' = f`h'.`var' - l.`var'
		label variable y_`h' "`h'"
	}
	*---------------------------------------------------------------------------
	* Full sample
	*---------------------------------------------------------------------------
	eststo clear
	cap drop bl ul90 ll90 ul68 ll68 bh uh90 lh90 uh68 lh68 q zeros blc ulc90 llc90 ulc68 llc68
	quietly gen bl=.
	quietly gen ul90=.
	quietly gen ll90=.
	quietly gen ul68=.
	quietly gen ll68=.
	quietly gen bh=.
	quietly gen uh90=.
	quietly gen lh90=.
	quietly gen uh68=.
	quietly gen lh68=.	
	quietly gen q=.
	quietly gen zeros=.
	quietly gen blc=. 
	quietly gen ulc90=. 
	quietly gen llc90=. 
	quietly gen ulc68=. 
	quietly gen llc68=.	
	* Loop over horizons
	quietly forvalues h = 0/`HOR' {	
		xtscc y_`h' sl_ sh_ id_low id_high L(1/`LAG').(dyl_ sl_ dyh_ sh_) F`h'.(dum1-dum11) i.code if quarter >= tq(1998q1),lag(`h') noconstant
		replace bl = _b[sl_] if _n == `h'+1
		replace ul90 = _b[sl_] + `T90'*_se[sl_]  if _n == `h'+1
		replace ll90 = _b[sl_] - `T90'*_se[sl_]  if _n == `h'+1
		replace ul68 = _b[sl_] + `T68'*_se[sl_]  if _n == `h'+1
		replace ll68 = _b[sl_] - `T68'*_se[sl_]  if _n == `h'+1
		replace bh = _b[sh_] if _n == `h'+1
		replace uh90 = _b[sh_] + `T90'*_se[sh_]  if _n == `h'+1
		replace lh90 = _b[sh_] - `T90'*_se[sh_]  if _n == `h'+1
		replace uh68 = _b[sh_] + `T68'*_se[sh_]  if _n == `h'+1
		replace lh68 = _b[sh_] - `T68'*_se[sh_]  if _n == `h'+1
		lincom sh_-sl_
		replace blc = r(estimate) if _n == `h'+1
		replace ulc90 = r(estimate) + `T90'*r(se)  if _n == `h'+1
		replace llc90 = r(estimate) - `T90'*r(se)  if _n == `h'+1
		replace ulc68 = r(estimate) + `T68'*r(se)  if _n == `h'+1
		replace llc68 = r(estimate) - `T68'*r(se)  if _n == `h'+1 
		replace q = `h'	if _n == `h'+1
		replace zeros = 0 if _n == `h'+1	
		quietly eststo
	}
	local varlab : variable label `var'
	nois esttab, se nocons keep(sl_ sh_) ti("`varlab' - Full Sample") label star(* 0.32 ** 0.10) t(3) nogaps b(`FORMATT')
	*---------------------------------------------------------------------------
	* Graph - Low Debt Regime
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea ll90 ul90 q, fcolor("`LIGHT3'") lwidth(none)) ///
		(rarea ll68 ul68 q, fcolor("`DARK3'") lwidth(none)) ///
		(line bl q, color("`SOLID3'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///				
		, ///
		ytitle( , size(`FS')) ///
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
		(rarea ll90 ul90 q, fcolor("`LIGHT3'") lwidth(none)) ///
		(rarea ll68 ul68 q, fcolor("`DARK3'") lwidth(none)) ///
		(line bl q, color("`SOLID3'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///				
		, ///
		ytitle( , size(`FS')) ///
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
		(rarea ll90 ul90 q, fcolor("`LIGHT3'") lwidth(none)) ///
		(rarea ll68 ul68 q, fcolor("`DARK3'") lwidth(none)) ///
		(line bl q, color("`SOLID3'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///	
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'low.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'low.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - High Debt Regime
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lh90 uh90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lh68 uh68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bh q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
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
		(rarea lh90 uh90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lh68 uh68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bh q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
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
		(rarea lh90 uh90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lh68 uh68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bh q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
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
	graph save "$dir/Results/Figures/GPH/`var'high.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'high.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - test of parameters
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rcap llc90 ulc90 q, lcolor(orange) lwidth(1.2)) ///
		(rcap llc68 ulc68 q, lcolor(orange_red) lwidth(1.2)) ///
		(line zeros q, color(black) lw(0.5) xla(0(1)12) xtick(0(1)12)) ///
		(scatter blc q, msymbol(O) mcolor(black) msize(medium)), ///
		ytitle(, size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
 		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(order(1 "90% CI" 2 "68% CI") ///
        pos(5) ring(0) col(1) ///
        size(medium) region(lstyle(none)))
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cg_" | "`var'" == "nonoil_" | "`var'" == "res_" {
	twoway ///
		(rcap llc90 ulc90 q, lcolor(orange) lwidth(1.2)) ///
		(rcap llc68 ulc68 q, lcolor(orange_red) lwidth(1.2)) ///
		(line zeros q, color(black) lw(0.5) xla(0(1)12) xtick(0(1)12)) ///
		(scatter blc q, msymbol(O) mcolor(black) msize(medium)), ///
		ytitle(, size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
 		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(order(1 "90% CI" 2 "68% CI") ///
        pos(5) ring(0) col(1) ///
        size(medium) region(lstyle(none)))
	}
	else {
	twoway ///
		(rcap llc90 ulc90 q, lcolor(orange) lwidth(1.2)) ///
		(rcap llc68 ulc68 q, lcolor(orange_red) lwidth(1.2)) ///
		(line zeros q, color(black) lw(0.5) xla(0(1)12) xtick(0(1)12)) ///
		(scatter blc q, msymbol(O) mcolor(black) msize(medium)), ///
		ytitle(, size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
 		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(order(1 "90% CI" 2 "68% CI") ///
        pos(5) ring(0) col(1) ///
        size(medium) region(lstyle(none)))
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'test.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'test.pdf", replace		
	drop dyl_ dyh_ dy_ y_*
}
*-------------------------------------------------------------------------------
* Close log file
log close		
*-------------------------------------------------------------------------------
