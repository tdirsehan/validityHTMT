# Standalone HTMT+ helpers used by the jamovi backend, automated tests,
# and methodological transparency.
#
# HTMT+ is the absolute-correlation variant of the heterotrait-monotrait ratio.

htmt_from_correlation <- function(R, constructs) {

    if (!is.matrix(R) && !is.data.frame(R))
        stop("R must be a correlation matrix.")

    R <- as.matrix(R)

    if (nrow(R) != ncol(R))
        stop("R must be a square correlation matrix.")

    if (is.null(rownames(R)) || is.null(colnames(R)))
        stop("R must have row and column names.")

    if (!identical(rownames(R), colnames(R)))
        stop("R row and column names must match and be in the same order.")

    if (!is.list(constructs) || length(constructs) < 2)
        stop("At least two constructs are required.")

    vars <- unlist(constructs, use.names = FALSE)

    if (anyDuplicated(vars))
        stop("Indicators must not be repeated across constructs.")

    if (any(lengths(constructs) < 2))
        stop("Each construct requires at least two indicators.")

    missingVars <- setdiff(vars, colnames(R))
    if (length(missingVars) > 0)
        stop(
            paste0(
                "Unknown indicator(s): ",
                paste(missingVars, collapse = ", ")
            )
        )

    constructNames <- names(constructs)
    if (is.null(constructNames))
        constructNames <- rep("", length(constructs))

    emptyNames <- is.na(constructNames) | trimws(constructNames) == ""
    constructNames[emptyNames] <- paste0("Construct ", which(emptyNames))
    constructNames <- make.unique(constructNames)

    k <- length(constructs)
    out <- matrix(
        NA_real_,
        k,
        k,
        dimnames = list(constructNames, constructNames)
    )
    diag(out) <- 1

    within_mean <- function(v) {
        z <- abs(R[v, v, drop = FALSE])
        values <- z[upper.tri(z)]
        values <- values[is.finite(values)]

        if (length(values) == 0)
            return(NA_real_)

        mean(values)
    }

    for (i in seq_len(k - 1)) {
        for (j in (i + 1):k) {
            a <- constructs[[i]]
            b <- constructs[[j]]

            cross <- abs(R[a, b, drop = FALSE])
            crossValues <- as.numeric(cross)
            crossValues <- crossValues[is.finite(crossValues)]

            hetero <- if (length(crossValues) == 0)
                NA_real_
            else
                mean(crossValues)

            denom <- sqrt(within_mean(a) * within_mean(b))

            value <- if (
                !is.finite(hetero) ||
                !is.finite(denom) ||
                denom <= 0
            ) {
                NA_real_
            } else {
                hetero / denom
            }

            out[i, j] <- out[j, i] <- value
        }
    }

    out
}


htmt_matrix <- function(data,
                        constructs,
                        method = c("pearson", "spearman"),
                        use = c("pairwise.complete.obs", "complete.obs")) {

    method <- match.arg(method)
    use <- match.arg(use)

    if (!is.list(constructs) || length(constructs) < 2)
        stop("At least two constructs are required.")

    vars <- unlist(constructs, use.names = FALSE)

    if (anyDuplicated(vars))
        stop("Indicators must not be repeated across constructs.")

    if (any(lengths(constructs) < 2))
        stop("Each construct requires at least two indicators.")

    missingVars <- setdiff(vars, names(data))
    if (length(missingVars) > 0)
        stop(
            paste0(
                "Unknown indicator(s): ",
                paste(missingVars, collapse = ", ")
            )
        )

    # jamovi may expose ordinal/integer variables as factors with underlying
    # numeric values. toNumeric() is the recommended conversion.
    x <- as.data.frame(
        lapply(data[, vars, drop = FALSE], jmvcore::toNumeric),
        check.names = FALSE
    )
    names(x) <- vars

    if (nrow(x) < 2)
        stop("At least two observations are required.")

    if (identical(use, "complete.obs") && sum(stats::complete.cases(x)) < 2)
        stop("At least two complete observations are required for complete-case HTMT+.")

    R <- tryCatch(
        suppressWarnings(stats::cor(x, use = use, method = method)),
        error = function(e) e
    )

    if (inherits(R, "error"))
        stop(
            paste0(
                "HTMT+ correlations could not be estimated: ",
                conditionMessage(R)
            )
        )

    htmt_from_correlation(R, constructs)
}
