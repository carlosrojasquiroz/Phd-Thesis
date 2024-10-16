#====================================================================================================================
Project: 
Author: Carlos Rojas Quiroz
Date: 25th September 2024

Description:
This code ...
Key topics include:
  - ...

# Structure
    / Main.jl 
    │
    ├── 1. Declaration of packages
    ├── 2. Mutable struct param
    ├── 3. External scripts:
    │    ├── 3.1 ModelObjects.jl    # Computation of matrices and grids 
    │    ├── 3.2 FirmsOptim.jl      # Firms' optimization
    │    ├── 3.3 HouseholdsOptim.jl # Households' consumption and utility
    │    ├── 3.4 GovOptim.jl        # Government's consumption
    │    └── 3.5 TauOptim.jl        # Optimal tax rate    
    ├── 4. Declaration of parameters
    ├── 5. Computation of matrices and grids
    └── 6. Value function iteration
====================================================================================================================#


#--------------------------------------------------------------------------------------------------------------------
# 1. Declaration of packages
#--------------------------------------------------------------------------------------------------------------------
using Parameters, Optim, SpecialFunctions, LinearAlgebra, Statistics, Plots, SparseArrays, Roots, NLsolve
#--------------------------------------------------------------------------------------------------------------------
# 2. Mutable struct param
#--------------------------------------------------------------------------------------------------------------------
@with_kw mutable struct Param
    #---------------------------------------------------------------------------------------------------------------- 
    # Households
    #----------------------------------------------------------------------------------------------------------------
    ϕ::Float64  = 0.70  # Public spending weight (1-ϕ), Cuadra et al. (2010)
    β::Float64  = 0.9407  # Discount factor, steady-state r = r* + spread = 0.06309
    r::Float64  = 0.01  # Risk-free interest rate, standard value 
    σ::Float64  = 2.00  # Risk aversion, standard value
    γm::Float64 = 1.60  # Labor elasticity in manufacturing sector, standard value
    γc::Float64 = 1.60  # Labor elasticity in commodity sector, standard value
    δ::Float64 = (1+0.1255)^0.25-1 # Capital depreciation rate, García-Cicco et al.(2010)
    #----------------------------------------------------------------------------------------------------------------
    # Manufacturing Firms
    #----------------------------------------------------------------------------------------------------------------
    α::Float64  = 0.68 # Share of labor in manufacturing firms, García-Cicco et al.(2010)
    θ::Float64  = 0.05 # Share of oil in manufacturing firms, Sousha (2016)
    #----------------------------------------------------------------------------------------------------------------
    # Commodity Firms
    #----------------------------------------------------------------------------------------------------------------
    ϱ::Float64  = 0.28 # Royalty rate, weighted average
    ϑ::Float64  = 0.68 # Share of labor in commodity firms, impose equal capital share across both sectors
    #----------------------------------------------------------------------------------------------------------------    
    # Government
    #----------------------------------------------------------------------------------------------------------------
    λ::Float64  = 0.10      # Re-entry probability, Cuadra et al. (2010)
    d0::Float64 = -0.18819  # Default cost 0
    d1::Float64 = 0.24558   # Default cost 1
    ψ::Float64 = 0.64       # Drop in oil price
    #----------------------------------------------------------------------------------------------------------------
    # Stochastic process for the oil price
    #----------------------------------------------------------------------------------------------------------------
    ρo::Float64 = 0.9277841 # AR(1) parameter, own estimation
    μo::Float64 = 0.0139778 # Intercept, own estimation  
    σo::Float64 = 0.1562    # Standard deviation, own estimation
    m::Float64 = 2.15       # Number of ± s.d., Hamman et al. (2023)
    #----------------------------------------------------------------------------------------------------------------
    # Grids
    #----------------------------------------------------------------------------------------------------------------
    Np::Int64 = 25      # Number of points for oil prices
    Na::Int64 = 51      # Number of points for savings
    Nb::Int64 = 51      # Number of points for debt
    al::Float64 = 0.00  # Min savings value
    ah::Float64 = 0.15  # Max savings value
    bl::Float64 = 0.00  # Borrowing min limit
    bh::Float64 = 0.50  # Max debt value
    #----------------------------------------------------------------------------------------------------------------
    # Optimizers
    #----------------------------------------------------------------------------------------------------------------
    τmin::Float64 = 0.00  # Inferior limit of tax rate
    τmax::Float64 = 1.00  # Superior limit of tax rate
    ϵ::Float64 = 1e-6     # Convergence tolerance
    cost_fn::Int64 = 1    # Switch for cost function
    distQ::Float64 = 1.0  # Distance of Q object
    distV::Float64 = 1.0  # Distance of V object
    distVd::Float64 = 1.0 # Distance of Vd object
    #----------------------------------------------------------------------------------------------------------------
    # Steady State
    #----------------------------------------------------------------------------------------------------------------
    # Productivity of manufacturing sector
    zmss::Float64  = 1.00 
    # Productivity of oil sector
    zcss::Float64  = 1.00
    # Consumption tax rate 
    τss::Float64 = 0.1887 # weighted average
    # Labor in manufacturing sector 
    hmss::Float64 = 2/9 # 50/50 proportion of VAB oil/VAB non oil
    # Labor in commodity sector  
    hcss::Float64 = 1/9 # 50/50 proportion of VAB oil/VAB non oil
    # Commodity price (oil) 
    poss::Float64 = exp(μo / (1 - ρo))
    # Return rate of capital 
    rkss::Float64 = 1 / β - 1 + δ # rk ≈ 0.09
    # Capital stock of manufacturing sector 
    kmss::Float64 = ((1 - α - θ) / rkss) ^ ((1 - θ) / α) * (zmss * hmss ^ α * θ ^ θ / (poss ^ θ))^(1 / α)
    # Intermediate input 
    mss::Float64 = (θ * zmss * hmss ^ α * kmss ^ (1 - α - θ) / poss)^(1 / (1 - θ))
    # Scalar factor of manufacturing labor
    ωm::Float64 =  α * zmss * mss ^ θ * kmss ^ (1 - α - θ) / (hmss ^ (1 - α + γm) * (1 + τss))
    # Capital stock of commodity sector 
    kcss::Float64 = (((1 - ϑ) * (1 - ϱ) * poss * zcss * hcss ^ ϑ) / rkss) ^ (1 / ϑ)
    # Scalar factor of commodity labor   
    ωc::Float64 = ϑ * (1 - ϱ) * poss * zcss * kcss ^ (1 - ϑ) / ((1 + τss) * hcss ^ (1 - ϑ + γc)) 
    # Wage in manufacturing sector   
    wmss::Float64 = hmss ^ γm * ωm * (1 + τss)
    # Wage in commodity sector
    wcss::Float64 = hcss ^ γc * ωc * (1 + τss)
    # Production in manufacturing sector
    ymss::Float64 = zmss * hmss ^ α * mss ^ θ * kmss ^ (1 - α - θ)
    # Production in commodity sector
    ycss::Float64 = zcss * hcss ^ ϑ * kcss ^ (1 - ϑ)
    # Profits in manufacturing sector
    pimss::Float64 = ymss - poss * mss - wmss * hmss - rkss * kmss
    # Profits in commodity sector
    picss::Float64 = (1 - ϱ) * poss * ycss - wcss * hcss - rkss * kcss
    # Households' consumption
    css::Float64 =  (wmss * hmss + wcss * hcss + pimss + picss) / (1 + τss)
    # Government's consumption
    gss::Float64 = τss * css + ϱ * poss * ycss
    # Gross domestic product
    gdpss::Float64 = ymss + poss * ycss - poss * mss
    # Trade balance
    tbss::Float64 = ymss - css - gss - δ * (kmss + kcss) + poss * ycss - poss * mss
    # Importance of manufacturing sector
    share_m::Float64 = ymss / gdpss
    # Importance of commodity sector
    share_c::Float64 = (poss * ycss - poss * mss) / gdpss
    # Investment ratio
    I_Y::Float64 = δ * (kmss + kcss) / gdpss * 100
    # Consumption ratio
    C_Y::Float64 = css / gdpss * 100
    # Public spending ratio
    G_Y::Float64 = gss / gdpss * 100
    # Trade balance
    TB_Y::Float64 = tbss / gdpss * 100
