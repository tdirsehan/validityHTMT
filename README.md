# validityHTMT

A jamovi module for assessing discriminant validity with the Heterotrait-Monotrait ratio of correlations (HTMT).

Developed by Prof. Dr. Taşkın Dirsehan.

## Current features

- Up to 8 reflective constructs.
- Drag-and-drop assignment of indicators to constructs.
- User-defined construct names.
- Pearson or Spearman correlations.
- Pairwise-complete or complete-case missing-data handling.
- Square HTMT matrix.
- Optional pairwise interpretation table.
- Selectable 0.85 or 0.90 decision threshold.
- Checks for repeated indicators and constructs with fewer than two items.

## HTMT implemented

For constructs A and B:

HTMT(A,B) = mean(|r_ij|, i in A, j in B) / sqrt(mean(|r_ij|, i != j in A) * mean(|r_ij|, i != j in B))

This is the commonly used absolute-correlation form of the original HTMT diagnostic.

## Build and install

Prerequisites: current jamovi, R, and jmvtools.

```r
install.packages('jmvtools', repos='https://repo.jamovi.org')
setwd('/path/to/validityHTMT')
jmvtools::prepare()
jmvtools::check()
jmvtools::install()
```

`jmvtools::install()` creates a platform-specific `.jmo` file and installs it into the running jamovi application.

## Suggested validation before release

1. Compare several datasets against SmartPLS / ADANCO / R implementations of HTMT.
2. Add bootstrap confidence intervals (HTMT inference) as a second-stage feature.
3. Consider polychoric correlations for ordinal indicators.
4. Add example `.omv` data and documentation before library submission.

## Reference

Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in variance-based structural equation modeling. *Journal of the Academy of Marketing Science*, *43*(1), 115–135.

## v0.1.2 compatibility fix

The jamovi analysis schema uses `permitted: [numeric]` for numeric variable targets, while `continuous` and `ordinal` are measure-type suggestions. The UI variable supplier has also been reorganized so all construct indicator targets are children of a single numeric VariableSupplier.


## v0.1.4 compatibility note

The custom UI no longer uses `populate: manual` for `VariableSupplier`. In jamovi this property requires a JavaScript `updated` event handler; the module does not need manual supplier population, so automatic population is used for compatibility with jamovi 2.4.x.


## v0.1.5
- Fixed jamovi 2.4.x result-table population: tables now use `addRow()` after `deleteRows()` instead of calling `setRow()` on zero-row tables.


## v0.1.6
- Added a References section to the jamovi output with the Henseler, Ringle, and Sarstedt (2015) HTMT article.


## v0.1.7
- Prepared source repository for public release: aligned version metadata and added `.gitignore` for build artifacts.
