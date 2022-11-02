# TSCB
Two-Stage Cluster Bootstrap and Causal Cluster Variance: Stata package

[tscb.ado](tscb.ado) - contain a small post estimation program to compute the standard error for simple OLS and FE estimators. For the moment we consider the case $q_k=1$ and $\frac{1}{q_k}=c$ where $c$ can be an integer or not. We following algorithm 1 of [Abadie et al (2022)](#references).

We provide an example using the data availble from the paper:

## OLS:
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


## FE:
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


> :warning: **At the moment the procedure with covariates is not available**: Be very careful here!

# CCV
CCV - work in progress


# References
**When Should You Adjust Standard Errors for Clustering?**, Alberto Abadie, Susan Athey, Guido W Imbens, Jeffrey M Wooldridge, The Quarterly Journal of Economics, 2022.


