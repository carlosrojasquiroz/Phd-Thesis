# TauOptim.jl

function ndgrid(v1, v2)
#===================================================================================
This function creates a NpxNb matrix for each vector P and B, respectively
===================================================================================#     
    m, n = length(v1), length(v2)
    v1 = reshape(v1, m, 1)
    v2 = reshape(v2, 1, n)
    (repeat(v1, 1, n), repeat(v2, m, 1))
end

function tmaxval(P, B, Bp, Q, p::Param)
#===================================================================================
This function computes the value of τ that maximizes the utility function
===================================================================================#     
    funU = τ -> -1.0 * utility(P, B, Bp, τ, Q, p)
    result = optimize(funU, p.τmin, p.τmax)
    tau_opt = Optim.minimizer(result)  # Obtiene el valor de tau que minimiza la función
    return tau_opt
end

function inittau(p::Param, m::Dict{Symbol, Any}, Q)
#===================================================================================
This function computes the value of τ for repayment and default states, conditional
on the level of oil price, the old debt and the new debt: 
    τ(P,B,B') = f(P,B,B',Q(P,B'), parameters)
===================================================================================#     
    # Debt grid
    B = m[:B]
    # Oil price 
    Po = m[:P]
    # Oil price in default state
    P̂o = m[:P̂]
    # Optimal tax rate in default: tau(P,0,0)
    @unpack Np, ϵ, Nb = p    
    tau_optD = zeros(Np, 1)
    tau_optD = map((P) -> tmaxval(P, ϵ, ϵ, ϵ, p), P̂o)
    # Optimal tax rate in repayment: tau(P,B,B')
    tau_optR = zeros(Np, Nb, Nb)
    P_grid, Bp_grid = ndgrid(Po, B)
    for i2 in 1 : Nb
        tau_optR[:, i2, :] = map((P, Bp, Qo) -> tmaxval(P, B[i2], Bp, Qo, p),
                                 P_grid, Bp_grid, Q)
    end
    return tau_optD, tau_optR
end