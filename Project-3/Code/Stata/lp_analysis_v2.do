*-------------------------------------------------------------------------------
* Section 5: Local projection analysis (positive/negative shocks)
*-------------------------------------------------------------------------------
* Log file to save output in new directory file
cd "$dir/Output/Logs"
log using "Debt_$VERSION.log", text replace
* List of endogenous variables 
local varendo rer_ pb_ shr_ oil_ nonoil_ c_ i_ cg_ tb_ d_ g_ u_ r_ spr_ crg_ ca_ res_ gg_ exp_ imp_
* Loop over variables
foreach var of local varendo {
	* Endogenous variable
	quietly gen dy_ = d.`var'
	quietly gen dyln_ = dy_*id_low*id_neg
	quietly gen dyhn_ = dy_*id_high*id_neg
	quietly gen dylp_ = dy_*id_low*id_pos
	quietly gen dyhp_ = dy_*id_high*id_pos
	quietly forvalues h = 0/$HOR {
		gen y_`h' = f`h'.`var' - l.`var'
		label variable y_`h' "`h'"
	}
	*---------------------------------------------------------------------------
	* Local projection regressions
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
	quietly forvalues h = 0/$HOR {	
		xtscc y_`h' sln_ shn_ slp_ shp_ lowneg highneg lowpos highpos L(1/ $LAG ).(dyln_ sln_ dyhn_ shn_ dylp_ slp_ dyhp_ shp_) F`h'.(dum1-dum11) i.code if quarter >= tq(1998q1), lag(`h') noconstant
		if "$SHOCKTYPE" == "negative" {
			replace bl = $SIGN *_b[sln_] if _n == `h'+1
			replace ul90 = $SIGN *_b[sln_] + $T90 *_se[sln_]  if _n == `h'+1
			replace ll90 = $SIGN *_b[sln_] - $T90 *_se[sln_]  if _n == `h'+1
			replace ul68 = $SIGN *_b[sln_] + $T68 *_se[sln_]  if _n == `h'+1
			replace ll68 = $SIGN *_b[sln_] - $T68 *_se[sln_]  if _n == `h'+1
			replace bh = $SIGN *_b[shn_] if _n == `h'+1
			replace uh90 = $SIGN *_b[shn_] + $T90 *_se[shn_]  if _n == `h'+1
			replace lh90 = $SIGN *_b[shn_] - $T90 *_se[shn_]  if _n == `h'+1
			replace uh68 = $SIGN *_b[shn_] + $T68 *_se[shn_]  if _n == `h'+1
			replace lh68 = $SIGN *_b[shn_] - $T68 *_se[shn_]  if _n == `h'+1
			lincom $SIGN *(shn_ - sln_)
			replace blc = r(estimate) if _n == `h'+1
			replace ulc90 = r(estimate) + $T90 *r(se)  if _n == `h'+1
			replace llc90 = r(estimate) - $T90 *r(se)  if _n == `h'+1
			replace ulc68 = r(estimate) + $T68 *r(se)  if _n == `h'+1
			replace llc68 = r(estimate) - $T68 *r(se)  if _n == `h'+1 
			replace q = `h'	if _n == `h'+1
			replace zeros = 0 if _n == `h'+1	
			quietly eststo
		}
		else if "$SHOCKTYPE" == "positive" {
			replace bl = $SIGN *_b[slp_] if _n == `h'+1
			replace ul90 = $SIGN *_b[slp_] + $T90 *_se[slp_]  if _n == `h'+1
			replace ll90 = $SIGN *_b[slp_] - $T90 *_se[slp_]  if _n == `h'+1
			replace ul68 = $SIGN *_b[slp_] + $T68 *_se[slp_]  if _n == `h'+1
			replace ll68 = $SIGN *_b[slp_] - $T68 *_se[slp_]  if _n == `h'+1
			replace bh = $SIGN *_b[shp_] if _n == `h'+1
			replace uh90 = $SIGN *_b[shp_] + $T90 *_se[shp_]  if _n == `h'+1
			replace lh90 = $SIGN *_b[shp_] - $T90 *_se[shp_]  if _n == `h'+1
			replace uh68 = $SIGN *_b[shp_] + $T68 *_se[shp_]  if _n == `h'+1
			replace lh68 = $SIGN *_b[shp_] - $T68 *_se[shp_]  if _n == `h'+1
			lincom $SIGN *(shn_ - sln_)
			replace blc = r(estimate) if _n == `h'+1
			replace ulc90 = r(estimate) + $T90 *r(se)  if _n == `h'+1
			replace llc90 = r(estimate) - $T90 *r(se)  if _n == `h'+1
			replace ulc68 = r(estimate) + $T68 *r(se)  if _n == `h'+1
			replace llc68 = r(estimate) - $T68 *r(se)  if _n == `h'+1 
			replace q = `h'	if _n == `h'+1
			replace zeros = 0 if _n == `h'+1	
			quietly eststo
		}
	}
	local varlab : variable label `var'
	nois esttab, se nocons keep(sln_ shn_) ti("`varlab' - Sample: 1998Q1-2023Q3") label star(* 0.32 ** 0.10) t(3) nogaps b($FORMATT)
	*---------------------------------------------------------------------------
	* Graph - Low Debt Regime
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea ll90 ul90 q, fcolor("$LIGHT3") lwidth(none)) ///
		(rarea ll68 ul68 q, fcolor("$DARK3") lwidth(none)) ///
		(line bl q, color("$SOLID3") lw($LW) xla(0(1)$HOR) xtick(0(1)$HOR)) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///				
		, ///
		ytitle( , size($FS)) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cg_" | "`var'" == "nonoil_" | "`var'" == "res_" {
	twoway ///
		(rarea ll90 ul90 q, fcolor("$LIGHT3") lwidth(none)) ///
		(rarea ll68 ul68 q, fcolor("$DARK3") lwidth(none)) ///
		(line bl q, color("$SOLID3") lw($LW) xla(0(1)$HOR) xtick(0(1)$HOR)) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///				
		, ///
		ytitle( , size($FS)) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea ll90 ul90 q, fcolor("$LIGHT3") lwidth(none)) ///
		(rarea ll68 ul68 q, fcolor("$DARK3") lwidth(none)) ///
		(line bl q, color("$SOLID3") lw($LW) xla(0(1)$HOR) xtick(0(1)$HOR)) ///	
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///			
		, ///
		ytitle( , size($FS)) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	quietly graph save "$dir/Output/Figures/GPH/`var'low_$VERSION.gph", replace	
	quietly graph export "$dir/Output/Figures/PDF/`var'low_$VERSION.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - High Debt Regime
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rarea lh90 uh90 q, fcolor("$LIGHT") lwidth(none)) ///
		(rarea lh68 uh68 q, fcolor("$DARK") lwidth(none)) ///
		(line bh q, color("$SOLID") lw($LW) xla(0(1)$HOR) xtick(0(1)$HOR)) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///			
		, ///
		ytitle("Basis Points", size($FS)) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cg_" | "`var'" == "nonoil_" | "`var'" == "res_" {
	twoway ///
		(rarea lh90 uh90 q, fcolor("$LIGHT") lwidth(none)) ///
		(rarea lh68 uh68 q, fcolor("$DARK") lwidth(none)) ///
		(line bh q, color("$SOLID") lw($LW) xla(0(1)$HOR) xtick(0(1)$HOR)) ///			
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///			
		, ///
		ytitle("Percentage Change", size($FS)) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)	
	}
	else {
	twoway ///
		(rarea lh90 uh90 q, fcolor("$LIGHT") lwidth(none)) ///
		(rarea lh68 uh68 q, fcolor("$DARK") lwidth(none)) ///
		(line bh q, color("$SOLID") lw($LW) xla(0(1)$HOR) xtick(0(1)$HOR)) ///		
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///			
		, ///
		ytitle("Percentage Points", size($FS)) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///	
		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)		
	}
	* Save graph file
	quietly graph save "$dir/Output/Figures/GPH/`var'high_$VERSION.gph", replace	
	quietly graph export "$dir/Output/Figures/PDF/`var'high_$VERSION.pdf", replace
	*---------------------------------------------------------------------------
	* Graph - test of parameters
	*---------------------------------------------------------------------------
	if "`var'" == "r_" | "`var'" == "spr_" {
	twoway ///
		(rcap llc90 ulc90 q, lcolor(orange) lwidth($LW)) ///
		(rcap llc68 ulc68 q, lcolor(orange_red) lwidth($LW)) ///
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///
		(scatter blc q, msymbol(O) mcolor(black) msize(medium)), ///
		ytitle(, size($FS)) ///
		ylabel( , angle(horizontal) format(%9.0f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
 		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else if "`var'"== "g_" | "`var'" == "c_" | "`var'" == "i_" | "`var'" == "rer_" | "`var'" == "oil_" | "`var'" == "cg_" | "`var'" == "nonoil_" | "`var'" == "res_" {
	twoway ///
		(rcap llc90 ulc90 q, lcolor(orange) lwidth($LW)) ///
		(rcap llc68 ulc68 q, lcolor(orange_red) lwidth($LW)) ///
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///
		(scatter blc q, msymbol(O) mcolor(black) msize(medium)), ///
		ytitle(, size($FS)) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
 		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	else {
	twoway ///
		(rcap llc90 ulc90 q, lcolor(orange) lwidth($LW)) ///
		(rcap llc68 ulc68 q, lcolor(orange_red) lwidth($LW)) ///
		(line zeros q, color(black) lw(0.5) xla(0(1)$HOR) xtick(0(1)$HOR)) ///
		(scatter blc q, msymbol(O) mcolor(black) msize(medium)), ///
		ytitle(, size($FS)) ///
		ylabel( , angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel( , labsize($FS) grid) ///
 		graphregion(color(white)) plotregion(color(white)) ///
		xsize(8) ///
		ysize(6) ///
		legend(off)
	}
	* Save graph file
	quietly graph save "$dir/Output/Figures/GPH/`var'test_$VERSION.gph", replace	
	quietly graph export "$dir/Output/Figures/PDF/`var'test_$VERSION.pdf", replace		
	drop dyln_ dyhn_ dylp_ dyhp_ dy_ y_*
}
* Close log file
log close
* Go back to the old directory
cd "$dir/Code/Stata"		
*-------------------------------------------------------------------------------
