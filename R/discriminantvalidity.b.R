# This file is a generated template; edits are preserved by jmvtools::prepare().

#' Discriminant Validity (HTMT+)
#'
#' Computes the absolute-correlation variant of the Heterotrait-Monotrait
#' ratio of correlations (HTMT+).
#'
#' @export
discriminantValidityClass <- R6::R6Class(
    "discriminantValidityClass",
    inherit = discriminantValidityBase,
    private = list(

        .collectConstructs = function() {
            sets <- list(
                self$options$c1, self$options$c2, self$options$c3, self$options$c4,
                self$options$c5, self$options$c6, self$options$c7, self$options$c8
            )
            constructLabels <- c(
                self$options$n1, self$options$n2, self$options$n3, self$options$n4,
                self$options$n5, self$options$n6, self$options$n7, self$options$n8
            )

            keep <- vapply(sets, length, integer(1)) > 0
            sets <- sets[keep]
            constructLabels <- constructLabels[keep]

            constructLabels <- trimws(constructLabels)
            empty <- is.na(constructLabels) | constructLabels == ""
            constructLabels[empty] <- paste0("Construct ", which(empty))

            list(
                sets = sets,
                names = make.unique(constructLabels)
            )
        },

        .run = function() {
            self$results$references$setContent(
                paste0(
                    "<p>Henseler, J., Ringle, C. M., &amp; Sarstedt, M. (2015). ",
                    "A new criterion for assessing discriminant validity in variance-based structural equation modeling. ",
                    "<i>Journal of the Academy of Marketing Science</i>, <i>43</i>(1), 115&ndash;135.</p>",
                    "<p>Ringle, C. M., Sarstedt, M., Sinkovics, N., &amp; Sinkovics, R. R. (2023). ",
                    "A perspective on using partial least squares structural equation modelling in data articles. ",
                    "<i>Data in Brief</i>, <i>48</i>, 109074.</p>"
                )
            )

            spec <- private$.collectConstructs()
            sets <- spec$sets
            constructNames <- spec$names

            self$results$instructions$setContent(
                paste0(
                    "<p>Select at least two reflective constructs. Each selected construct must contain at least two indicators. ",
                    "This module computes <b>HTMT+</b>, the absolute-correlation variant of HTMT: the mean absolute ",
                    "heterotrait-heteromethod correlation divided by the geometric mean of the two mean absolute ",
                    "monotrait-heteromethod correlations.</p>"
                )
            )

            if (length(sets) < 2)
                return()

            if (any(vapply(sets, length, integer(1)) < 2)) {
                self$results$htmtMatrix$setError(
                    "Each selected construct must contain at least two indicators."
                )
                return()
            }

            allVars <- unlist(sets, use.names = FALSE)
            duplicatedVars <- unique(allVars[duplicated(allVars)])

            if (length(duplicatedVars) > 0) {
                self$results$htmtMatrix$setError(
                    paste0(
                        "An indicator can belong to only one construct. Duplicated indicator(s): ",
                        paste(duplicatedVars, collapse = ", ")
                    )
                )
                return()
            }

            dat <- self$data[, allVars, drop = FALSE]

            # jamovi may expose ordinal/integer variables as factors with
            # underlying numeric values. toNumeric() is the recommended
            # conversion and avoids factor-level coding errors.
            dat <- as.data.frame(
                lapply(dat, jmvcore::toNumeric),
                check.names = FALSE
            )
            names(dat) <- allVars

            if (nrow(dat) < 2) {
                self$results$htmtMatrix$setError(
                    "At least two observations are required."
                )
                return()
            }

            use <- if (
                identical(self$options$missing, "complete")
            ) {
                "complete.obs"
            } else {
                "pairwise.complete.obs"
            }

            method <- if (
                identical(self$options$correlation, "spearman")
            ) {
                "spearman"
            } else {
                "pearson"
            }

            if (
                identical(use, "complete.obs") &&
                sum(stats::complete.cases(dat)) < 2
            ) {
                self$results$htmtMatrix$setError(
                    "HTMT+ could not be estimated because fewer than two complete observations remain."
                )
                self$results$notes$setContent(
                    "<p><b>Warning:</b> Complete-case analysis requires at least two observations with no missing values across all selected indicators.</p>"
                )
                return()
            }

            R <- tryCatch(
                suppressWarnings(
                    stats::cor(
                        dat,
                        use = use,
                        method = method
                    )
                ),
                error = function(e) e
            )

            if (inherits(R, "error")) {
                self$results$htmtMatrix$setError(
                    paste0(
                        "HTMT+ correlations could not be estimated: ",
                        conditionMessage(R)
                    )
                )
                return()
            }

            warningMessages <- character()

            if (any(!is.finite(R))) {
                warningMessages <- c(
                    warningMessages,
                    "Some correlations could not be estimated. Check zero-variance indicators, sparse pairwise overlap, and missing data."
                )
            }

            # Use the same shared HTMT+ core that is covered by the numerical
            # regression tests, avoiding a second independent formula copy.
            namedSets <- sets
            names(namedSets) <- constructNames
            M <- htmt_from_correlation(R, namedSets)
            k <- length(sets)

            # Eight columns are predeclared for compatibility with older jamovi
            # compilers, including jamovi 2.4.x.
            tab <- self$results$htmtMatrix
            tab$deleteRows()

            for (i in seq_len(k)) {
                vals <- list(construct = constructNames[i])

                for (j in seq_len(k))
                    vals[[paste0("c", j)]] <- M[i, j]

                tab$addRow(
                    rowKey = paste0("construct_", i),
                    values = vals
                )
            }

            cut <- if (
                identical(self$options$threshold, "strict85")
            ) {
                0.85
            } else {
                0.90
            }

            pairTab <- self$results$pairTable
            pairTab$deleteRows()
            rowNo <- 1

            for (i in seq_len(k - 1)) {
                for (j in (i + 1):k) {
                    h <- M[i, j]

                    assessment <- if (!is.finite(h)) {
                        "Not estimable"
                    } else if (h < cut) {
                        "Discriminant validity supported"
                    } else {
                        "Potential discriminant validity problem"
                    }

                    pairTab$addRow(
                        rowKey = paste0("pair_", rowNo),
                        values = list(
                            constructA = constructNames[i],
                            constructB = constructNames[j],
                            htmt = h,
                            threshold = cut,
                            assessment = assessment
                        )
                    )

                    rowNo <- rowNo + 1
                }
            }

            methodLabel <- if (
                method == "pearson"
            ) {
                "Pearson"
            } else {
                "Spearman"
            }

            missingLabel <- if (
                use == "complete.obs"
            ) {
                "complete cases"
            } else {
                "pairwise complete observations"
            }

            notes <- paste0(
                "<p>Method: HTMT+ using absolute indicator correlations; correlation: ",
                methodLabel,
                "; missing data: ",
                missingLabel,
                "; decision threshold: ",
                sprintf("%.2f", cut),
                ". Values below the selected threshold are conventionally interpreted as supporting discriminant validity. ",
                "The threshold should be treated as a diagnostic rather than a mechanical proof.</p>"
            )

            if (length(warningMessages) > 0) {
                notes <- paste0(
                    notes,
                    paste0(
                        "<p><b>Warning:</b> ",
                        warningMessages,
                        "</p>",
                        collapse = ""
                    )
                )
            }

            self$results$notes$setContent(notes)
        }
    )
)
