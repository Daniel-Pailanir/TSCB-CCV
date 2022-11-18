*! ccv: Causal Cluster Variance (Abadie et al., 2022) Implementation
*! Version 0.0.0 november7, 2022
*! dpailanir@fen.uchile.cl, dclarke@fen.uchile.cl

/*
Versions: 0.0.1 november14 - add if/in and create unique id in ccv
*/


cap program drop ccv
program ccv, eclass
version 13.0


#delimit ;
    syntax varlist(min=3 max=3) [if] [in],
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
tempvar touse
mark `touse' `if' `in'

tempvar M
qui egen `M' = group(`3') if `touse'

*-------------------------------------------------------------------------------
*--- (1) Run CCV
*-------------------------------------------------------------------------------
cap set seed `seed'
qui putmata data = (`1' `2' `M') if `touse', replace
mata: ccv=J(`reps',1,.)

// calculate tau FE
mata: fe = FE(data[,1], data[,2], data[,3])
mata: Wbar = mean(data[,2])

// robust and cluster se FE
mata: Ntot = rows(data)
mata: tildes = auxsum(data[,1], data[,2], data[,3], fe)
mata: rFE_V = Ntot*(tildes[1,1]/tildes[3,1]^2)
mata: clusterFE_V = Ntot*(tildes[2,1]/tildes[3,1]^2)
mata: Mk = rows(uniqrows(data[,3]))
mata: lambdak = 1 - `qk'*((tildes[4,1]/Mk)^2/(tildes[5,1]/Mk))
mata: CCV_FE_V = lambdak*clusterFE_V + (1 - lambdak)*rFE_V
mata: ccv_se_fe = sqrt(CCV_FE_V)/sqrt(Ntot)
mata: st_local("ccv_se_fe", strofreal(ccv_se_fe))

dis "Causal Cluster Variance with (`reps') sample splits."
dis "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"

forval i=1/`reps' {
    display in smcl "." _continue
    if mod(`i',50)==0 dis "     `i'"
	
    tempvar split
    qui gen `split' = runiform()<=0.5 if `touse'
    qui putmata split = (`split') if `touse', replace
    mata: ccv[`i',1]=CCV(data[,1], data[,2], data[,3], split, `pk', `qk')
}

// adjust for qk<1
mata: ccv = ccv:*`qk' :+ (1-`qk')*clusterFE_V

mata: n=rows(data)
mata: ccv_se = sqrt((1/`reps')*sum(ccv))/sqrt(n)
mata: st_local("ccv_se", strofreal(ccv_se))

ereturn scalar se_ols = `ccv_se' 
ereturn scalar se_fe = `ccv_se_fe' 

di as text ""
di as text "Causal Cluster Variance (CCV):" 
di as text "OLS" as result %9.5f `ccv_se'
di as text "FE " as result %9.5f `ccv_se_fe'

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
    //Calculate pk term
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

        if (variance(vec(w))==0) {
            tau_ms[m,1] = tau
            tau_full_ms = tau_full
        }
        else {
            tau_ms[m,1] = sum(y:*(w):*(1:-u_m))/sum((w):*(1:-u_m)) - sum(y:*(1:-w):*(1:-u_m))/sum((1:-w):*(1:-u_m))
            tau_full_ms = sum(y:*(w))/sum(w) - sum(y:*(1:-w))/sum(1:-w)
        }
		
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

mata:
real scalar FE(vector Y, vector W, vector Cluster) {
    //A = (Y, W)
    //Acoll = _mm_collapse2(A, 1, Cluster)
    //y = Y - Acoll[,1]
    Wmean = _mm_collapse2(W, 1, Cluster)
    w = W - Wmean
    tau_fe = sum(Y:*w)/sum(W:*w)
    return(tau_fe)
}
end

mata:
real matrix auxsum(vector Y, vector W, vector M, scalar fe) {
    sum_tildeU = 0
    sum_tildeW = 0
    sum_tildeU_FE = 0
    num_lambdak = 0
    den_lambdak = 0
    T = J(5,1,.)
	
    uniqM = uniqrows(M)
    NM = rows(uniqM)
    for(m=1;m<=NM;++m) {
        cond = M:==uniqM[m]
        y = select(Y,cond)
        w = select(W,cond)
        Ym = mean(y)
        Wmbar = mean(w)
        Wtilde = w :- Wmbar
        Utilde = y :- Ym :- (Wtilde:*fe)
        sum_tildeU = sum_tildeU + sum((Wtilde:^2):*(Utilde:^2))
        sum_tildeU_FE = sum_tildeU_FE + (sum(Wtilde:*Utilde))^2
        sum_tildeW = sum_tildeW + sum(Wtilde:^2)
		
        num_lambdak = num_lambdak + Wmbar*(1-Wmbar)
        den_lambdak = den_lambdak + (Wmbar^2)*((1-Wmbar)^2)
    }
	
    T[1,1] = sum_tildeU
    T[2,1] = sum_tildeU_FE
    T[3,1] = sum_tildeW
    T[4,1] = num_lambdak
    T[5,1] = den_lambdak
    return(T)
}
end

