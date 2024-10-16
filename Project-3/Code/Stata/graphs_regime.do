*-------------------------------------------------------------------------------
* Section 3: Graphs on the public debt regimes according to a 
* logistic function following Tenreyro and Whaite 
*-------------------------------------------------------------------------------
quietly gen zeros = 0
levelsof country, local(countries)
foreach country of local countries {
    twoway (rarea Fd zeros quarter if country == "`country'" & quarter >= tq(1998q1) & quarter <= tq(2023q3), fcolor("$DARK") lcolor("$DARK")), ///
		ytitle("Prob(high debt regime)", size($FS)) ///
		ylabel(, angle(horizontal) format(%9.2f) labsize($FS)) ///
		xtitle("Quarters" , size($FS)) ///
		xlabel(, labsize($FS) grid)
		* Save graph file
		quietly graph save "$dir/Output/Figures/GPH/`country'_regime.gph", replace	
		quietly graph export "$dir/Output/Figures/PDF/`country'_regime.pdf", replace
}
quietly drop zeros
