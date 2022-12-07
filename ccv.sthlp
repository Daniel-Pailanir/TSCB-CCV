{smcl}
{* *! version 1.0.0 November 15, 2022}
{title:Title}

{p 4 4 2}
{cmdab:ccv} {hline 2} The Causal Cluster Variance Estimator for Stata

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
{opt ccv} {opt depvar} {opt treatment} {opt groupvar} {ifin}{cmd:,} {it:qk() pk()} [{it:options}]

{synoptset 10 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt qk}({it:#})} proportion of clusters from population which are sampled in data.{p_end}
{synopt :{opt pk}({it:#})} proportion of individuals from population which are sampled in data.{p_end}
{synopt :{opt seed}({it:#})} set random-number seed to #.{p_end}
{synopt :{opt reps}({it:#})} the number of sample split repetitions to increase precision of variance calculation.{p_end}
{pstd}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:ccv} implements the Causal Cluster Variance (CCV) an analytic variance formula
 proposed by {help ccv##CCV:Abadie et al. (2022)} for models where average treatment
 effects are desired, and where standard error estimates wish to account for clustering.
 The CCV is a variance estimate which considers both the standard sampling component
 which induces variance in estimated regression coefficients, but also incorporates
 a design-based component, accounting for variability in estimates owing to treatment
 assignment mechanisms.  When the data which is used to estimate treatment effects
 includes an important proportion of clusters in the full population, standard
 cluster-robust standard errors can be significantly inflated, and the CCV provides
 a correction for this.
{p_end}

{pstd}
  Following the details laid out fully in {help ccv##CCV:Abadie et al. (2022)}, the CCV is 
  suitable for OLS regressions of an outcome on a single treatment variable, or
  for OLS regressions of an outcome variable on a single treatment variable, as well
  as unit fixed effects.  The estimation of the variance requires estimating various
  sub-components, including both residuals and between-cluster variation in
  treatment effects, and if these are estimated on the full sample, correlations between
  estimation errors of sub-components generates biases.  As such, sample splits are
  conducted within which separate components are estimated.
{p_end}

{pstd}
 {cmd:ccv} generates standard errors based on the CCV estimator for OLS or fixed
 effect models, and for comparison reports (standard) robust and cluster-robust
 standard errors.  The {cmd:ccv} command allows for cases where all clusters are
 observed, or where only some proportion of clusters are observed.  Sampling
 information about the proportion of clusters observed, as well as the proportion
 of individuals sampled from the full population needs to be provided by the user.
{p_end}

{pstd}
 The {cmd:ccv} command is closely related to the {cmd:tscb} (Two-Stage Cluster
 Bootstrap) command.  {cmd:tscb}
 (provided that it is installed) implements a bootstrap-version of the cluster
 variance formula of {help ccv##CCV:Abadie et al. (2022)}, and shares quite a
 similar syntax and logic.
{p_end}


{marker options}{...}
{title:Options}
{phang}
{opt qk}({it:#}) Indicates the proportion of clusters from the population which are
sampled in the data. This value should be strictly greater than 0, and less than
or equal to 1.  Values of 1 imply that all clusters are observed in the data,
whereas values less than 1 imply that only this proportion of clusters were sampled.
This is required.

{pstd}
{p_end}
{phang}
{opt pk}({it:#}) Indicates the proportion of population from a given cluster
which is sampled.  This value should be strictly greater than 0, and less than
or equal to 1.  For example, if a 10% sample from a microdata census is used
as the estimation sample, this value should be indicated as 0.1.  This is a
required option.

{pstd}
{p_end}
 {phang}
{opt seed}({it:#}) seed define for pseudo-random numbers.

{pstd}
{p_end}
{phang}
{opt reps}({it:#}) repetition of sample splits. Default is 4.

{pstd}
{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}

{cmd:ccv} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(se_ols)}}Standard error of the OLS estimator {p_end}
{synopt:{cmd:e(se_fe)}}Standard error of the FE estimator {p_end}
{synopt:{cmd:e(reps)}}Number of sample splits {p_end}
{synopt:{cmd:e(N_clust)}}Number of clusters {p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}ccv{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}


{pstd}
{p_end}

{marker examples}{...}
{title:Examples}

 
{marker references}{...}
{title:References}

{marker CCV}{...}
{phang} Alberto Abadie, Susan Athey, Guido W Imbens, Jeffrey M Wooldridge. 2022.
{browse "https://academic.oup.com/qje/advance-article-abstract/doi/10.1093/qje/qjac038/6750017?redirectedFrom=fulltext&login=false":{it:When Should You Adjust Standard Errors for Clustering?}.} The Quarterly Journal of Economics.
{p_end}


{title:Author}

