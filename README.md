# validityHTMT

A jamovi module for assessing discriminant validity with the Heterotrait-Monotrait ratio of correlations (HTMT).

Developed by Prof. Dr. Taşkın Dirsehan.

## Current features

- Dynamic construct creation with a **+ Construct** button.
- No hard-coded upper limit on the number of constructs.
- **Reset** button to clear all analysis inputs and return to the default two empty construct blocks.
- Drag-and-drop assignment of indicators to each construct.
- Pearson or Spearman correlations.
- Pairwise-complete or complete-case missing-data handling.
- Dynamic square HTMT matrix.
- Optional pairwise interpretation table.
- Selectable 0.85 or 0.90 decision threshold.
- The selected threshold is shown as a note below the pairwise assessment table rather than as a repeated table column.
- Checks for repeated indicators and constructs with fewer than two items.

## Dynamic constructs (v0.2.0 beta)

The analysis opens with two empty construct blocks. Clicking **+ Construct** appends another construct block. Constructs can be added as needed rather than being predeclared as Construct 1 through Construct 8.

The **Reset** button clears the construct assignments and restores the analysis options to their defaults: Pearson correlation, pairwise-complete observations, HTMT threshold 0.90, and the pairwise assessment table enabled.

For compatibility with jamovi's dynamic option system, constructs are stored as an `Array` whose items are variable sets. The HTMT matrix is rendered dynamically so its dimensions follow the number of non-empty constructs.

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

1. Compile and test the v0.2.0 dynamic-construct beta on jamovi 2.4.x and a current jamovi release.
2. Verify the **+ Construct** and **Reset** interactions in the target jamovi versions.
3. Compare several datasets against SmartPLS / ADANCO / independent R implementations of HTMT.
4. Add bootstrap confidence intervals (HTMT inference) as a second-stage feature.
5. Consider polychoric correlations for ordinal indicators.
6. Add example `.omv` data and documentation before jamovi Library submission.

## Reference

Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in variance-based structural equation modeling. *Journal of the Academy of Marketing Science*, *43*(1), 115–135.

## Version history

### v0.2.0 beta
- Replaced the fixed eight-construct interface with dynamic construct blocks.
- Added a **+ Construct** button.
- Removed the hard-coded construct-count limit.
- Added a **Reset** button that clears analysis inputs and restores default settings.
- Removed the repeated Threshold column from the pairwise table; the selected threshold is shown below the table as a note.
- Changed the HTMT matrix to a dynamic HTML matrix so rows and columns grow with the construct list.

### v0.1.7
- Prepared source repository for public release and added build-artifact exclusions.

### v0.1.6
- Added the Henseler, Ringle, and Sarstedt (2015) reference to the jamovi output.

### v0.1.5
- Fixed jamovi 2.4.x result-table population by using `addRow()` after `deleteRows()`.
