![Stata](https://img.shields.io/badge/stata-2013-green) ![GitHub Starts](https://img.shields.io/github/stars/Daniel-Pailanir/tscb-ccv?style=social) ![GitHub license](https://img.shields.io/github/license/Daniel-Pailanir/sdid)

# Two-Stage Cluster Bootstrap and Causal Cluster Variance for Stata

## TSCB: Two-Stage Cluster Bootstrap
[tscb.ado](tscb.ado) - A post estimation program to compute the standard error for OLS and FE estimators. We consider the case when $q_k=1$ and $\frac{1}{q_k}=c$ where $c$ can take integer or non-integer values. We follow algorithm 1 of [Abadie et al (2022)](#references).

### Syntax
```
tscb Y W M [if] [in], qk() seed() reps()
```

Where Y is an outcome variable, W a binary treatment variable and M a variable indicating the cluster. We provide an example using the data availble from the paper:

### OLS and FE
```
use data.dta

* run TSCB
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
OLS  0.00362
FE   0.00144
```


## CCV: Causal Cluster Variance
[ccv.ado](ccv.ado) - A program to compute the standard error for OLS and FE estimators. 

### Syntax
```
ccv Y W M [if] [in], qk() pk() seed() reps()
```

Where Y is an outcome variable, W a binary treatment variable and M a variable indicating the cluster. We provide an example using the data availble from the paper:

### OLS and FE
```
use data.dta

* run CCV
ccv Y W statenumber, qk(1) pk(1) seed(2022) reps(8)
```
The code returns the following results

```
Causal Cluster Variance with (8) sample splits.
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
........
Causal Cluster Variance (CCV):
OLS  0.00355
FE   0.00138
```

## References
**When Should You Adjust Standard Errors for Clustering?**, Alberto Abadie, Susan Athey, Guido W Imbens, Jeffrey M Wooldridge, The Quarterly Journal of Economics, 2022.


