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
  
### Relative Event-Study Coefficients with difference and compare

__esplot__ has two suboptions to estimate and "difference out" reference coefficients; __difference__ and __compare__: 

> __difference__ plots all series relative to the base level of __by__. It is helpful here to consider an example; let __by__ be a dummy variable that is 1 when the individual is a female, 0 when it is a male. By default, passing this variable to __by__ will cause two series to be estimated: one set of coefficients for males, and one for females. However, perhaps we are mainly interested in the difference in response across genders. Then, we could select the __difference__ option. __esplot__ will then estimate the male and female coefficients, but will plot their difference (female - male) in every period. 

>NB: when a using a factor variable with more than two levels with __by__, stata treats the _lowest_ value as the base case. At this time, to change the reference category, it is neccessary to create a new variable where the desired reference category is the lowest value. In the above example, we would use an indicator variable for "is male" rather than one for "is female".

> __compare__ takes an additional event dummy, and estimates the main event coefficients relative to this event. Here, it is also helpful to consider an example from [Cullen & Perez-Truglia, 2019](https://www.nber.org/papers/w26530). Cullen & Perez-Truglia use the quasi-random rotation of managers across units to identify the effects of manager gender on the career progression of male and female employees. For example, they consider the effect of switching from a female manager to male manager _relative_ to switching from a female manager to another female manager. This would be coded as __... event(to_male_manager) compare(to_female_manager)...__. By including the comparison event, the authors adjust for the effects of switching managers _per se_ and isolate the differences associated with the gender of the manager. 

> __compare__ and __difference__ can be used together. See [Cullen & Perez-Truglia, 2019](https://www.nber.org/papers/w26530) for an in depth discussion, examples, and econometric specification

### Efficiently Estimating Many Event-Study Plots: save, replace, nogen

__event__ (and __compare__) have the sub-options __save__, __nogen__, and __replace__, which are of primary use when estimating multiple specifications, or multiple outcomes. These options save, (and then subsequently read from the data in memory), event "lags and leads". The __replace__ example is provided for completeness, but should be used with caution, as it overwrites "lags and leads" saved in memory. By default, __esplot__ does not change the data in memory. 

> __save__ saves event lags _L<t>_<event>_ (or _L<t>_<compare>_) and leads _F<t>_<event>_ (or _F<t>_<compare>_). This sub-option can be selected for either, or both __event__ and __compare__.

> __nogen__ tells __esplot__ that lags and leads of the above form are present in the data in memory (often as a result of selecting __save__ on an earlier run) and that it should use the lags and leads in memory. If lags and leads are present and __nogen__ (or __replace__ ) is not selected, __esplot__ will throw an error.

> __replace__ tells __esplot__ that lags and leads are present in the data and that it should overwrite them. This option should be used with caution, especially when lags and leads are user defined. There are two primary use-cases for __replace__, most often used with __save__. 
 
> - if an earlier __esplot__ call used __save__, and the __window__ is adjusted. This is because __esplot__ calculates lags and leads only up to the endpoints given in __window__. (Example 2)

> - if an earlier __esplot__ call used __save__, and you now wish to use __estimate_reference__ (or vice versa). Since, __esplot__ only keeps the lags and leads that it needs, if __save__ is used without __estimate_reference__, then the necessary leads for the omitted periods will not be saved. (Example 3)

#### Examples with save, replace, and nogen

__Example 1__  
/* event lags and leads are saved */  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) estimate_reference}  
/* esplot saves time by simply using the lags/leads from the previous call */  
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}  

__Example 2__  
/* event lags and leads are saved */  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}  
/* esplot saves time by simply using the lags/leads from the previous call */  
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}  
/*we wish to expand the window of the first plot. we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them */  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, replace) window(-40 60) period(6) estimate_reference}

__Example 3__  
/* event lags and leads are saved */  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3)}  
/* esplot saves time by simply using the lags/leads from the previous call */  
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}  
/* There are differences in levels between males and females; we would like both series to go through the origin at t = -1.
we now want to use estimate_reference, 
so we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them */  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}  

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

This package was developed as an extension of code written for  
Cullen, Zoë B., and Ricardo Perez-Truglia. _The Old Boys' Club: Schmoozing and the Gender Gap._ No.[w26530](https://www.nber.org/papers/w26530). NBER, 2019.  
in my capacity as a research assistant to the authors.  

Katherine Fang and Jenna Anders made extensive contributions to early versions of the underlying code, which this package extends. Zoë Cullen and Ricardo Perez-Truglia guided development. Any remaining errors are mine.

## Author 

Dylan Balla-Elliott  
Research Associate, Harvard Business School  
dballaelliott@gmail.com  
[github](https://github.com/dballaelliott) | [twitter](https://twitter.com/dballaelliott)

## Additional Features

Bug-fixes, feature requests, and general comments are welcome via email, or directly as issues on github.  

I currently plan on adding support for :  
    - bounds on attrition/sample selection (Lee, 2009) for single-event plots
    - the extension of the above to "differenced" event-study plots as discussed in Cullen & Perez-Truglia (2019)
    - additional plot options

Extensions via forks/pull requests by github users are welcomed.  

- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 
