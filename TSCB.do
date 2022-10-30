/*
    TSCB_OLS.do computes the Two-Stage Cluster Bootstrap proposed by
    Abadie, Athey, Imbens and Wooldridge (2022).
	
    This code works for the OLS estimator with the following specification:

        Y - outcome variable
        W - treatment variable (binary)
        state - cluster variable and FE
*/

mata: mata clear

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
local commandline=e(cmdline)
if "`commandline'"=="" {
    di as error "estimate not found"
}

local rank=e(rank)
local names : colfullnames e(b)

*------------------------------------------------------------------------------*
* (1) Run TSCB
*------------------------------------------------------------------------------*
tokenize `varlist'  //1 outputvar, 2 treatmentvar, 3 clustervar

preserve
collapse (count) `1' (mean) `2', by(`3')
qui putmata Data=(`3' `1') W=`2', replace
restore

mata: S = length(uniqrows(Data[,1]))
mata: States = J(S,1,NULL)

local i=1
qui levelsof `3', local(clusterv)
local rs=r(r)

foreach s of local clusterv {
    qui putmata S`i'=(`3' `1' `2') if `3'==`s', replace
    mata: States[`i'] = &(S`i')
    local ++i
}

//bootstrap procedure
local b=1
cap set seed `seed'
mata: Betas=J(`reps',`rank',.)
mata: se=J(1,`rank',.)

dis "Two-Stage Cluster Bootstrap replications (`reps')."
dis "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"

preserve
while `b'<=`reps' {
    display in smcl "." _continue
    if mod(`b',50)==0 dis "     `b'"

    //select Wmean randomly
    mata: Data2=NewData(Data,W,S)
		
    //array para los clusters sampleados SST=Treated, SSU=Untreated, SS=T+U
    mata: SST  = J(S,1,NULL) 
    mata: SSU  = J(S,1,NULL) 
    mata: SS   = J(S,1,NULL) 
    mata: SSTU = J(1,3,.) 

    forval i=1/`rs' {		
        //base para la regresion
        mata: SS[`i']=SSample(Data2, States, SST, SSU, `i')
        mata: SSTU=(SSTU\(*SS[`i']))
    }
	
    //run regression and save estimators
    clear
    getmata (`3' `1' `2')=SSTU
    qui drop if `3'==.
    qui `commandline'
    mata: Betas[`b',]=st_matrix("e(b)")
    local ++b
}
restore

forval i=1/`rank' {
    mata: se[1,`i']=sqrt((`reps'-1)/`reps') * sqrt(variance(vec(Betas[,`i'])))
}

mata: st_matrix("se", se)
mat coln se = `names'
mat rown se = "Std. Err."
ereturn matrix se se

di as text ""
di as text "Two-Stage Cluster Bootstrap (TSCB):"

matlist e(se)'

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

*---------*
* Example *
*---------*
use data.dta, clear
egen statenumber=group(state) //create a new id from 1 to N

* OLS
reg Y W
tscb Y W statenumber, qk(1) seed(2022) reps(150)

* FE
areg Y W, abs(statenumber)
tscb Y W statenumber, qk(1) seed(2022) reps(150)



