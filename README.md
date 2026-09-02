# validityHTMT

A jamovi module for assessing discriminant validity with the Heterotrait-Monotrait ratio of correlations (HTMT).

Developed by Prof. Dr. Taşkın Dirsehan.

## Current features

- Up to 8 reflective constructs.
- Native jamovi indicator assignment controls.
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

## Example data and usage

A fully synthetic dataset is provided at `examples/htmt_example.csv`.

Suggested review workflow:

1. Open `examples/htmt_example.csv` in jamovi.
2. Open `Factor` -> `Validity` -> `Discriminant Validity (HTMT)`.
3. Assign `C1_1` to `C1_4` to Construct 1.
4. Assign `C2_1` to `C2_4` to Construct 2.
5. If using a third construct, assign `C3_1` to `C3_4` to Construct 3.
6. Inspect the HTMT matrix and the optional pairwise interpretation table.
7. Repeat with Pearson/Spearman, 0.85/0.90 thresholds, and pairwise/complete-case missing-data handling as desired.

The example file contains no real participant data.

## Build and install

Prerequisites: jamovi, R, and jmvtools.

```r
install.packages('jmvtools', repos='https://repo.jamovi.org')
setwd('/path/to/validityHTMT')
jmvtools::prepare()
jmvtools::check()
jmvtools::install()
```

`jmvtools::install()` creates a platform-specific `.jmo` file and installs it into the running jamovi application.

## v0.2.0 status

This is an early community/experimental release candidate. The statistical core uses the fixed construct options `c1` to `c8` for compatibility with older jamovi releases. The current UI work aims to present two constructs initially and reveal additional predeclared constructs on demand while preserving jamovi's native indicator-transfer behaviour.

Known limitation: the compact `+ Construct` / reset UI is a compatibility-oriented enhancement and should be reviewed across jamovi versions. The underlying HTMT calculation remains available for up to 8 constructs.

Independent numerical cross-validation against additional HTMT implementations is planned as a subsequent development step. Reviewers should therefore treat this version as an early community/experimental candidate rather than a mature curated release.

## Reference

Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in variance-based structural equation modeling. *Journal of the Academy of Marketing Science*, *43*(1), 115–135.

## Version notes

### v0.1.2
- Corrected numeric variable target metadata and reorganized construct targets under a single VariableSupplier.

### v0.1.4
- Removed unnecessary `populate: manual` usage for compatibility with jamovi 2.4.x.

### v0.1.5
- Fixed jamovi 2.4.x result-table population using `addRow()` after `deleteRows()`.

### v0.1.6
- Added the Henseler, Ringle, and Sarstedt (2015) reference to the output.

### v0.1.7
- Aligned public-release metadata and added `.gitignore` entries for build artifacts.

### v0.2.0
- Added the experimental compact construct UI work while retaining the stable fixed-option statistical backend.
- Added handling for non-syntactic variable names (for example names beginning with `@`).
- Added a synthetic review dataset and explicit usage instructions for library submission.
