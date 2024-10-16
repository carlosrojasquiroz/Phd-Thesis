/*------------------------------------------------------------------------------
Project: 		Oil Supply News and Sovereign Default Risk
Author: 		Carlos Rojas Quiroz
Institution: 	European University Institute
Date: 			2024-06-25
Method: 		Local Projection Panel Data
Description: 	High/Low Debt Regimes + positive/negative sign shocks
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
gen float_ = L.Fd1 // hight debt regime
gen peg_ = (1-L.Fd1) // low debt regime
replace peg_ = factoexrr
* Interactive terms
gen sfp_ = s_*float_*idxp_
gen spp_ = s_*peg_*idxp_
gen sfn_ = s_*float_*idxn_
gen spn_ = s_*peg_*idxn_
* Labels
label variable sfp_ "High Debt, s>0"
label variable spp_ "Low Debt, s>0"
label variable sfn_ "High Debt , s<0"
label variable spn_ "Low Debt, s<0"
*-------------------------------------------------------------------------------
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
log using "DebtSign.log", text replace
*-------------------------------------------------------------------------------
* Section 5: Local projection analysis
*-------------------------------------------------------------------------------
* List of endogenous variables 
local varendo rer_ pb_ shr_ oil_ nonoil_ c_ i_ cg_ tb_ d_ g_ u_ r_
* Loop over variables
foreach var of local varendo {
	* Endogenous variable
	gen dy_ = d.`var'
	gen dyfp_ = dy_*float_*idxp_
	gen dypp_ = dy_*peg_*idxp_
	gen dyfn_ = dy_*float_*idxn_
	gen dypn_ = dy_*peg_*idxn_	
	quietly forvalues h = 0/`HOR' {
		gen y_`h' = f`h'.`var' - l.`var'
		label variable y_`h' "`h'"
	}
	*---------------------------------------------------------------------------
	* Full sample
	*---------------------------------------------------------------------------
	eststo clear
	cap drop bpp upp90 lpp90 upp68 lpp68 bfp ufp90 lfp90 ufp68 lfp68 bpn upn90 lpn90 upn68 lpn68 bfn ufn90 lfn90 ufn68 lfn68 q zeros
	gen bpp=.
	gen upp90=.
	gen lpp90=.
	gen upp68=.
	gen lpp68=.
	gen bfp=.
	gen ufp90=.
	gen lfp90=.
	gen ufp68=.
	gen lfp68=.	
	gen bpn=.
	gen upn90=.
	gen lpn90=.
	gen upn68=.
	gen lpn68=.
	gen bfn=.
	gen ufn90=.
	gen lfn90=.
	gen ufn68=.
	gen lfn68=.		
	gen q=.
	gen zeros=.
	* Loop over horizons
	quietly forvalues h = 0/`HOR' {	
		xtscc y_`h' spp_ sfp_ spn_ sfn_ L(1/`LAG').(dypp_ spp_ dyfp_ sfp_ dypn_ spn_ dyfn_ sfn_) F`h'.(dum1-dum11)  if quarter >= tq(1998q1), fe lag(`h')
		replace bpp = _b[spp_] if _n == `h'+1
		replace upp90 = _b[spp_] + `T90'*_se[spp_]  if _n == `h'+1
		replace lpp90 = _b[spp_] - `T90'*_se[spp_]  if _n == `h'+1
		replace upp68 = _b[spp_] + `T68'*_se[spp_]  if _n == `h'+1
		replace lpp68 = _b[spp_] - `T68'*_se[spp_]  if _n == `h'+1
		replace bfp = _b[sfp_] if _n == `h'+1
		replace ufp90 = _b[sfp_] + `T90'*_se[sfp_]  if _n == `h'+1
		replace lfp90 = _b[sfp_] - `T90'*_se[sfp_]  if _n == `h'+1
		replace ufp68 = _b[sfp_] + `T68'*_se[sfp_]  if _n == `h'+1
		replace lfp68 = _b[sfp_] - `T68'*_se[sfp_]  if _n == `h'+1
		replace bpn = `SIGN'*_b[spn_] if _n == `h'+1
		replace upn90 = `SIGN'*_b[spn_] + `T90'*_se[spn_]  if _n == `h'+1
		replace lpn90 = `SIGN'*_b[spn_] - `T90'*_se[spn_]  if _n == `h'+1
		replace upn68 = `SIGN'*_b[spn_] + `T68'*_se[spn_]  if _n == `h'+1
		replace lpn68 = `SIGN'*_b[spn_] - `T68'*_se[spn_]  if _n == `h'+1
		replace bfn = `SIGN'*_b[sfn_] if _n == `h'+1
		replace ufn90 = `SIGN'*_b[sfn_] + `T90'*_se[sfn_]  if _n == `h'+1
		replace lfn90 = `SIGN'*_b[sfn_] - `T90'*_se[sfn_]  if _n == `h'+1
		replace ufn68 = `SIGN'*_b[sfn_] + `T68'*_se[sfn_]  if _n == `h'+1
		replace lfn68 = `SIGN'*_b[sfn_] - `T68'*_se[sfn_]  if _n == `h'+1
		replace q = `h'	if _n == `h'+1
		replace zeros = 0 if _n == `h'+1	
		quietly eststo
	}
	local varlab : variable label `var'
	nois esttab, se nocons keep(spp_ sfp_ spn_ sfn_) ti("`varlab' - Full Sample") label star(* 0.32 ** 0.10) t(3) nogaps b(`FORMATT')
	*---------------------------------------------------------------------------
	* Graph - Low Debt | positive shocks
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lpp90 upp90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lpp68 upp68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bpp q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Low Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea lpp90 upp90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lpp68 upp68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bpp q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Low Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lpp90 upp90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lpp68 upp68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bpp q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Low Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'low_p.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'low_p.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - Low Debt | negative shocks
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lpn90 upn90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lpn68 upn68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bpn q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Low Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea lpn90 upn90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lpn68 upn68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bpn q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Low Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lpn90 upn90 q, fcolor("`LIGHT2'") lwidth(none)) ///
		(rarea lpn68 upn68 q, fcolor("`DARK2'") lwidth(none)) ///
		(line bpn q, color("`SOLID2'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle( , size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:Low Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'low_n.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'low_n.pdf", replace	
	*---------------------------------------------------------------------------
	* Graph - High Debt | positive shocks
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lfp90 ufp90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lfp68 ufp68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bfp q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Basis Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:High Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea lfp90 ufp90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lfp68 ufp68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bfp q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Change", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:High Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lfp90 ufp90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lfp68 ufp68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bfp q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:High Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'high_p.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'high_p.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - High Debt | negative shocks
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lfn90 ufn90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lfn68 ufn68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bfn q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Basis Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:High Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cpi_" {
	twoway ///
		(rarea lfn90 ufn90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lfn68 ufn68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bfn q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Change", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:High Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lfn90 ufn90 q, fcolor("`LIGHT'") lwidth(none)) ///
		(rarea lfn68 ufn68 q, fcolor("`DARK'") lwidth(none)) ///
		(line bfn q, color("`SOLID'") lw(`LW') xla(0(1)`HOR') xtick(0(1)`HOR')) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)`HOR') xtick(0(1)`HOR')) ///			
		, ///
		ytitle("Percentage Points", size(`FS')) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize(`FS')) ///
		xtitle("Quarters" , size(`FS')) ///
		xlabel( , labsize(`FS') grid) ///
		title("{bf:High Debt}",  position(11) size(vlarge)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	graph save "$dir/Results/Figures/GPH/`var'high_n.gph", replace	
	graph export "$dir/Results/Figures/PDF/`var'high_n.pdf", replace		
	drop dypp_ dyfp_ dypn_ dyfn_ dy_ y_*
}
*-------------------------------------------------------------------------------
* Close log file
log close
*-------------------------------------------------------------------------------
* Combine graphs
*-------------------------------------------------------------------------------
cd "$dir/Results/Figures/GPH"
* Float vs Peg | negative shocks
graph combine g_high_n.gph g_low_n.gph, col(2) ycommon title("{bf:Gross Domestic Product}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/g_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/g_2_n.pdf", replace	
graph combine tb_high_n.gph tb_low_n.gph, col(2) ycommon title("{bf:Net Exports/GDP}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/tb_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/tb_2_n.pdf", replace
graph combine cg_high_n.gph cg_low_n.gph, col(2) ycommon title("{bf:Public Consumption}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/cg_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/cg_2_n.pdf", replace
graph combine rer_high_n.gph rer_low_n.gph, col(2) ycommon title("{bf:Real Exchange Rate}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/rer_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/rer_2_n.pdf", replace
graph combine u_high_n.gph u_low_n.gph, col(2) ycommon title("{bf:Unemployment}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/u_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/u_2_n.pdf", replace
graph combine r_high_n.gph r_low_n.gph, col(2) ycommon title("{bf:Sovereign Default Risk}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/r_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/r_2_n.pdf", replace
graph combine d_high_n.gph d_low_n.gph, col(2) ycommon title("{bf:Public Debt/GDP}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/d_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/d_2_n.pdf", replace
graph combine oil_high_n.gph oil_low_n.gph, col(2) ycommon title("{bf:GVA Oil Sector}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/oil_2_n.gph", replace
graph export "$dir/Results/Figures/PDF/oil_2_n.pdf", replace
* Float vs Peg | positive shocks
graph combine g_high_p.gph g_low_p.gph, col(2) ycommon title("{bf:Gross Domestic Product}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/g_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/g_2_p.pdf", replace	
graph combine tb_high_p.gph tb_low_p.gph, col(2) ycommon title("{bf:Net Exports/GDP}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/tb_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/tb_2_p.pdf", replace
graph combine cg_high_p.gph cg_low_p.gph, col(2) ycommon title("{bf:Public Consumption}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/cg_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/cg_2_p.pdf", replace
graph combine rer_high_p.gph rer_low_p.gph, col(2) ycommon title("{bf:Real Exchange Rate}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/rer_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/rer_2_p.pdf", replace
graph combine u_high_p.gph u_low_p.gph, col(2) ycommon title("{bf:Unemployment}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/u_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/u_2_p.pdf", replace
graph combine r_high_p.gph r_low_p.gph, col(2) ycommon title("{bf:Sovereign Default Risk}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/r_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/r_2_p.pdf", replace
graph combine d_high_p.gph d_low_p.gph, col(2) ycommon title("{bf:Public Debt/GDP}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/d_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/d_2_p.pdf", replace
graph combine oil_high_p.gph oil_low_p.gph, col(2) ycommon title("{bf:GVA Oil Sector}",  position(11) size(vlarge)) xsize(6) ysize(3) iscale(*1.2)
graph save "$dir/Results/Figures/GPH/oil_2_p.gph", replace
graph export "$dir/Results/Figures/PDF/oil_2_p.pdf", replace
set graph on		
*-------------------------------------------------------------------------------
