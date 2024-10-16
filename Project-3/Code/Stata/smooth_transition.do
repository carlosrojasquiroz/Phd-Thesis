*-------------------------------------------------------------------------------
* Section 3: Smooth transition function
*-------------------------------------------------------------------------------
quietly gen p10 = .
quietly gen p25 = .
quietly gen p50 = .
quietly gen p75 = .
quietly gen p90 = .
quietly gen desvest = .
quietly gen promedio = .
* Computing statistics
levelsof code, local(cc)
foreach x in `cc' {
	quietly summarize $VARSTF if code == `x' & quarter >= tq(1998q1), detail
    quietly replace p10 = r(p10) if code == `x'
	quietly replace p25 = r(p25) if code == `x'
	quietly replace p50 = r(p50) if code == `x'
	quietly replace p75 = r(p75) if code == `x'
	quietly replace p90 = r(p90) if code == `x'
    quietly replace desvest = r(sd) if code == `x'
	quietly replace promedio = r(mean) if code == `x'
}
* Standarized variable
quietly gen X = (L.$VARSTF - promedio)/desvest
* Switching parameter
local theta 3
* Probability function (0<=Fd<=1)
quietly gen Fd = exp(`theta'*X)/(1+exp(`theta'*X))
*-------------------------------------------------------------------------------
