_version alpha-1_

# esplot {hline 2} event study plots

## Syntax

> __esplot__ varname [_if_] [_in_]
[_weight_], **ev**ent(_varname [, suboptions ]_) [  _options_ ]  
  
### Options

>Main Options
  
| Options | Description |
|-----------------------------------| ----------------------------------------------------------------------------------------------|
|by(_varname_)                      | plot separate series for each group |
|compare(_varname [ ,suboptions]_)  | estimate event coefficients for __event__ relative to those of __compare__ {help esplot##relative_estimates:more} |  
| difference |  estimate coefficients for each series in __by__ relative to the base level.  |  
| **control**s(_varlist_)  | _varlist_ of controls to pass to internal {help reghdfe} call.|
|absorb(_varlist_)         | _varlist_ of fixed effects to absorb. see {help reghdfe} |
|vce( {help reghdfe##opt_vce:vce_opts} ) | __vce__ options from {help reghdfe}.| 

> Display Options  

| Options | Description |
|-----------------------------------| ----------------------------------------------------------------------------------|
| **w**indow(_start stop_)        | endpoints at which to truncate pre and post period.  |
| **period**_length(_int_) | smooth over _x_ periods. e.g.  period_length(12) plots annual estimates from monthly data.|
|**col**ors( [colorstyle](help colorstyle) _list_)    | manually set colors for each series | 
|est_plot(_est_opts_)  | switch plot style of estimates. currently _scatter_ (default) and _line_ are supported |
|ci_plot(_ci_opts_)  | switch plot style of confidence intervals. currently _rcap_ (default), _line_, and _rarea_ are supported. |
|   {helpb twoway_options}   | edit titles,  style, etc |

> Technical Options  

| Options               | Description   |
|-----------------------------------| ----------------------------------------------------------------------------------|
|**est**imate_reference | normalize by estimating and differencing out reference category.|
|**save**data(_filename [, replace]_) | Save event-study estimates to _filename_. _replace_ allowed. |
  
Data must be [tsset](help tsset) before calling __esplot__  
**fweight**, **pweight**, and **aweight**s  allowed; [weight](help weight)  

## Description

what does __esplot__ do?

## Details

{marker main_dets}{...}
{dlgtab:Main Options}{...}


> __event__ : indicator variable that takes the value 1 in the periods that an individual experiences an event (i.e. an event dummy). __esplot__ then estimates the event coefficients across time. Individuals may experience multiple events, or no events, over the course of the panel.  

> __by__ : calculate event study coefficients seperately for each value of __by__.   
 
> __compare__ :  indicator variable that takes the value 1 in the periods that an individual experiences an event (i.e. an event dummy). In each period (and for each series specified in __by__), we estimate the relative event study coefficient __event__ - __compare__. See [Cullen & Perez-Truglia, 2019](https://www.nber.org/papers/w26530) for an example of such a design, where the estimate of interest is the effect of switching from a female manager to male manager _relative_ to switching from a female manager to another female manager.  

> __difference__ plots all series relative to the base level of __by__. When used without __compare__, it is analogous to a difference-in-difference estimate at every time _t_. When used _with_ __compare__, it is analogous to a triple-difference coefficient. See [Cullen & Perez-Truglia, 2019](https://www.nber.org/papers/w26530) for an example of such a triple-difference.  

> __controls__, __absorb__, __vce__ are passed directly to the internal {helpb reghdfe} call that estimates event study coefficients.  

{marker disp_dets}{...}
{dlgtab:Display Options}{...}


> __window__: While not required, it is strongly recommended that users provide arguments to __window__. __window__ takes two arguments (technically an ascending [numlist](help numlist) of length 2), which are the endpoints at which to truncate pre and post period. If __window__ is not specificed, __esplot__ will try to estimate coefficients across the maximum time window present in the panel. While many of these coefficients may drop out if there are no observations, this can be costly in terms of run time. If the first argument is non-negative, __esplot__ will display a warning (as no preperiod will be displayed), but will still try to plot results in the passed window.  

> __period_length__ allows for event study coefficients to be smoothed into groups of size _x_. For example, we could plot quarterly (or annual) estimates from a panel with monthly observations by typing __period_length__(3) (or __period_length__(12)). Confidence intervals and point estimates are calcuated using [lincom](help lincom). Note that smoothing over larger time periods can lead to narrower confidence intervals, as point estimates that are individually insignificant may be jointly signifiant.   

{marker tech_dets}{...}
{dlgtab:Technical Options}{...}


> __estimate_reference__ by default, __esplot__ treats _t = -1_ (or __period_length__ <= _t_ <= _-1_, if __period_length__ is specified) as the omitted category, and coefficients are calculated in reference to this time period. When __estimate_reference__ is specified, the estimate for the reference category is explicitly calculated, and differenced out. If __by__ is specified, this is done seperately for each series. In this way, each series is normalized to the origin at _t = -1_.In some ways, this is analogous to including a fixed-effect for each series, as it will adjust for differences in levels across groups of __by__ or across individuals who ever have an event and those who do not. 

> __savedata__ saves the point estimates, 95% confidence intervals, and p-values for all estimates for all series. This can be used to create custom graphs using twoway graph options that are not natively supported by __esplot__. The data are labeled to make plotting simple. _replace_ is allowed. see [online examples](https://dballaelliott.github.io/esplot/) for example workflow  

More complicated options are discussed below.  
  
### Normalizing with estimate_reference 

fill in

### Relative Event-Study Coefficients with compare and difference

fill in

### Event Indicator Sub-Options: save, replace, nogen

fill in

### est_opts and ci_opts

fill in

### Custom plots with savedata

fill in

## Remarks

See [website](https://dballaelliott.github.io/esplot/) for further discussion and for examples.

## Stored results


__esplot__ provides the following in __e()__:

From internal {helpb reghdfe} call to estimate event study coefficients:

Scalars

> __r(N)__: number of observations 

Macros

Matrices

Functions

## Acknowledgements

Link to Old Boy's Club paper, etc. 

- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 

