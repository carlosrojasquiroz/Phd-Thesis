*-------------------------------------------------------------------------------
* Section 4: Transformation of variables
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
label variable sl_ "Ll regime"
label variable sh_ "Hl regime"
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
