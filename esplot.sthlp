{smcl}
{it:version alpha-1}

{title:esplot {hline 2} event study plots}

{title:Syntax}

{p 8 8 2} {bf:esplot} varname [{it:if}] [{it:in}]
[{it:weight}], {ul:ev}ent({it:varname [, suboptions ]}) [  {it:options} ]    {break}

{p 4 4 2}{bf:Options}

{p 8 8 2}Main Options

{col 5}Options{col 40}Description
{space 4}{hline}
{col 5}by({it:varname}){col 40}plot separate series for each group
{col 5}compare({it:varname [ ,suboptions]}){col 40}estimate event coefficients for {bf:event} relative to those of {bf:compare} {help esplot##relative_estimates:more}{col 134}{break}{col 5}difference{col 40}estimate coefficients for each series in {bf:by} relative to the base level.{col 134}{break}{col 5}{ul:control}s({it:varlist}){col 40}{it:varlist} of controls to pass to internal {help reghdfe} call.
{col 5}absorb({it:varlist}){col 40}{it:varlist} of fixed effects to absorb. see {help reghdfe}
{col 5}vce( {help reghdfe##opt_vce:vce_opts} ){col 40}{bf:vce} options from {help reghdfe}.
{space 4}{hline}
{p 8 8 2} Display Options    {break}

{col 5}Options{col 40}Description
{space 4}{hline}
{col 5}{ul:w}indow({it:start stop}){col 40}endpoints at which to truncate pre and post period.
{col 5}{ul:period}_length({it:int}){col 40}smooth over {it:x} periods. e.g.  period_length(12) plots annual estimates from monthly data.
{col 5}{ul:col}ors(  {browse "help colorstyle":colorstyle} {it:list}){col 40}manually set colors for each series
{col 5}est_plot({it:est_opts}){col 40}switch plot style of estimates. currently {it:scatter} (default) and {it:line} are supported
{col 5}ci_plot({it:ci_opts}){col 40}switch plot style of confidence intervals. currently {it:rcap} (default), {it:line}, and {it:rarea} are supported.
{col 5}{helpb twoway_options}{col 40}edit titles,  style, etc
{space 4}{hline}
{p 8 8 2} Technical Options    {break}

{col 5}Options{col 40}Description
{space 4}{hline}
{col 5}{ul:est}imate_reference{col 40}normalize by estimating and differencing out reference category.
{col 5}{ul:save}data({it:filename [, replace]}){col 40}Save event-study estimates to {it:filename}. {it:replace} allowed.
{space 4}{hline}
{p 4 4 2}
Data must be  {browse "help tsset":tsset} before calling {bf:esplot}    {break}
{ul:fweight}, {ul:pweight}, and {ul:aweight}s  allowed;  {browse "help weight":weight}    {break}

{title:Description}

{p 4 4 2}
what does {bf:esplot} do?

{title:Details}

{marker main_dets}{...}
{dlgtab:Main Options}{...}


{p 8 8 2} {bf:event} : indicator variable that takes the value 1 in the periods that an individual experiences an event (i.e. an event dummy). {bf:esplot} then estimates the event coefficients across time. Individuals may experience multiple events, or no events, over the course of the panel.    {break}

{p 8 8 2} {bf:by} : calculate event study coefficients seperately for each value of {bf:by}.     {break}

{p 8 8 2} {bf:compare} :  indicator variable that takes the value 1 in the periods that an individual experiences an event (i.e. an event dummy). In each period (and for each series specified in {bf:by_}), we estimate the relative event study coefficient {bf:event} - {bf:compare}. See  {browse "https://www.nber.org/papers/w26530":Cullen & Perez-Truglia, 2019} for an example of such a design, where the estimate of interest is the effect of switching from a female manager to male manager {it:relative} to switching from a female manager to another female manager.    {break}

{p 8 8 2} {bf:difference} plots all series relative to the base level of {bf:by}. When used without {bf:compare}, it is analogous to a difference-in-difference estimate at every time {it:t}. When used {it:with} {bf:compare}, it is analogous to a triple-difference coefficient. See  {browse "https://www.nber.org/papers/w26530":Cullen & Perez-Truglia, 2019} for an example of such a triple-difference.    {break}

{p 8 8 2} {bf:controls}, {bf:absorb}, {bf:vce} are passed directly to the internal {helpb reghdfe} call that estimates event study coefficients.    {break}

{marker disp_dets}{...}
{dlgtab:Display Options}{...}


{p 8 8 2} {bf:window}: While not required, it is strongly recommended that users provide arguments to {bf:window}. {bf:window} takes two arguments (technically an ascending  {browse "help numlist":numlist} of length 2), which are the endpoints at which to truncate pre and post period. If {bf:window} is not specificed, {bf:esplot} will try to estimate coefficients across the maximum time window present in the panel. While many of these coefficients may drop out if there are no observations, this can be costly in terms of run time. If the first argument is non-negative, {bf:esplot} will display a warning (as no preperiod will be displayed), but will still try to plot results in the passed window.    {break}

{p 8 8 2} {bf:period_length} allows for event study coefficients to be smoothed into groups of size {it:x}. For example, we could plot quarterly (or annual) estimates from a panel with monthly observations by typing {bf:period_length__(3) (or {bf:period_length__(12)). Confidence intervals and point estimates are calcuated using  {browse "help lincom":lincom}. Note that smoothing over larger time periods can lead to narrower confidence intervals, as point estimates that are individually insignificant may be jointly signifiant.     {break}

{marker tech_dets}{...}
{dlgtab:Technical Options}{...}


{p 8 8 2} {bf:estimate_reference} by default, {bf:esplot} treats {it:t = -1} (or {bf:period_length} <= {it:t} <= {it:-1}, if {bf:period_length} is specified) as the omitted category, and coefficients are calculated in reference to this time period. When {bf:estimate_reference} is specified, the estimate for the reference category is explicitly calculated, and differenced out. If {bf:by} is specified, this is done seperately for each series. In this way, each series is normalized to the origin at {it:t = -1}.In some ways, this is analogous to including a fixed-effect for each series, as it will adjust for differences in levels across groups of {bf:by} or across individuals who ever have an event and those who do not. 

{p 8 8 2} {bf:savedata} saves the point estimates, 95% confidence intervals, and p-values for all estimates for all series. This can be used to create custom graphs using twoway graph options that are not natively supported by {bf:esplot}. The data are labeled to make plotting simple. {it:replace} is allowed. see  {browse "https://dballaelliott.github.io/esplot/":online examples} for example workflow    {break}

{p 4 4 2}
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
/* event lags and leads are saved */    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) estimate_reference}    {break}
/* esplot saves time by simply using the lags/leads from the previous call */    {break}
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}    {break}

{p 4 4 2}
{bf:Example 2}    {break}
/* event lags and leads are saved */    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}    {break}
/* esplot saves time by simply using the lags/leads from the previous call */    {break}
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}    {break}
/*we wish to expand the window of the first plot. we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them */    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, replace) window(-40 60) period(6) estimate_reference}

