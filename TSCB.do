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



