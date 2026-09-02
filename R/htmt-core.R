# Standalone helper used for testing and methodological transparency.
htmt_matrix <- function(data, constructs, method = c("pearson", "spearman"), use = "pairwise.complete.obs") {
    method <- match.arg(method)
    stopifnot(is.list(constructs), length(constructs) >= 2)
    vars <- unlist(constructs, use.names = FALSE)
    if (anyDuplicated(vars)) stop("Indicators must not be repeated across constructs.")
    if (any(lengths(constructs) < 2)) stop("Each construct requires at least two indicators.")

    x <- as.data.frame(lapply(data[, vars, drop = FALSE], as.numeric))
    R <- stats::cor(x, use = use, method = method)
    k <- length(constructs)
    out <- matrix(NA_real_, k, k, dimnames = list(names(constructs), names(constructs)))
    diag(out) <- 1

    within_mean <- function(v) {
        z <- abs(R[v, v, drop = FALSE])
        mean(z[upper.tri(z)], na.rm = TRUE)
    }

    for (i in seq_len(k - 1)) {
        for (j in (i + 1):k) {
            a <- constructs[[i]]
            b <- constructs[[j]]
            hetero <- mean(abs(R[a, b, drop = FALSE]), na.rm = TRUE)
            denom <- sqrt(within_mean(a) * within_mean(b))
            out[i, j] <- out[j, i] <- hetero / denom
        }
    }
    out
}
