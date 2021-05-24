---
name: Bug report
about: Create a report to help us improve
title: "[BUG REPORT]: Bug Description"
labels: bug
assignees: ''

---
**Before opening an issue, please run `ado update esplot, update` to make sure you are running the most up-to-date version of the package!**

Since `esplot` is in active development, I ship bugfixes relatively frequently, and it's possible that someone else has already run into your problem. If not, please leave an issue and I'll see what I can do!  

**Describe the bug**
A clear and concise description of what the bug is & what you were trying to do. 

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Uploading a .log file will make it much quicker for me to patch the bug!**
Following these steps will make debugging *much* more efficient! 

Please create a `debug_esplot.log` file using the following steps: 
1. `set trace on`
2. `log using debug_esplot.log`
3. `<your command>`
4. `log close`