{p 4 4 2}
{bf:Example 3}    {break}
/* event lags and leads are saved */    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3)}    {break}
/* esplot saves time by simply using the lags/leads from the previous call */    {break}
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}    {break}
/* There are differences in levels between males and females; we would like both series to go through the origin at t = -1.
we now want to use estimate_reference, 
so we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them */    {break}
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}    {break}

{title:Remarks}

{p 4 4 2}
See  {browse "https://dballaelliott.github.io/esplot/":website} for further discussion and for examples.

{title:Stored results}


{p 4 4 2}
{bf:esplot} provides the following in {bf:e()}:

{p 4 4 2}
From internal {helpb reghdfe} call to estimate event study coefficients:

{p 4 4 2}
Scalars

{p 8 8 2} {bf:r(N)}: number of observations 

{p 4 4 2}
Macros

{p 4 4 2}
Matrices

{p 4 4 2}
Functions

{title:Acknowledgements}

{p 4 4 2}
This package was developed as an extension of code written for Cullen, Zoë B., and Ricardo Perez-Truglia. {it:The Old Boys{c 39} Club: Schmoozing and the Gender Gap.} No. {browse "https://www.nber.org/papers/w26530":w26530}. NBER, 2019. in my capacity as a research assistant to the authors. 

{p 4 4 2}
Katherine Fang and Jenna Anders made extensive contributions to early versions of the underlying code, which this package extends. Zoë Cullen and Ricardo Perez-Truglia guided development. Any remaining errors are mine

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
    - bounds on attrition/sample selection (Lee, 2009) for single-event plots
    - the extension of the above to "differenced" event-study plots as discussed in Cullen & Perez-Truglia (2019)
    - additional plot options

{p 4 4 2}
Extensions via forks/pull requests by github users are welcomed.    {break}

{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 


