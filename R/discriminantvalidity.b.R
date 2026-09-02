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
            raw <- self$options$constructs

            if (is.null(raw))
                raw <- list()

            sets <- lapply(raw, function(x) {
                if (is.null(x) || length(x) == 0)
                    return(character(0))

                # v0.2.0 stores each dynamic construct as a Group with
                # `vars` and a UI-only `reset` Action. Keep compatibility
                # with early beta/saved analyses that stored a character
                # vector directly.
                if (is.list(x) && !is.null(x$vars))
                    x <- x$vars

                if (is.null(x) || length(x) == 0)
                    return(character(0))

                if (is.character(x))
                    return(unname(x))

                unname(as.character(unlist(x, use.names = FALSE)))
            })

            keep <- vapply(sets, length, integer(1)) > 0
            sets <- sets[keep]
            constructNames <- paste0("Construct ", seq_along(sets))

            list(sets = sets, names = constructNames)
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

        .matrixHtml = function(M, constructNames) {
            fmt <- function(x) {
                if (is.na(x) || !is.finite(x))
                    return("&ndash;")
                sprintf("%.3f", x)
            }

            header <- paste0(
                "<tr><th style='text-align:left;padding:4px 8px;'>Construct</th>",
                paste0(
                    "<th style='text-align:right;padding:4px 8px;'>",
                    constructNames,
                    "</th>",
                    collapse = ""
                ),
                "</tr>"
            )

            rows <- vapply(seq_along(constructNames), function(i) {
                cells <- paste0(
                    "<td style='text-align:right;padding:4px 8px;'>",
                    vapply(seq_along(constructNames), function(j) fmt(M[i, j]), character(1)),
                    "</td>",
                    collapse = ""
                )
                paste0(
                    "<tr><th style='text-align:left;padding:4px 8px;'>",
                    constructNames[i],
                    "</th>",
                    cells,
                    "</tr>"
                )
            }, character(1))

            paste0(
                "<div style='overflow-x:auto;'>",
                "<table style='border-collapse:collapse;min-width:520px;'>",
                "<thead>", header, "</thead><tbody>",
                paste0(rows, collapse = ""),
                "</tbody></table></div>"
            )
        },

        .run = function() {
            self$results$references$setContent(
                paste0(
                    "<p>Henseler, J., Ringle, C. M., &amp; Sarstedt, M. (2015). ",
                    "A new criterion for assessing discriminant validity in variance-based structural equation modeling. ",
                    "<i>Journal of the Academy of Marketing Science</i>, <i>43</i>(1), 115&ndash;135.</p>"
                )
            )

            self$results$instructions$setContent(
                paste0(
                    "<p>Add constructs with the <b>+ Construct</b> button and drag indicators into each construct. ",
                    "At least two non-empty constructs are required and each construct should contain at least two indicators. ",
                    "HTMT is computed as the mean absolute heterotrait-heteromethod correlation divided by ",
                    "the geometric mean of the two mean absolute monotrait-heteromethod correlations.</p>"
                )
            )

            spec <- private$.collectConstructs()
            sets <- spec$sets
            constructNames <- spec$names

            pairTab <- self$results$pairTable
            pairTab$deleteRows()

            if (length(sets) < 2) {
                self$results$htmtMatrix$setContent(
                    "<p>Add at least two constructs and assign indicators to them.</p>"
                )
                return()
            }

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
            dat <- as.data.frame(lapply(dat, function(x) as.numeric(x)))

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

            self$results$htmtMatrix$setContent(
                private$.matrixHtml(M, constructNames)
            )

            cut <- if (identical(self$options$threshold, "strict85")) 0.85 else 0.90

            self$results$pairFootnote$setContent(
                paste0(
                    "<p><i>Note.</i> HTMT decision threshold = ",
                    sprintf("%.2f", cut),
                    ". Values below the selected threshold are conventionally interpreted as supporting discriminant validity. ",
                    "The threshold should be treated as a diagnostic rather than a mechanical proof.</p>"
                )
            )

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
                        assessment = assessment
                    ))
                    rowNo <- rowNo + 1
                }
            }

            methodLabel <- if (method == "pearson") "Pearson" else "Spearman"
            missingLabel <- if (use == "complete.obs") "complete cases" else "pairwise complete observations"
            self$results$notes$setContent(
                paste0(
                    "<p>Constructs analysed: ", k,
                    ". Correlation: ", methodLabel,
                    "; missing data: ", missingLabel, ".</p>"
                )
            )
        }
    )
)
