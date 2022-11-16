{smcl}
{* *! version 1.0.0 November 15, 2022}
{title:Title}

{p 4 4 2}
{cmdab:ccv} {hline 2} Causal Cluster Variance Estimator

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
{opt ccv} {opt depvar} {opt treatment} {opt groupvar} {ifin}{cmd:,} {it:qk() pk()} [{it:options}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt seed}({it:#})} set random-number seed to #.{p_end}
{synopt :{opt reps}({it:#})} repetitions...{p_end}
{pstd}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:ccv}  {help ccv##CCV:Abadie et al. (2022)}.
{p_end}


{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt seed}({it:#}) seed define for pseudo-random numbers.

{pstd}
{p_end}
{phang}
{opt reps}({it:#}) repetitions for

{pstd}
{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}

{cmd:sdid} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(se_ols)}}Standard error {p_end}
{synopt:{cmd:e(se_fe)}}Standard error {p_end}
{synopt:{cmd:e(reps)}}Number of  {p_end}
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
{phang} Alberto Abadie, Susan Athey, Guido W Imbens, Jeffrey M Wooldridge. 2022. {browse "https://academic.oup.com/qje/advance-article-abstract/doi/10.1093/qje/qjac038/6750017?redirectedFrom=fulltext&login=false":{it:When Should You Adjust Standard Errors for Clustering?}.} The Quarterly Journal of Economics.
{p_end}


{title:Author}

