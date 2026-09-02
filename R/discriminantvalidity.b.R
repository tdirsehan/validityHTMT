# This file is a generated template; edits are preserved by jmvtools::prepare().

#' Discriminant Validity (HTMT)
#'
#' Computes the Heterotrait-Monotrait ratio of correlations (HTMT).
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
            names <- c(
                self$options$n1, self$options$n2, self$options$n3, self$options$n4,
                self$options$n5, self$options$n6, self$options$n7, self$options$n8
            )

            keep <- vapply(sets, length, integer(1)) > 0
            sets <- sets[keep]
            names <- names[keep]

            names <- trimws(names)
            names[names == ""] <- paste0("Construct ", which(names == ""))

            list(sets = sets, names = make.unique(names))
        },

        .meanWithin = function(R, vars) {
            if (length(vars) < 2)
                return(NA_real_)
            block <- abs(R[vars, vars, drop = FALSE])
            mean(block[upper.tri(block)], na.rm = TRUE)
        },

        .htmt = function(R, a, b) {
            if (length(a) < 2 || length(b) < 2)
                return(NA_real_)

            cross <- abs(R[a, b, drop = FALSE])
            hetero <- mean(cross, na.rm = TRUE)
            monoA <- private$.meanWithin(R, a)
            monoB <- private$.meanWithin(R, b)

            denom <- sqrt(monoA * monoB)
            if (!is.finite(hetero) || !is.finite(denom) || denom <= 0)
                return(NA_real_)

            hetero / denom
        },

        .run = function() {
            self$results$references$setContent(
                paste0(
                    "<p>Henseler, J., Ringle, C. M., &amp; Sarstedt, M. (2015). ",
                    "A new criterion for assessing discriminant validity in variance-based structural equation modeling. ",
                    "<i>Journal of the Academy of Marketing Science</i>, <i>43</i>(1), 115&ndash;135.</p>"
                )
            )

            spec <- private$.collectConstructs()
            sets <- spec$sets
            constructNames <- spec$names

            self$results$instructions$setContent(
                paste0(
                    "<p>Select at least two constructs. Each construct should contain at least two indicators. ",
                    "HTMT is computed as the mean absolute heterotrait-heteromethod correlation divided by ",
                    "the geometric mean of the two mean absolute monotrait-heteromethod correlations.</p>"
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
            # Preserve the exact jamovi variable names (including @, spaces,
            # Turkish characters, etc.) while coercing columns to numeric.
            # Without check.names = FALSE, base R may silently sanitise names,
            # which makes R[a, b] fail with "subscript out of bounds" later.
            dat <- as.data.frame(
                lapply(dat, function(x) as.numeric(x)),
                check.names = FALSE
            )
            names(dat) <- allVars

            use <- if (identical(self$options$missing, "complete")) "complete.obs" else "pairwise.complete.obs"
            method <- if (identical(self$options$correlation, "spearman")) "spearman" else "pearson"

            R <- suppressWarnings(stats::cor(dat, use = use, method = method))

            if (any(!is.finite(R), na.rm = TRUE)) {
                self$results$notes$setContent(
                    "<p><b>Warning:</b> Some correlations could not be estimated. Check zero-variance indicators and missing data.</p>"
                )
            }

            k <- length(sets)
            M <- matrix(NA_real_, nrow = k, ncol = k, dimnames = list(constructNames, constructNames))
            diag(M) <- 1

            for (i in seq_len(k - 1)) {
                for (j in (i + 1):k) {
                    value <- private$.htmt(R, sets[[i]], sets[[j]])
                    M[i, j] <- value
                    M[j, i] <- value
                }
            }

            # Matrix table uses eight predeclared columns for compatibility
            # with older jamovi compilers (including jamovi 2.4.x).
            tab <- self$results$htmtMatrix
            # jamovi 2.4.x tables begin with zero rows. setRow() only
            # edits an existing row, so rows must be created with addRow().
            # Clear rows first because the same analysis object is re-used
            # when options change.
            tab$deleteRows()
            for (i in seq_len(k)) {
                vals <- list(construct = constructNames[i])
                for (j in seq_len(k))
                    vals[[paste0("c", j)]] <- M[i, j]
                tab$addRow(rowKey = paste0("construct_", i), values = vals)
            }

            cut <- if (identical(self$options$threshold, "strict85")) 0.85 else 0.90

            pairTab <- self$results$pairTable
            pairTab$deleteRows()
            rowNo <- 1
            for (i in seq_len(k - 1)) {
                for (j in (i + 1):k) {
                    h <- M[i, j]
                    assessment <- if (is.na(h)) {
                        "Not estimable"
                    } else if (h < cut) {
                        "Discriminant validity supported"
                    } else {
                        "Potential discriminant validity problem"
                    }

                    pairTab$addRow(rowKey = paste0("pair_", rowNo), values = list(
                        constructA = constructNames[i],
                        constructB = constructNames[j],
                        htmt = h,
                        threshold = cut,
                        assessment = assessment
                    ))
                    rowNo <- rowNo + 1
                }
            }

            methodLabel <- if (method == "pearson") "Pearson" else "Spearman"
            missingLabel <- if (use == "complete.obs") "complete cases" else "pairwise complete observations"
            self$results$notes$setContent(
                paste0(
                    "<p>Correlation: ", methodLabel,
                    "; missing data: ", missingLabel,
                    "; decision threshold: ", sprintf("%.2f", cut), ". ",
                    "Values below the selected threshold are conventionally interpreted as supporting discriminant validity. ",
                    "This threshold rule should be treated as a diagnostic rather than a mechanical proof.</p>"
                )
            )
        }
    )
)
