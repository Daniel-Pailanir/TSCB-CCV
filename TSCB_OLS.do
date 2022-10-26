/*
	TSCB_OLS.do computes the Two-Stage Cluster Bootstrap proposed by
	Abadie, Athey, Imbens and Wooldridge (2022).
	
	This code works for the OLS estimator with the following specification:
	
	Y_{is} = \alpha + \tau W_{is} + \varepsilon_{is}

	where:
		Y - outcome variable
		W - treatment variable (binary)
		state - cluster variable
*/

use data.dta, clear
egen statenumber=group(state) //create a new id

timer clear
timer on 1

mata: mata clear
putmata DataOriginal=(Y W statenumber), replace

mata: 
    rseed(1996)
	units=panelsetup(DataOriginal,3)
	StateN=panelstats(units)[1]
	SN=StateN*1
	Obs=_mm_collapse(DataOriginal[,2], 1, DataOriginal[,3], &mm_nobs())
	Wmean=_mm_collapse(DataOriginal[,2], 1, DataOriginal[,3])

	//treated and untreated data
	DataT=select(DataOriginal, DataOriginal[,2]:==1)
	DataU=select(DataOriginal, DataOriginal[,2]:==0)
	PST=panelsetup(DataT,3)
	PSU=panelsetup(DataU,3)
	
	Obs=(Obs,PST[,2]-PST[,1]:+1)
	Obs=(Obs,PSU[,2]-PSU[,1]:+1)
end
		
*bootstrap procedure
mata:
    rseed(1996)
    B=50
    taus_OLS=J(2,B,.)

    for(b=1; b<=B; b++) {
		b
		p=J(SN, 1, 1/SN)
		index=rdiscrete(SN, 1, p)
		Wsample=Wmean[index[,1],2]
		//concat
		Obs2=(Obs,Wsample)
		Obs2=(Obs2,round(Obs2[.,2]:*Obs2[.,5]))
		Obs2=(Obs2,round(Obs2[.,2]:*(1:-Obs2[.,5])))
		
		SS=J(1,3,.)
		for(i=1; i<=SN; i++) {
			NT=Obs2[i,6]
			NU=Obs2[i,7]
			NT_original=Obs2[i,3]
			NU_original=Obs2[i,4]
			indexT=ceil(NT_original*runiform(NT,1))
			indexU=ceil(NU_original*runiform(NU,1))
			
			//treated
			matauxT=DataT[selectindex(DataT[,3]:==Obs2[i,1]),]
			SST=matauxT[indexT[,1],]
				
			//untreated
			matauxU=DataU[selectindex(DataU[,3]:==Obs2[i,1]),]
			SSU=matauxU[indexU[,1],]
				
			//append de tratados y no tratados por cada estado
			SS=(SS\SST\SSU)
		}

		N=rows(SS)
		X=(SS[,2],J(N,1,1))
		y=SS[,1]
		XX=quadcross(X,X)
		beta=invsym(XX)*quadcross(X,y)
		taus_OLS[,b]=beta
	}
	
    se_tau=sqrt((B-1)/B) * sqrt(variance(vec(taus_OLS[1,])))
    se_cons=sqrt((B-1)/B) * sqrt(variance(vec(taus_OLS[2,])))
    (se_tau, se_cons)
end

timer off 1
timer list 1

* 6.2848167 minutos para 250 iteraciones
* 0.003663059 en 250 iteraciones

