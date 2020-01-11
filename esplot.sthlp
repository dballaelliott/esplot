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

{p 4 4 2}{bf:Normalizing with estimate_reference }

{p 4 4 2}
fill in

{p 4 4 2}{bf:Relative Event-Study Coefficients with compare and difference}

{p 4 4 2}
fill in

{p 4 4 2}{bf:Event Indicator Sub-Options: save, replace, nogen}

{p 4 4 2}
fill in

{p 4 4 2}{bf:est_opts and ci_opts}

{p 4 4 2}
fill in

{p 4 4 2}{bf:Custom plots with savedata}

{p 4 4 2}
fill in

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
Link to Old Boy{c 39}s Club paper, etc. 

{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 



