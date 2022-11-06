*! ccv: Causal Cluster Variance (Abadie et al., 2022) Implementation
*! Version 0.0.0 november6, 2022
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
        ];
#delimit cr
tokenize `varlist'

*-------------------------------------------------------------------------------
*--- (0) Error checks and unpack parsing
*-------------------------------------------------------------------------------
local Y = "`1'"
local W = "`2'"
local M = "`3'"
reg `Y' `W', cluster(`M')



*-------------------------------------------------------------------------------
*--- (1) Run CCV
*-------------------------------------------------------------------------------
gen split = runiform()<=0.5

    
qui putmata data = (`1' `2' `3' split), replace
mata: CCV(data[,1], data[,2], data[,3], data[,4], `pk', `qk')

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
    tau_full

    //Calculate pk term [UNDER CONSTRUCTION]
    pk_term = 0
    uniqM = uniqrows(M)  
    for(m=1;m<=rows(uniqM);++m) {
        uniqM[m]
    }
    
    // Place-holder
    V_CCV = 1
    return(V_CCV)
}
end
