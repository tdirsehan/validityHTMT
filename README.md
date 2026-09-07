# validityHTMT

A jamovi module for assessing discriminant validity with **HTMT+**, the absolute-correlation variant of the Heterotrait-Monotrait ratio of correlations.

Developed by Prof. Dr. Taşkın Dirsehan.

## Current features

- Up to 8 reflective constructs.
- Native jamovi indicator-assignment controls only; no custom DOM/UI workaround is required.
- User-defined construct names.
- Pearson or Spearman correlations.
- Pairwise-complete or complete-case missing-data handling.
- Square HTMT+ matrix.
- Optional pairwise interpretation table.
- Selectable 0.85 or 0.90 decision threshold.
- Checks for repeated indicators and constructs with fewer than two items.
- Safe numeric conversion of jamovi ordinal/integer variables with `jmvcore::toNumeric()`.
- Informative handling of insufficient complete cases and non-estimable correlations.

## HTMT+ implemented

For constructs A and B:

HTMT+(A,B) = mean(|r_ij|, i in A, j in B) / sqrt(mean(|r_ij|, i != j in A) * mean(|r_ij|, i != j in B))

This module deliberately uses absolute indicator correlations. This variant is commonly called **HTMT+**. It differs from the signed-correlation equation originally presented by Henseler, Ringle, and Sarstedt (2015) and avoids cancellation when positive and negative indicator correlations occur.

## Example data and usage

A fully synthetic dataset is provided at `examples/htmt_example.csv`.

Suggested review workflow:

1. Open `examples/htmt_example.csv` in jamovi.
2. Open `Factor` -> `Validity` -> `Discriminant Validity (HTMT+)`.
3. Assign `C1_1` to `C1_4` to Construct 1.
4. Assign `C2_1` to `C2_4` to Construct 2.
5. Optionally assign `C3_1` to `C3_4` to Construct 3.
6. Inspect the HTMT+ matrix and the optional pairwise interpretation table.
7. Repeat with Pearson/Spearman, 0.85/0.90 thresholds, and pairwise/complete-case missing-data handling.

The example file contains no real participant data.

### Fixed numerical benchmarks for the example file

Pearson HTMT+:

| Pair | Expected value |
| --- | ---: |
| C1-C2 | 0.30525247 |
| C1-C3 | 0.20524750 |
| C2-C3 | 0.29918240 |

Spearman HTMT+:

| Pair | Expected value |
| --- | ---: |
| C1-C2 | 0.28122732 |
| C1-C3 | 0.21208079 |
| C2-C3 | 0.29532938 |

These values are hard-coded in the automated tests so that numerical regressions are detected rather than only checking broad thresholds.

## Build and install

Prerequisites: jamovi, R, and jmvtools.

```r
install.packages(
    'jmvtools',
    repos = c('https://repo.jamovi.org', 'https://cran.r-project.org')
)
setwd('/path/to/validityHTMT')
jmvtools::prepare()
jmvtools::check()
jmvtools::install()
```

`jmvtools::install()` creates a platform-specific `.jmo` file and installs it into the running jamovi application.

## Testing

The core test suite covers:

- exact Pearson HTMT+ benchmark values;
- exact Spearman HTMT+ benchmark values;
- invariance to indicator sign reversal;
- insufficient complete cases;
- zero-variance indicators;
- non-syntactic variable names, including spaces, `@`, and Turkish characters;
- duplicated indicators;
- constructs with too few indicators;
- unknown indicator names.

Run locally with:

```r
testthat::test_dir('tests/testthat')
```

## v0.2.1 status

This is a community/experimental release candidate.

The v0.2.1 review branch removes the experimental custom JavaScript/DOM construct controls used in v0.2.0 and relies only on native jamovi UI components. The statistical backend remains available for up to 8 constructs.

Known limitations:

- bootstrap confidence intervals / HTMT inference are not yet implemented;
- polychoric correlations are not yet implemented;
- only reflective multi-item constructs are intended.

## References

Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in variance-based structural equation modeling. *Journal of the Academy of Marketing Science*, *43*(1), 115-135.

Ringle, C. M., Sarstedt, M., Sinkovics, N., & Sinkovics, R. R. (2023). A perspective on using partial least squares structural equation modelling in data articles. *Data in Brief*, *48*, 109074.

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
- Added handling for non-syntactic variable names.
- Added a synthetic review dataset and explicit usage instructions.

### v0.2.1
- Renamed the implemented statistic explicitly as HTMT+.
- Added Ringle et al. (2023) to methodological references.
- Replaced `as.numeric()` with `jmvcore::toNumeric()` for jamovi-safe numeric conversion.
- Added complete-case guards and correlation error handling.
- Preserved non-estimable-correlation warnings instead of overwriting them.
- Added exact-value Pearson and Spearman regression tests and edge-case tests.
- Removed custom JavaScript/DOM UI manipulation from the review build.
