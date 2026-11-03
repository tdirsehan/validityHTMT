# Exercise the actual R analysis and rendered table cells after jmvtools::prepare().
# Numeric benchmarks must stay unchanged when presentation changes.
stopifnot(requireNamespace("validityHTMT", quietly = TRUE))
source("R/htmt-core.R")

d <- utils::read.csv("examples/htmt_example.csv", check.names = FALSE)
groups <- list(
    list(label = "C1", vars = paste0("C1_", 1:4)),
    list(label = "C2", vars = paste0("C2_", 1:4)),
    list(label = "C3", vars = paste0("C3_", 1:4))
)
namedGroups <- lapply(groups, function(x) x$vars)
names(namedGroups) <- vapply(groups, function(x) x$label, "")

execute <- function(method = "pearson", missing = "pairwise",
                    threshold = "liberal90", showPairs = TRUE,
                    data = d, constructs = groups) {
    validityHTMT::discriminantValidity(
        data = data, constructs = constructs, correlation = method,
        missing = missing, threshold = threshold, showPairs = showPairs
    )
}

check_layout <- function(result, expected, expectedNames = rownames(expected)) {
    actual <- result$htmtMatrix$asDF
    k <- nrow(expected)
    stopifnot(is.data.frame(actual), nrow(actual) == k,
              ncol(actual) == k + 1L)
    stopifnot(identical(as.character(actual[[1]]), expectedNames))
    lowerCount <- 0L
    for (j in seq_len(k)) {
        column <- as.character(actual[[j + 1L]])
        for (i in seq_len(k)) {
            if (i == j) {
                stopifnot(identical(column[[i]], "\u2014"))
            } else if (i < j) {
                stopifnot(is.na(column[[i]]) || identical(column[[i]], ""))
            } else {
                observed <- suppressWarnings(as.numeric(column[[i]]))
                target <- expected[i, j]
                if (is.finite(target)) {
                    stopifnot(is.finite(observed),
                              abs(observed - target) < 1e-10)
                    lowerCount <- lowerCount + 1L
                } else {
                    stopifnot(!is.finite(observed))
                }
            }
        }
    }
    stopifnot(lowerCount == sum(is.finite(expected[lower.tri(expected)])))
    cat("Verified lower triangle for ", k, " constructs (",
        lowerCount, " finite values).\n", sep = "")
    invisible(actual)
}

for (method in c("pearson", "spearman")) {
    result <- execute(method = method)
    expected <- htmt_matrix(d, namedGroups, method = method)
    print(result$htmtMatrix$asDF)
    print(result$pairTable$asDF)
    check_layout(result, expected)
    stopifnot(nrow(result$pairTable$asDF) == 3L,
              ncol(result$pairTable$asDF) == 4L)
}

# Exactly one HTMT+ value must appear in the two-construct table.
twoGroups <- groups[1:2]
twoExpected <- htmt_matrix(d, namedGroups[1:2])
twoResult <- execute(constructs = twoGroups)
check_layout(twoResult, twoExpected)
stopifnot(nrow(twoResult$pairTable$asDF) == 1L)

# Five constructs must produce 10 distinct results, not 20 duplicated cells.
set.seed(2217)
largerData <- d
for (cname in c("C4", "C5")) {
    base <- stats::rnorm(nrow(largerData))
    for (j in 1:3)
        largerData[[paste0(cname, "_", j)]] <- base + stats::rnorm(nrow(largerData))
}
fiveGroups <- c(groups, list(
    list(label = "C4", vars = paste0("C4_", 1:3)),
    list(label = "C5", vars = paste0("C5_", 1:3))
))
fiveNamed <- lapply(fiveGroups, function(x) x$vars)
names(fiveNamed) <- vapply(fiveGroups, function(x) x$label, "")
fiveExpected <- htmt_matrix(largerData, fiveNamed)
fiveResult <- execute(data = largerData, constructs = fiveGroups)
check_layout(fiveResult, fiveExpected)
stopifnot(nrow(fiveResult$pairTable$asDF) == 10L)

# Threshold changes should change interpretation, not numerical HTMT+.
set.seed(843)
n <- 6000
f1 <- stats::rnorm(n)
f2 <- 0.875 * f1 + sqrt(1 - 0.875^2) * stats::rnorm(n)
thresholdData <- data.frame(
    A1 = f1 + stats::rnorm(n, sd = 0.2),
    A2 = f1 + stats::rnorm(n, sd = 0.2),
    B1 = f2 + stats::rnorm(n, sd = 0.2),
    B2 = f2 + stats::rnorm(n, sd = 0.2)
)
thresholdGroups <- list(
    list(label = "A", vars = c("A1", "A2")),
    list(label = "B", vars = c("B1", "B2"))
)
thresholdNamed <- list(A = c("A1", "A2"), B = c("B1", "B2"))
h <- htmt_matrix(thresholdData, thresholdNamed)["A", "B"]
stopifnot(h > .85, h < .90)
strict <- execute(data = thresholdData, constructs = thresholdGroups,
                  threshold = "strict85")
liberal <- execute(data = thresholdData, constructs = thresholdGroups,
                   threshold = "liberal90")
check_layout(strict, htmt_matrix(thresholdData, thresholdNamed))
check_layout(liberal, htmt_matrix(thresholdData, thresholdNamed))
stopifnot(any(grepl("Potential", unlist(strict$pairTable$asDF),
                   fixed = TRUE)),
          any(grepl("supported", unlist(liberal$pairTable$asDF),
                    fixed = TRUE)))

# Visibility toggling must not alter the numerical matrix.
noPairs <- execute(showPairs = FALSE)
check_layout(noPairs, htmt_matrix(d, namedGroups))

# Complete-case handling must agree with the standalone core.
incomplete <- d
incomplete$C1_1[1:5] <- NA_real_
incomplete$C2_2[6:10] <- NA_real_
completeResult <- execute(data = incomplete, method = "spearman",
                          missing = "complete")
completeExpected <- htmt_matrix(incomplete, namedGroups,
    method = "spearman", use = "complete.obs")
check_layout(completeResult, completeExpected)

# Blank construct names must match the UI's Construct N convention.
blank <- groups
blank[[3]]$label <- ""
blankResult <- execute(constructs = blank)
blankNamed <- namedGroups
names(blankNamed)[3] <- "Construct 3"
check_layout(blankResult, htmt_matrix(d, blankNamed),
             c("C1", "C2", "Construct 3"))

# A constant indicator must not fatally break otherwise estimable pairs.
set.seed(109)
warningData <- data.frame(
    A1 = stats::rnorm(60), A2 = stats::rnorm(60),
    B1 = stats::rnorm(60), B2 = stats::rnorm(60),
    C1 = rep(1, 60), C2 = stats::rnorm(60)
)
warningGroups <- list(
    list(label = "A", vars = c("A1", "A2")),
    list(label = "B", vars = c("B1", "B2")),
    list(label = "C", vars = c("C1", "C2"))
)
warningNamed <- list(A = c("A1", "A2"), B = c("B1", "B2"),
                     C = c("C1", "C2"))
warnResult <- execute(data = warningData, constructs = warningGroups)
check_layout(warnResult, htmt_matrix(warningData, warningNamed))
stopifnot(nrow(warnResult$pairTable$asDF) == 3L,
          any(grepl("Not estimable", unlist(warnResult$pairTable$asDF),
                    fixed = TRUE)))
cat("Actual jamovi analysis: all v1.0.3 display tests passed.\n")
