*! tscb: Two-Stage Cluster Bootstrap (Abadie et al., 2022) Implementation
*! Version 1.0.0 november6, 2022
*! dpailanir@fen.uchile.cl, dclarke@fen.uchile.cl

/*
Versions:
*/

cap program drop tscb 
program tscb, eclass
version 13.0

#delimit ;
    syntax varlist(min=3 max=3), qk(numlist max=1 >0 <=1)
    [
        seed(numlist integer >0 max=1)
        reps(integer 50)
    ]
    ;
#delimit cr

*------------------------------------------------------------------------------*
* (0) Error checks in parsing
*------------------------------------------------------------------------------*
local qm=1/`qk'
if mod(`qm',1)==0 {
    if `qm'!=1 di as text "1/q is an integer, so we expand the data by `qm' for each cluster"
}

if mod(`qm',1)!=0 {
    local f=floor(`qm')
    local alpha=1-(`qm'-`f')
    local qm=`f'+1
    di as text "1/q is not an integer, so we expand the data by `f' or `qm' for each cluster"
}

*------------------------------------------------------------------------------*
* (1) Run TSCB
*------------------------------------------------------------------------------*
tokenize `varlist'  //1 outputvar, 2 treatmentvar, 3 clustervar

qui levelsof `3'
local rs=r(r)
local S=`rs'*`qm'

mata: States = J(`S',1,NULL)
local i=1

local m=0
forval r=1/`qm' {
    if `r'>1 local ++m
    forval s=1/`rs' {
        qui putmata S`i'=(`3' `1' `2') if `3'==`s', replace
        mata: States[`i'] = &(S`i')
        if `i'>`s' {
            mata: (*States[`i'])[,1] = (*States[`i'])[,1]:+`m'*`rs'
        }
        local ++i
    }
}

mata: Data=(range(1,`S',1), J(`S',1,.))
mata: W=J(`S',1,.)
forval s=1/`S' {
    mata: W[`s',1]    = mean((*States[`s'])[,3])
    mata: Data[`s',2] = rows((*States[`s'])[,1])
}

//bootstrap procedure
local b=1
cap set seed `seed'
mata: ols=J(`reps',1,.)
mata: fe=J(`reps',1,.)

dis "Two-Stage Cluster Bootstrap replications (`reps')."
dis "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"

preserve
while `b'<=`reps' {
    display in smcl "." _continue
    if mod(`b',50)==0 dis "     `b'"

    //select Wmean randomly
    mata: Data2=NewData(Data,W,`S')
		
    //array para los clusters sampleados SST=Treated, SSU=Untreated, SS=T+U
    mata: SST  = J(`S',1,NULL) 
    mata: SSU  = J(`S',1,NULL) 
    mata: SS   = J(`S',1,NULL) 
    mata: SSTU = J(1,3,.) 

    if `qk'==1 {
        local upperS=`S'
        mata: newi=Data[,1]
    }
    else {
        local upperS=`rs'
        local M=`S'
		
        if mod(1/`qk',1)!=0 {
            mata: ud=rdiscrete(1, 1, (`alpha',1-`alpha'))
            mata: st_local("ud", strofreal(ud))
            if `ud'==1 local M=`f'*`rs'
            else       local M=`qm'*`rs'		
        }
		
        mata: newi=sort(SSelect(`M', `rs', Data[1..`M',1]),1)
    }

    forval i=1/`upperS' {		
        //base para la regresion
        mata: i=newi[`i',1]
        mata: SS[`i']=SSample(Data2, States, SST, SSU, i)
        mata: SSTU=(SSTU\(*SS[`i']))
    }
	
    //run regression and save estimators
    mata: alpha = sum(SSTU[,2]:*(1:-SSTU[,3]))/sum(1:-SSTU[,3])
    mata: ols[`b',] = sum(SSTU[,2]:*SSTU[,3])/sum(SSTU[,3]) - alpha
	mata: fe[`b',] = FE(SSTU[,2], SSTU[,3], SSTU[,1])

    local ++b
}
restore

mata: tscb_ols = sqrt((`reps'-1)/`reps') * sqrt(variance(vec(ols)))
mata: tscb_fe = sqrt((`reps'-1)/`reps') * sqrt(variance(vec(fe)))

mata: st_local("tscb_ols", strofreal(tscb_ols))
mata: st_local("tscb_fe", strofreal(tscb_fe))

ereturn scalar se_ols = `tscb_ols' 
ereturn scalar se_fe = `tscb_fe'

di as text ""
di as text "Two-Stage Cluster Bootstrap (TSCB):"
di as text "OLS" as result %9.5f `tscb_ols'
di as text "FE " as result %9.5f `tscb_fe'

end

*------------------------------------------------------------------------------*
* (2) Mata Functions
*------------------------------------------------------------------------------*
mata:
    matrix NewData(matrix D, matrix W, S) {
        p=J(S,1,1/S)
        index=rdiscrete(S,1,p)
        Wsample=W[index[,1],1]
        D2=(D,round(D[.,2]:*Wsample),round(D[.,2]:*(1:-Wsample)))
        return(D2)
    }
end 

mata:
    matrix SSample(matrix Data2, pointer States, pointer SST, pointer SSU, i) {
    NT=Data2[i,3]
    NU=Data2[i,4]
    NT_original=rows((*States[i])[selectindex((*States[i])[,3]:==1),])
    NU_original=rows((*States[i])[selectindex((*States[i])[,3]:==0),])
    indexT=ceil(NT_original*runiform(NT,1))
    indexU=ceil(NU_original*runiform(NU,1))
	
    //treated
    matauxT=(*States[i])[selectindex((*States[i])[,3]:==1),]
    SST[i]=&(matauxT[indexT[,1],])
		
    //untreated
    matauxU=(*States[i])[selectindex((*States[i])[,3]:==0),]
    SSU[i]=&(matauxU[indexU[,1],])
		
    //append de tratados y no tratados por cada estado
    SS=&((*SST[i])\(*SSU[i]))
	
    return(SS)
    }
end

mata: 
    real vector SSelect(S, rs, D) {
    index=(runiform(S,1),D)
    s=sort(index,-1)[1..rs,2]
    return(s)
    }
end

mata:
real scalar FE(vector Y, vector W, vector Cluster) {
    Wmean = _mm_collapse2(W, 1, Cluster)
    w = W - Wmean
    tau_fe = sum(Y:*w)/sum(W:*w)
    return(tau_fe)
}
end

