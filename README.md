# esplot: a stata package for event study plots


**NOTE: this package is outdated. It estimates dynamic DiD coefficients via TWFE. While this was the standard approach for many years, it is now known to be quite fragile. See [What’s Trending in Difference-in-Differences? A Synthesis of the Recent Econometrics Literature](https://www.jonathandroth.com/assets/files/DiD_Review_Paper.pdf) for a discussion of why these TWFE specifications are difficult to interpret, and not generally an appropriate specification with more than one treatment date.** 

Excellent packages exist that implement DiD/event study estimation using the new, robust methods. **You should not use this code.**  Instead use should use the [stata package](https://friosavila.github.io/playingwithstata/main_csdid.html) `cs_did` or the [R package](https://cran.r-project.org/web/packages/did/vignettes/did-basics.html) `did`.  


_This repository exists for backward compatability and documentation of an existing command_


Event study plots are increasingly popular in applied research. `esplot` is a new command for stata allowing researchers to quickly and easily create event study plots.


## Install

1. Install from within stata

   `net install esplot, from("https://raw.githubusercontent.com/dballaelliott/esplot/pkg/") replace`

*OR* 2. Download/clone this repository

#### Examples

The `example` folder contains a .do file and a .csv with example data. Users may find it useful to download the folder and run (or simply browse) `make_examples.do` for sample syntax.

These data can also be used to experiment with the examples provided on the help [site](https://dballaelliott.github.io/esplot). Note that `example.csv` uses the same variable names for ease of use, but that the values have been randomized, so plots may not align with the example images.

## Additional Information

See [site](https://dballaelliott.github.io/esplot) for introduction and overview.

Type `help esplot` after installation for internal stata help documentation.

### New Features

**`esplot` 0.10.0 (late May 2021).** Continuous treatment is now allowed when using panel data syntax. That is, the values of `event` and `compare` can be other than 0 and 1.  
**`esplot` 0.9.5 (early March 2021).** Lets users specify `saturate` or `bin` to control how endpoints are treated.   
**`esplot` 0.9.1 (late Feb 2021).** Adds support for alternate syntax when data cannot be `tsset` (i.e. are not panel data).  
**`esplot` 0.7.1 (late Nov 2020).** Adds support for quantile regression.  

#### Endpoints
As of **`esplot` 0.9.0**, leads and lags outside of the specified `window` are estimated, but not displayed. **This is a change to the default; in earlier versions, periods outside the window were binned together.** The old functionality is available by specifying the suboption `bin` to window with `window(start end, bin)`. But think before you bin! This forces the dynamic effects to be constant outside of the specified window. If you're comfortable with that restriction, it can help with the identification of time fixed effects, but if this assumption is violated, it can cause the dynamic effects _within the window_ to be misidentified. See the [docs](https://dballaelliott.github.io/esplot/options/#general-options) for more information on these suboptions.  
### For users of older versions of Stata

Currently, this project nominally supports Stata versions as early as 11.
However, I've mostly developed and tested this program, especially the graphics, in Stata 16 and later.
I've tried to test that core functionality works in older versions, but I can't guarantee that I haven't missed anything.
