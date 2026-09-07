source(file.path("R", "htmt-core.R"))

assert_close <- function(actual, expected, tol = 1e-7, label = "value") {
    if (length(actual) != length(expected) || any(!is.finite(actual)) ||
        max(abs(actual - expected)) > tol) {
        stop(sprintf("%s regression: expected %s; got %s",
            label,
            paste(expected, collapse = ", "),
            paste(actual, collapse = ", ")))
    }
}

# Published Henseler, Ringle & Sarstedt (2015), Table 5 -> Table 6 benchmark.
indicator_names <- c(
    "acsi1", "acsi2", "acsi3", "cuex1", "cuex2", "cuex3",
    "perq1", "perq2", "perq3", "perv1", "perv2"
)

R <- matrix(c(
    1.000,0.770,0.701,0.426,0.423,0.274,0.797,0.779,0.512,0.739,0.684,
    0.770,1.000,0.665,0.339,0.345,0.235,0.705,0.680,0.460,0.656,0.615,
    0.701,0.665,1.000,0.393,0.385,0.250,0.651,0.635,0.410,0.622,0.579,
    0.426,0.339,0.393,1.000,0.574,0.318,0.517,0.406,0.249,0.373,0.326,
    0.423,0.345,0.385,0.574,1.000,0.335,0.472,0.442,0.277,0.359,0.310,
    0.274,0.235,0.250,0.318,0.335,1.000,0.295,0.268,0.362,0.230,0.200,
    0.797,0.705,0.651,0.517,0.472,0.295,1.000,0.784,0.503,0.645,0.556,
    0.779,0.680,0.635,0.406,0.442,0.268,0.784,1.000,0.533,0.619,0.543,
    0.512,0.460,0.410,0.249,0.277,0.362,0.503,0.533,1.000,0.411,0.354,
    0.739,0.656,0.622,0.373,0.359,0.230,0.645,0.619,0.411,1.000,0.774,
    0.684,0.615,0.579,0.326,0.310,0.200,0.556,0.543,0.354,0.774,1.000
), nrow = 11, byrow = TRUE, dimnames = list(indicator_names, indicator_names))

published_constructs <- list(
    ACSI = c("acsi1", "acsi2", "acsi3"),
    CUEX = c("cuex1", "cuex2", "cuex3"),
    PERQ = c("perq1", "perq2", "perq3"),
    PERV = c("perv1", "perv2")
)

H <- htmt_from_correlation(R, published_constructs)
published_actual <- c(
    H["ACSI", "CUEX"], H["ACSI", "PERQ"], H["ACSI", "PERV"],
    H["CUEX", "PERQ"], H["CUEX", "PERV"], H["PERQ", "PERV"]
)
published_expected <- c(
    0.6321122622, 0.9516421637, 0.8744716501,
    0.7334197129, 0.5326063042, 0.7607990244
)
assert_close(published_actual, published_expected, 1e-9, "published HTMT+")
stopifnot(identical(round(published_actual, 2), c(0.63, 0.95, 0.87, 0.73, 0.53, 0.76)))

# Bundled synthetic dataset, Pearson and Spearman exact regression values.
d <- utils::read.csv(file.path("examples", "htmt_example.csv"), check.names = FALSE)
constructs <- list(
    C1 = c("C1_1", "C1_2", "C1_3", "C1_4"),
    C2 = c("C2_1", "C2_2", "C2_3", "C2_4"),
    C3 = c("C3_1", "C3_2", "C3_3", "C3_4")
)

Hp <- htmt_matrix(d, constructs, method = "pearson")
assert_close(
    c(Hp["C1", "C2"], Hp["C1", "C3"], Hp["C2", "C3"]),
    c(0.30525247, 0.20524750, 0.29918240),
    1e-7,
    "Pearson HTMT+"
)

Hs <- htmt_matrix(d, constructs, method = "spearman")
assert_close(
    c(Hs["C1", "C2"], Hs["C1", "C3"], Hs["C2", "C3"]),
    c(0.28122732, 0.21208079, 0.29532938),
    1e-7,
    "Spearman HTMT+"
)

# HTMT+ must be invariant to indicator sign reversal.
sign_data <- data.frame(
    x1 = c(1,2,4,5,7,9,10,12),
    x2 = c(2,1,5,4,8,7,11,10),
    x3 = c(1,3,3,6,6,8,9,11),
    y1 = c(9,7,8,5,6,3,4,2),
    y2 = c(8,9,6,7,4,5,2,3),
    y3 = c(10,8,9,6,7,4,5,1)
)
sign_constructs <- list(A = c("x1","x2","x3"), B = c("y1","y2","y3"))
H1 <- htmt_matrix(sign_data, sign_constructs)
sign_data$x2 <- -sign_data$x2
H2 <- htmt_matrix(sign_data, sign_constructs)
assert_close(H1["A","B"], H2["A","B"], 1e-12, "sign invariance")

# Insufficient complete cases must fail informatively.
missing_data <- data.frame(
    x1 = c(1, NA, 3, NA), x2 = c(NA, 2, 3, NA),
    y1 = c(1, 2, NA, 4), y2 = c(NA, 2, 3, 4)
)
err <- tryCatch({
    htmt_matrix(missing_data, list(A=c("x1","x2"), B=c("y1","y2")), use="complete.obs")
    NULL
}, error = identity)
stopifnot(inherits(err, "error"), grepl("At least two complete observations", conditionMessage(err)))

# Zero variance should produce a non-estimable pair, not Inf.
zero_data <- data.frame(
    x1 = 1:8, x2 = c(1,2,4,3,6,5,8,7), y1 = 8:1, y2 = rep(1,8)
)
Hz <- htmt_matrix(zero_data, list(A=c("x1","x2"), B=c("y1","y2")))
stopifnot(is.na(Hz["A","B"]))

cat("All validityHTMT HTMT+ CI checks passed.\n")
