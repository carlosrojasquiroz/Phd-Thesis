/*------------------------------------------------------------------------------
Project: 		Oil Supply News and Sovereign Default Risk
Author: 		Carlos Rojas Quiroz
Institution: 	European University Institute
Date: 			2024-06-25
Method: 		Local Projection Panel Data
Description: 	Use a de facto indicator to identify peg exchange rate periods 
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
* Oil Supply News Shock
gen s_ = shock
gen sf_ = s_*fineexrr
gen sp_ = s_*(1-fineexrr)
label variable sf_ "Float"
label variable sp_ "Peg"
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
log using "ExRateRegs.log", text replace
*-------------------------------------------------------------------------------
* Section 5: Local projection analysis
*-------------------------------------------------------------------------------
* List of endogenous variables 
local varendo rer_ pb_ shr_ oil_ nonoil_ c_ i_ cg_ tb_ d_ g_ u_ r_
* Loop over variables
foreach var of local varendo {
	* Endogenous variable
	gen dy_ = d.`var'
	gen dyf_ = dy_*fineexrr
	gen dyp_ = dy_*(1-fineexrr)
	quietly forvalues h = 0/`HOR' {
		gen y_`h' = f`h'.`var' - l.`var'
		label variable y_`h' "`h'"
	}
	*---------------------------------------------------------------------------
	* Full sample
	*---------------------------------------------------------------------------
	eststo clear
	cap drop bp up90 lp90 up68 lp68 bf uf90 lf90 uf68 lf68 q zeros blc ulc90 llc90 ulc68 llc68
	gen bp=.
	gen up90=.
	gen lp90=.
	gen up68=.
	gen lp68=.
	gen bf=.
	gen uf90=.
	gen lf90=.
	gen uf68=.
	gen lf68=.	
	gen q=.
	gen zeros=.
	gen blc=. 
	gen ulc90=. 
	gen llc90=. 
	gen ulc68=. 
	gen llc68=.
	* Loop over horizons
	quietly forvalues h = 0/`HOR' {	
		xtscc y_`h' sp_ sf_ L(1/`LAG').(dyp_ sp_) L(1/`LAG').(dyf_ sf_) F`h'.(dum1-dum11)  if quarter >= tq(1998q1), fe lag(`h')
		replace bp = `SIGN'*_b[sp_] if _n == `h'+1
		replace up90 = `SIGN'*_b[sp_] + `T90'*_se[sp_]  if _n == `h'+1
		replace lp90 = `SIGN'*_b[sp_] - `T90'*_se[sp_]  if _n == `h'+1
		replace up68 = `SIGN'*_b[sp_] + `T68'*_se[sp_]  if _n == `h'+1
		replace lp68 = `SIGN'*_b[sp_] - `T68'*_se[sp_]  if _n == `h'+1
		replace bf = `SIGN'*_b[sf_] if _n == `h'+1
		replace uf90 = `SIGN'*_b[sf_] + `T90'*_se[sf_]  if _n == `h'+1
		replace lf90 = `SIGN'*_b[sf_] - `T90'*_se[sf_]  if _n == `h'+1
		replace uf68 = `SIGN'*_b[sf_] + `T68'*_se[sf_]  if _n == `h'+1
		replace lf68 = `SIGN'*_b[sf_] - `T68'*_se[sf_]  if _n == `h'+1
		lincom sf_-sp_
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
	nois esttab, se nocons keep(sp_ sf_) ti("`varlab' - Full Sample") label star(* 0.32 ** 0.10) t(3) nogaps b(`FORMATT')
	*---------------------------------------------------------------------------
	* Graph - peg regimes
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
		title("{bf:Peg}",  position(11) size(vlarge)) ///
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
		title("{bf:Peg}",  position(11) size(vlarge)) ///
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
		title("{bf:Peg}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'peg.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'peg.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - float regime
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lf90 uf90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lf68 uf68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bf q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Basis Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Float}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea lf90 uf90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lf68 uf68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bf q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Change", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Float}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lf90 uf90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lf68 uf68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bf q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Float}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'float.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'float.pdf", replace	
	*---------------------------------------------------------------------------
	* Graph - test of parameters
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea llc90 ulc90 q, fcolor("`LIGHT3'") lwidth(none)) ///
		(rarea llc68 ulc68 q, fcolor("`DARK3'") lwidth(none)) ///
		(line blc q, color("`SOLID3'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
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
		(rarea llc90 ulc90 q, fcolor("`LIGHT3'") lwidth(none)) ///
		(rarea llc68 ulc68 q, fcolor("`DARK3'") lwidth(none)) ///
		(line blc q, color("`SOLID3'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///	
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
		(rarea llc90 ulc90 q, fcolor("`LIGHT3'") lwidth(none)) ///
		(rarea llc68 ulc68 q, fcolor("`DARK3'") lwidth(none)) ///
		(line blc q, color("`SOLID3'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///	
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
	graph save "$dir/Results/Figures/GPH/`var'test.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'test.pdf", replace		
	drop dyp_ dyf_ dy_ y_*
}
*-------------------------------------------------------------------------------
* Close log file
log close
*-------------------------------------------------------------------------------
* Combine graphs
*-------------------------------------------------------------------------------
cd "$dir/Results/Figures/GPH"
* Float vs Peg responses to the oil supply news shock	
graph combine g_float.gph g_peg.gph, col(2) ycommon title("{bf:Gross Domestic Product}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/g_2.gph", replace
graph export "$dir/Results/Figures/PDF/g_2.pdf", replace	
graph combine tb_float.gph tb_peg.gph, col(2) ycommon title("{bf:Net Exports/GDP}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/tb_2.gph", replace
graph export "$dir/Results/Figures/PDF/tb_2.pdf", replace
graph combine cg_float.gph cg_peg.gph, col(2) ycommon title("{bf:Public Consumption}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/cg_2.gph", replace
graph export "$dir/Results/Figures/PDF/cg_2.pdf", replace
graph combine rer_float.gph rer_peg.gph, col(2) ycommon title("{bf:Real Exchange Rate}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/rer_2.gph", replace
graph export "$dir/Results/Figures/PDF/rer_2.pdf", replace
graph combine u_float.gph u_peg.gph, col(2) ycommon title("{bf:Unemployment}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/u_2.gph", replace
graph export "$dir/Results/Figures/PDF/u_2.pdf", replace
graph combine r_float.gph r_peg.gph, col(2) ycommon title("{bf:Sovereign Default Risk}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/r_2.gph", replace
graph export "$dir/Results/Figures/PDF/r_2.pdf", replace
graph combine d_float.gph d_peg.gph, col(2) ycommon title("{bf:Public Debt/GDP}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/d_2.gph", replace
graph export "$dir/Results/Figures/PDF/d_2.pdf", replace
graph combine oil_float.gph oil_peg.gph, col(2) ycommon title("{bf:GVA Oil Sector}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/oil_2.gph", replace
graph export "$dir/Results/Figures/PDF/oil_2.pdf", replace
* All figures - test of differences between sf_ and sp_
graph combine g_test.gph c_test.gph i_test.gph tb_test.gph rer_test.gph cg_test.gph pb_test.gph d_test.gph u_test.gph nonoil_test.gph oil_test.gph r_test.gph , cols(4) rows(3) iscale(*.8)
graph save "$dir/Results/Figures/GPH/all_test.gph", replace
graph export "$dir/Results/Figures/PDF/all_test.pdf", replace
set graph on		
*-------------------------------------------------------------------------------
