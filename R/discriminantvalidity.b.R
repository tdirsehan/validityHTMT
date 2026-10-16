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
            input <- self$options$constructs
            if (is.null(input))
                input <- list()
            sets <- lapply(input, function(x) x$vars)
            keep <- vapply(sets, function(x) length(x) > 0, logical(1))
            slotNumbers <- which(keep)
            sets <- sets[keep]
            labels <- vapply(input[keep], function(x) {
                if (is.null(x$label) || length(x$label) == 0 || is.na(x$label[1]))
                    return("")
                trimws(as.character(x$label[1]))
            }, character(1))
            blank <- !nzchar(labels)
            labels[blank] <- paste0("Construct ", slotNumbers[blank])
            list(sets = sets, names = labels)
        },

        .init = function() {
            spec <- private$.collectConstructs()
            k <- length(spec$sets)
            help <- self$results$instructions
            help$setVisible(k < 2)
            if (k < 2) {
                help$setContent(paste0(
                    "<p>Select at least two reflective constructs and at least ",
                    "two indicators per construct. Use Add New Construct to ",
                    "include more constructs.</p>"
                ))
            }

            tab <- self$results$htmtMatrix
            for (j in seq_len(k))
                tab$addColumn(
                    name = paste0("c", j),
                    title = spec$names[j],
                    type = "number",
                    format = "zto"
                )
            for (i in seq_len(k))
                tab$addRow(
                    rowKey = i,
                    values = list(construct = spec$names[i])
                )

            if (k >= 2) {
                pairs <- self$results$pairTable
                rowNo <- 1L
                for (i in seq_len(k - 1L)) {
                    for (j in seq.int(i + 1L, k)) {
                        pairs$addRow(
                            rowKey = rowNo,
                            values = list(
                                constructA = spec$names[i],
                                constructB = spec$names[j]
                            )
                        )
                        rowNo <- rowNo + 1L
                    }
                }
            }
        },

        .run = function() {
            spec <- private$.collectConstructs()
            sets <- spec$sets
            constructNames <- spec$names
            k <- length(sets)
            if (k < 2)
                return()

            if (anyDuplicated(constructNames))
                jmvcore::reject("Construct names must be unique. Rename duplicate constructs.")

            if (any(vapply(sets, length, integer(1)) < 2))
                jmvcore::reject("Each selected construct must contain at least two indicators.")

            allVars <- unlist(sets, use.names = FALSE)
            duplicatedVars <- unique(allVars[duplicated(allVars)])
            if (length(duplicatedVars) > 0)
                jmvcore::reject(paste0(
                    "An indicator can belong to only one construct. Duplicated indicator(s): ",
                    paste(duplicatedVars, collapse = ", ")
                ))

            dat <- self$data[, allVars, drop = FALSE]
            dat <- as.data.frame(lapply(dat, jmvcore::toNumeric), check.names = FALSE)
            names(dat) <- allVars
            if (nrow(dat) < 2)
                jmvcore::reject("At least two observations are required.")

            use <- if (identical(self$options$missing, "complete"))
                "complete.obs" else "pairwise.complete.obs"
            method <- if (identical(self$options$correlation, "spearman"))
                "spearman" else "pearson"

            if (identical(use, "complete.obs") &&
                sum(stats::complete.cases(dat)) < 2)
                jmvcore::reject(paste0(
                    "HTMT+ could not be estimated because fewer than two ",
                    "complete observations remain."
                ))

            R <- tryCatch(
                suppressWarnings(stats::cor(dat, use = use, method = method)),
                error = function(e) e
            )
            if (inherits(R, "error"))
                jmvcore::reject(paste0(
                    "HTMT+ correlations could not be estimated: ",
                    conditionMessage(R)
                ))

            if (!any(is.finite(R[upper.tri(R)])))
                jmvcore::reject("No estimable indicator correlations remain. Check variability and missing values.")

            namedSets <- sets
            names(namedSets) <- constructNames
            M <- htmt_from_correlation(R, namedSets)
            if (all(!is.finite(M[upper.tri(M)])))
                jmvcore::reject("No HTMT+ construct pairs could be estimated. Check within-construct correlations.")
            tab <- self$results$htmtMatrix
            for (i in seq_len(k)) {
                values <- list()
                for (j in seq_len(k))
                    values[[paste0("c", j)]] <- if (i == j) NA_real_ else M[i, j]
                tab$setRow(rowKey = i, values = values)
            }

            cut <- if (identical(self$options$threshold, "strict85"))
                0.85 else 0.90
            pairTab <- self$results$pairTable
            rowNo <- 1L
            for (i in seq_len(k - 1L)) {
                for (j in seq.int(i + 1L, k)) {
                    h <- M[i, j]
                    assessment <- if (!is.finite(h)) {
                        "Not estimable"
                    } else if (h < cut) {
                        "Discriminant validity supported"
                    } else {
                        "Potential discriminant validity problem"
                    }
                    pairTab$setRow(
                        rowKey = rowNo,
                        values = list(
                            htmt = h,
                            threshold = cut,
                            assessment = assessment
                        )
                    )
                    rowNo <- rowNo + 1L
                }
            }

            methodLabel <- if (method == "pearson") "Pearson" else "Spearman"
            missingLabel <- if (use == "complete.obs")
                "complete cases" else "pairwise complete observations"
            tab$setNote("method", paste0(
                "HTMT+ using absolute indicator correlations; correlation: ",
                methodLabel, "; missing data: ", missingLabel,
                "; decision threshold: ", sprintf("%.2f", cut),
                ". The threshold is a diagnostic, not a mechanical proof."
            ))

            if (any(!is.finite(R))) {
                notice <- jmvcore::Notice$new(
                    self$options,
                    name = ".nonFinite",
                    type = jmvcore::NoticeType$WARNING,
                    content = paste0(
                        "Some correlations could not be estimated. ",
                        "Check zero-variance indicators, sparse pairwise ",
                        "overlap, and missing data."
                    )
                )
                self$results$insert(1, notice)
            }
        }
    )
)
