*! ccv: Causal Cluster Variance (Abadie et al., 2022) Implementation
*! Version 0.0.0 november7, 2022
*! Author: Pailañir Daniel, Clarke Damian
*! dpailanir@fen.uchile.cl, dclarke@fen.uchile.cl

/*
Versions:

*/


cap program drop ccv
program ccv, eclass
version 13.0


#delimit ;
    syntax varlist(min=3 max=3),
        qk(numlist max=1 >0 <=1) 
        pk(numlist max=1 >0 <=1)
        [
            seed(numlist integer >0 max=1)
            reps(integer 4)
        ];
#delimit cr
tokenize `varlist'

*-------------------------------------------------------------------------------
*--- (0) Error checks and unpack parsing
*-------------------------------------------------------------------------------
local Y = "`1'"
local W = "`2'"
local M = "`3'"
*reg `Y' `W', cluster(`M')



*-------------------------------------------------------------------------------
*--- (1) Run CCV
*-------------------------------------------------------------------------------
cap set seed `seed'
qui putmata data = (`1' `2' `3'), replace
mata: ccv=J(`reps',1,.)

dis "Causal Cluster Variance with (`reps') sample splits."
dis "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"

forval i=1/`reps' {
    display in smcl "." _continue
    if mod(`i',50)==0 dis "     `i'"

    cap drop split
    gen split = runiform()<=0.5
    qui putmata split = (split), replace
    mata: ccv[`i',1]=CCV(data[,1], data[,2], data[,3], split, `pk', `qk')
}
mata: n=rows(data)
mata: ccv_se = sqrt((1/`reps')*sum(ccv[,1]))/sqrt(n)
mata: st_local("ccv_se", strofreal(ccv_se))

ereturn scalar se = `ccv_se' 

di as text ""
di as text "Causal Cluster Variance (CCV):" as result %9.5f `ccv_se'

end

*-------------------------------------------------------------------------------
*--- (2) Mata functions
*-------------------------------------------------------------------------------
mata: 
real scalar CCV(vector Y, vector W, vector M, vector u, scalar pk, scalar qk) {
    // u is split variable: 1 if estimation, 0 if calculate    

    //Calculate alpha and tau for split 1 [NEED TO CONFIRM IF FASTER TO JUST SELECT SUB-VECTORS!]
    alpha = sum(Y:*(1:-W):*(1:-u))/sum((1:-W):*(1:-u))
    tau = sum(Y:*(W):*(1:-u))/sum((W):*(1:-u)) - alpha

    // Calculate tau for full sample
    tau_full = sum(Y:*(W))/sum(W) - sum(Y:*(1:-W))/sum(1:-W)

    //Calculate pk term [UNDER CONSTRUCTION]
    pk_term = 0
    ncount = 0
    uniqM = uniqrows(M)
    NM = rows(uniqM)
    tau_ms = J(NM,1,.)
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        y = select(Y,cond)
        w = select(W,cond)
        u_m = select(u,cond)
        Nm = rows(y)
        ncount = ncount + Nm
		tau_ms[m,1] = sum(y:*(w):*(1:-u_m))/sum((w):*(1:-u_m)) - sum(y:*(1:-w):*(1:-u_m))/sum((1:-w):*(1:-u_m))
        tau_full_ms = sum(y:*(w))/sum(w) - sum(y:*(1:-w))/sum(1:-w)
		
        aux_pk = Nm*((tau_full_ms - tau)^2)
        pk_term = pk_term + aux_pk
    }
    // Calculate residual
    resU = Y :- alpha :- W:*tau

    // Wbar
    Wbar = sum(W:*(1:-u))/(sum((1:-W):*(1:-u)) + sum((W):*(1:-u)))

    // pk
    pk_term = pk_term*(1-pk)/ncount
    
    // Calculate avg Z
    Zavg = sum(u)/ncount
	
    // Calculate the normalized CCV using second split
    n = ncount*(Wbar^2)*((1-Wbar)^2)

    sum_CCV = 0
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        cond = cond:*u
        y = select(Y,cond)
        w = select(W,cond)
        resu = select(resU,cond)
		
        // tau
	    tau_term = (tau_ms[m,1] - tau)*Wbar*(1-Wbar)

        // Residual
        res_term = (w :- Wbar):*resu

        // square of sums
        sq_sum = (sum(res_term :- tau_term))^2

        // sum of squares
        sum_sq = sum((res_term :- tau_term):^2)

        // Calculate CCV
        sum_CCV = sum_CCV+(1/(Zavg^2))*sq_sum-((1-Zavg)/(Zavg^2))*sum_sq+n*pk_term
    }
	
    V_CCV = sum_CCV/n
	
    // Place-holder
    return(V_CCV)
}
end


