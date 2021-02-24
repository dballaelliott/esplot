{smcl}
{it:version alpha-1}

{title:esplot {hline 2} event study plots}

{title:Syntax}

{p 8 8 2} {bf:esplot} varname [{it:if}] [{it:in}]
[{it:weight}], {it:event(varname [, suboptions]}) [{it:options} ]    {break}

{p 4 4 2}
{it:or}

{p 8 8 2} {bf:esplot} outcome [{it:if}] [{it:in}]
[{it:weight}], {it:event(varname [, suboptions]}) [{it:options} ]    {break}
{title:  Documentation}

{title:Core Syntax }

{p 4 4 2}
{bf:esplot} can be called one of two ways. 

{break}    1. with an event-time variable:

    _esplot <outcome> <event_time> [, options]_

{break}    2. or with an event indicator (on panel data):

    _esplot <outcome>, event(<event_indicator> [, options])_

{title:Options    {break}}

{p 4 4 2}{bf:General Options    {break}}

{p 8 8 2} {bf:compare(<event_indicator> [, options])} {it:Only available when using the event(<event_indicator>) syntax.} Plot the {it:difference} between the event-time coefficents associated with the event in {it:event} and the event given in {it:compare}. For example, {it:esplot infected, event(treatment) compare(placebo)} will estimate event-time coefficents around the {it:treatment} event and the {it:placebo} event and will plot the difference between the {it:treatment} and {it:placebo} arms.    {break}

{p 4 4 2}{it:event_indicator suboptions (for compare and event)}

{p 8 8 2} {bf:save} this causes the vector of relative-time indicators created by {it:esplot} around the event given in either {it:event} or {it:compare} to be saved to memory. This option is useful when running many specifications of the same event study, as it can save time when used with {it:nogen} by creating this vector only once.    {break}

{p 8 8 2} {bf:nogen} this vector tells {it:esplot} that the vector of relative-time indicators around this particular event already exist (probably after being created by an earlier call to {it:esplot} with the {it:save} option.)    {break}

{p 8 8 2} {bf:replace} allows {it:esplot} to write over the existing vector of relative-time indicators (rarely used.)    {break}

{p 8 8 2} {bf:by(varname)} estimate coefficents seperately for each level of {it:by}. For example, {it:esplot wage years_since_policy, by(education)} will estimate the event-time coefficients for the relative time given in {it:years_since_policy} seperately for each level of {it:education} and plot as many series as there are levels of education. 

{p 8 8 2} {bf:difference} estimate coefficents relative to the base-level of {it:by}. For example, if {it:education} has {it:k} levels, then typing {it:esplot wage years_since_policy, by(education)} will estimate the event-time coefficients for the relative time given in {it:years_since_policy} seperately for each level of {it:education} and plot the difference between each of the {it:k-1} sets of event-time coefficients and the base level of the {it:by} variable.

{p 8 8 2} Using {it:difference} in combination with {it:compare} allows for the estimation of difference-in-difference-in-difference coefficients. 

{p 8 8 2} {bf:estimate_reference}  by default, {it:esplot} includes indicator variables for all relative time periods except for -1. If the {it:estimate_reference} option is specified, the indicator for -1 is included and explicitly differenced out of the rest of the coefficients. When used with {it:by}, it recenters each series indepently, so that each series is mechanically 0 at time -1.

{p 8 8 2} {bf:savedata(filename [,replace])}  in addition to plotting directly, {it:esplot} will save the estimated coefficients to {it:filename}. This allows for the greatest flexibility in plotting the estimates. Coefficents are saved {it:after} applying all operations, like differencing ({it:difference} or {it:compare}), or pooling ({it:period_length}). Can be abbreviated {it:save(...)}.

{p 8 8 2} {bf:save_sample(varname)} store the output of {it:e(sample)} in {it:varname} following the internal regression call. 

{p 4 4 2}{bf:Regression Options }

{p 8 8 2} {bf:controls(varlist)} additional control variables to be included in the internal regression call.

