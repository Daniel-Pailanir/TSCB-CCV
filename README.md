![Stata](https://img.shields.io/badge/stata-2013-green) ![GitHub Starts](https://img.shields.io/github/stars/Daniel-Pailanir/tscb-ccv?style=social) ![GitHub license](https://img.shields.io/github/license/Daniel-Pailanir/sdid)

# Two-Stage Cluster Bootstrap and Causal Cluster Variance for Stata

## TSCB: Two-Stage Cluster Bootstrap
[tscb.ado](tscb.ado) - A post estimation program to compute the standard error for OLS and FE estimators. We consider the case when $q_k=1$ and $\frac{1}{q_k}=c$ where $c$ can take integer or non-integer values. We follow algorithm 1 of [Abadie et al (2022)](#references).

We provide an example using the data availble from the paper:

### OLS:
```
use data.dta
egen statenumber=group(state) //create a new id from 1 to N

* OLS
reg Y W
tscb Y W statenumber, qk(1) seed(2022) reps(150)
```
The code returns the following results

```
Two-Stage Cluster Bootstrap replications (150).
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
..................................................     50
..................................................     100
..................................................     150

Two-Stage Cluster Bootstrap (TSCB):

             | Std. Err. 
-------------+-----------
           W |  .0036182 
       _cons |  .0030679 
```


### FE:
```
* FE
areg Y W, abs(statenumber)
tscb Y W statenumber, qk(1) seed(2022) reps(150)
```
The code returns the following results

```
Two-Stage Cluster Bootstrap replications (150).
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
..................................................     50
..................................................     100
..................................................     150

Two-Stage Cluster Bootstrap (TSCB):

             | Std. Err. 
-------------+-----------
           W |  .0014387 
       _cons |  .0021086 
```

## CCV: Causal Cluster Variance
[ccv.ado](ccv.ado) - A program to compute the standard error for OLS estimator (for the moment). 

### OLS:
```
use data.dta
egen statenumber=group(state) //create a new id from 1 to N

* run CCV
ccv Y W statenumber, qk(1) pk(1) seed(2022) reps(8)
```
The code returns the following results

```
Causal Cluster Variance with (8) sample splits.
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
........
Causal Cluster Variance (CCV):  0.00355
```

## References
**When Should You Adjust Standard Errors for Clustering?**, Alberto Abadie, Susan Athey, Guido W Imbens, Jeffrey M Wooldridge, The Quarterly Journal of Economics, 2022.