end
#--------------------------------------------------------------------------------------------------------------------
# 3. External scripts
#--------------------------------------------------------------------------------------------------------------------
include("ModelObjects.jl")
include("FirmsOptim.jl")
include("HouseholdsOptim.jl")
include("GovOptim.jl")
include("TauOptim.jl")
include("ValueFunctionIteration.jl")
#--------------------------------------------------------------------------------------------------------------------
# 4. Declaration of parameters
#--------------------------------------------------------------------------------------------------------------------
par = Param()
#--------------------------------------------------------------------------------------------------------------------
# 5. Computation of matrices and grids
#--------------------------------------------------------------------------------------------------------------------
mat = Matrices(par)
#--------------------------------------------------------------------------------------------------------------------
# 6. Value function iteration
#--------------------------------------------------------------------------------------------------------------------
vfi = ValueFunctionIteration(par,mat)

Γ = vfi[:Γ]
tau = vfi[:τopt]
Δ = vfi[:Δ]
Q = vfi[:Q]
TB= vfi[:tbopt]
Y = vfi[:gdpopt]
Bp = vfi[:bopt]
f = firms(mat[:P], tau, par)
TB_Y = TB ./ mean(Y) .* 100
Bp_Y = Bp ./ mean(Y) .* 100
B_Y = B' ./ mean(Y) .* 100
#--------------------------------------------------------------------------------------------------------------------
# 4. Figures
#--------------------------------------------------------------------------------------------------------------------
B = mat[:B]
# 4.1 Figure 1: Bond price
# Values for B
highB = 68.00
lowB = 0.00
# Indexes
iYhigh = 14
iYlow = 13
iBhigh = findfirst(x -> x >= highB, B_Y)
iBlow = findfirst(x -> x >= lowB, B_Y)
# Plot Bond Price Schedule
p = plot(B_Y[iBlow[2]:iBhigh[2]], TB_Y[iYlow, iBlow[2]:iBhigh[2]], color=RGB(48/255, 71/255, 94/255), linewidth=2.5, label="Low Shock", legend=:outerbottom, legendfont=10)
plot!(p, B_Y[iBlow[2]:iBhigh[2]], TB_Y[iYhigh, iBlow[2]:iBhigh[2]], color=RGB(234/255, 84/255, 85/255), linewidth=2.5, label="High Shock")
# Customize legend, labels, and title
xlabel!("Foreign Assets", font="Serif", fontsize=12)
ylabel!("Bond Price", font="Serif", fontsize=12)
# Display the plot
display(p)
# Save the plot as PNG
savefig(p, "Fig1.png")