{p 8 8 2} {bf:absorb(varlist)} a vector of fixed effects to absorbed and not estimated in the internal regression call. {it:help reghdfe##absvar} for more information. 

{p 8 8 2} {bf:vce(vcetype, subopt))} specify the types of standard errors computed. {it:help reghdfe##opt_vce} for more information. Not compatible with {it:quantile}.

{p 8 8 2} {bf:quantile(0 < k < 100)} if this option is specified, {it:esplot} will use a quantile regression, rather than OLS. {it:quantile(50)} and {it:quantile(.5)} are synonyms, and will cause {it:esplot} to estimate a median regression. 

{p 8 8 2} weights are allowed when using OLS (default), but not when {it:quantile} is specified. 

{p 4 4 2}{bf:Display Options }

{p 8 8 2} {bf:window(start end)} display dynamic effect estimates (event-time coefficents) ranging from {it:start} to {it:end}. {it:start} should be less than zero; {it:end} should be greater than zero. 

{p 8 8 2} {bf:period_length(integer)} pool dynamic effect coefficients in groups of {it:period_length} before plotting. 

{p 8 8 2} {bf:colors(colorstylelist)} ordered list of colors; used for point estimates and confidence intervals.    {break}


{p 4 4 2}
Additional {it:twoway} options can be specified and will be passed through to the internal {it:twoway} call. {it:help twoway}options_
More complicated options are discussed below.    {break}

{p 4 4 2}{bf:Relative Event-Study Coefficients with difference and compare}

{p 4 4 2}
{bf:esplot} has two suboptions to estimate and "difference out" reference coefficients; {bf:difference} and {bf:compare}: 

{p 8 8 2} {bf:difference} plots all series relative to the base level of {bf:by}. It is helpful here to consider an example; let {bf:by} be a dummy variable that is 1 when the individual is a female, 0 when it is a male. By default, passing this variable to {bf:by} will cause two series to be estimated: one set of coefficients for males, and one for females. However, perhaps we are mainly interested in the difference in response across genders. Then, we could select the {bf:difference} option. {bf:esplot} will then estimate the male and female coefficients, but will plot their difference (female - male) in every period. 

{p 8 8 2}NB: when a using a factor variable with more than two levels with {bf:by}, stata treats the {it:lowest} value as the base case. At this time, to change the reference category, it is neccessary to create a new variable where the desired reference category is the lowest value. In the above example, we would use an indicator variable for "is male" rather than one for "is female".

{p 8 8 2} {bf:compare} takes an additional event dummy, and estimates the main event coefficients relative to this event. Here, it is also helpful to consider an example from  {browse "https://www.nber.org/papers/w26530":Cullen & Perez-Truglia, 2019}. Cullen & Perez-Truglia use the quasi-random rotation of managers across units to identify the effects of manager gender on the career progression of male and female employees. For example, they consider the effect of switching from a female manager to male manager {it:relative} to switching from a female manager to another female manager. This would be coded as {bf:... event(to_male_manager) compare(to_female_manager)...}. By including the comparison event, the authors adjust for the effects of switching managers {it:per se} and isolate the differences associated with the gender of the manager. 

{p 8 8 2} {bf:compare} and {bf:difference} can be used together. See  {browse "https://www.nber.org/papers/w26530":Cullen & Perez-Truglia, 2019} for an in depth discussion, examples, and econometric specification

{p 4 4 2}{bf:Efficiently Estimating Many Event-Study Plots: save, replace, nogen}

{p 4 4 2}
{bf:event} (and {bf:compare_}) have the sub-options {bf:save}, {bf:nogen}, and {bf:replace}, which are of primary use when estimating multiple specifications, or multiple outcomes. These options save, (and then subsequently read from the data in memory), event "lags and leads". The {bf:replace} example is provided for completeness, but should be used with caution, as it overwrites "lags and leads" saved in memory. By default, {bf:esplot} does not change the data in memory. 

{p 8 8 2} {bf:save} saves event lags {it:L<t>_<event>} (or {it:L<t>_<compare>}) and leads {it:F<t>_<event>} (or {it:F<t>_<compare>}). This sub-option can be selected for either, or both {bf:event} and {bf:compare}.

{p 8 8 2} {bf:nogen} tells {bf:esplot} that lags and leads of the above form are present in the data in memory (often as a result of selecting {bf:save} on an earlier run) and that it should use the lags and leads in memory. If lags and leads are present and {bf:nogen} (or {bf:replace} ) is not selected, {bf:esplot} will throw an error.

{p 8 8 2} {bf:replace} tells {bf:esplot} that lags and leads are present in the data and that it should overwrite them. This option should be used with caution, especially when lags and leads are user defined. There are two primary use-cases for {bf:replace}, most often used with {bf:save}. 

{p 8 8 2} - if an earlier {bf:esplot} call used {bf:save}, and the {bf:window} is adjusted. This is because {bf:esplot} calculates lags and leads only up to the endpoints given in {bf:window}. (Example 2)

{p 8 8 2} - if an earlier {bf:esplot} call used {bf:save}, and you now wish to use {bf:estimate_reference} (or vice versa). Since, {bf:esplot} only keeps the lags and leads that it needs, if {bf:save} is used without {bf:estimate_reference}, then the necessary leads for the omitted periods will not be saved. (Example 3)

{p 4 4 2}{it:Examples with save, replace, and nogen}

{p 4 4 2}
{bf:Example 1}    {break}
/} event lags and leads are saved {it:/    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) estimate_reference}    {break}
/} esplot saves time by simply using the lags/leads from the previous call {it:/    {break}
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}    {break}

{p 4 4 2}
{bf:Example 2}    {break}
/} event lags and leads are saved {it:/    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}    {break}
/} esplot saves time by simply using the lags/leads from the previous call {it:/    {break}
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}    {break}
/_we wish to expand the window of the first plot. we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them {it:/    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, replace) window(-40 60) period(6) estimate_reference}

{p 4 4 2}
{bf:Example 3}    {break}
/} event lags and leads are saved {it:/    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3)}    {break}
/} esplot saves time by simply using the lags/leads from the previous call {it:/    {break}
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}    {break}
/} There are differences in levels between males and females; we would like both series to go through the origin at t = -1.
we now want to use estimate_reference, 
so we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them {it:/    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}    {break}

{title:Remarks}

{p 4 4 2}
See  {browse "https://dballaelliott.github.io/esplot/":website} for further discussion and for examples.

{title:Acknowledgements}

{p 4 4 2}
Katherine Fang and Jenna Anders made extensive contributions to early versions of the underlying code, which this package extends. Any remaining errors are mine.

{title:Author }

{p 4 4 2}
Dylan Balla-Elliott    {break}
Research Associate, Harvard Business School    {break}
dballaelliott@gmail.com    {break}
{browse "https://github.com/dballaelliott":github} |  {browse "https://twitter.com/dballaelliott":twitter}

{title:Additional Features}

{p 4 4 2}
Bug-fixes, feature requests, and general comments are welcome via email, or directly as issues on github.    {break}

{p 4 4 2}
I currently plan on adding support for :    {break}
    - additional plot options

{p 4 4 2}
Extensions via forks/pull requests by github users are welcomed.    {break}

{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 


