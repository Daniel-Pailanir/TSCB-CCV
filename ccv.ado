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
*reg `Y' `W', cluster(`M')



*-------------------------------------------------------------------------------
*--- (1) Run CCV
*-------------------------------------------------------------------------------

qui putmata data = (`1' `2' `3'), replace
mata: CCV(data[,1], data[,2], data[,3], `pk', `qk')

end

*-------------------------------------------------------------------------------
*--- (2) Mata functions
*-------------------------------------------------------------------------------
mata: 
real scalar CCV(vector Y, vector W, vector M, scalar pk, scalar qk) {
    sum(Y)
    sum(W)
    sum(M)
    pk
    qk

    V_CCV = 1
    return(V_CCV)
}
end
