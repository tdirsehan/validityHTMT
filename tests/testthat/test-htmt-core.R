source(testthat::test_path("..", "..", "R", "htmt-core.R"))

testthat::test_that("HTMT+ reproduces the published Henseler et al. (2015) benchmark", {
    # Item correlation matrix from Henseler, Ringle, and Sarstedt (2015),
    # Table 5. All reported correlations are positive, so HTMT+ and the
    # original HTMT equation coincide for this published example.
    indicatorNames <- c(
        "acsi1", "acsi2", "acsi3",
        "cuex1", "cuex2", "cuex3",
        "perq1", "perq2", "perq3",
        "perv1", "perv2"
    )

    R <- matrix(
        c(
            1.000, 0.770, 0.701, 0.426, 0.423, 0.274, 0.797, 0.779, 0.512, 0.739, 0.684,
            0.770, 1.000, 0.665, 0.339, 0.345, 0.235, 0.705, 0.680, 0.460, 0.656, 0.615,
            0.701, 0.665, 1.000, 0.393, 0.385, 0.250, 0.651, 0.635, 0.410, 0.622, 0.579,
            0.426, 0.339, 0.393, 1.000, 0.574, 0.318, 0.517, 0.406, 0.249, 0.373, 0.326,
            0.423, 0.345, 0.385, 0.574, 1.000, 0.335, 0.472, 0.442, 0.277, 0.359, 0.310,
            0.274, 0.235, 0.250, 0.318, 0.335, 1.000, 0.295, 0.268, 0.362, 0.230, 0.200,
            0.797, 0.705, 0.651, 0.517, 0.472, 0.295, 1.000, 0.784, 0.503, 0.645, 0.556,
            0.779, 0.680, 0.635, 0.406, 0.442, 0.268, 0.784, 1.000, 0.533, 0.619, 0.543,
            0.512, 0.460, 0.410, 0.249, 0.277, 0.362, 0.503, 0.533, 1.000, 0.411, 0.354,
            0.739, 0.656, 0.622, 0.373, 0.359, 0.230, 0.645, 0.619, 0.411, 1.000, 0.774,
            0.684, 0.615, 0.579, 0.326, 0.310, 0.200, 0.556, 0.543, 0.354, 0.774, 1.000
        ),
        nrow = 11,
        byrow = TRUE,
        dimnames = list(indicatorNames, indicatorNames)
    )

    constructs <- list(
        ACSI = c("acsi1", "acsi2", "acsi3"),
        CUEX = c("cuex1", "cuex2", "cuex3"),
        PERQ = c("perq1", "perq2", "perq3"),
        PERV = c("perv1", "perv2")
    )

    H <- htmt_from_correlation(R, constructs)

    # Table 6 reports .63, .95, .87, .73, .53, and .76.
    testthat::expect_equal(H["ACSI", "CUEX"], 0.6321122622, tolerance = 1e-9)
    testthat::expect_equal(H["ACSI", "PERQ"], 0.9516421637, tolerance = 1e-9)
    testthat::expect_equal(H["ACSI", "PERV"], 0.8744716501, tolerance = 1e-9)
    testthat::expect_equal(H["CUEX", "PERQ"], 0.7334197129, tolerance = 1e-9)
    testthat::expect_equal(H["CUEX", "PERV"], 0.5326063042, tolerance = 1e-9)
    testthat::expect_equal(H["PERQ", "PERV"], 0.7607990244, tolerance = 1e-9)

    testthat::expect_equal(
        round(
            c(
                H["ACSI", "CUEX"],
                H["ACSI", "PERQ"],
                H["ACSI", "PERV"],
                H["CUEX", "PERQ"],
                H["CUEX", "PERV"],
                H["PERQ", "PERV"]
            ),
            2
        ),
        c(0.63, 0.95, 0.87, 0.73, 0.53, 0.76)
    )
})

example_constructs <- list(
    C1 = c("C1_1", "C1_2", "C1_3", "C1_4"),
    C2 = c("C2_1", "C2_2", "C2_3", "C2_4"),
    C3 = c("C3_1", "C3_2", "C3_3", "C3_4")
)

testthat::test_that("HTMT+ reproduces the fixed Pearson benchmark", {
    d <- utils::read.csv(
        testthat::test_path("..", "..", "examples", "htmt_example.csv"),
        check.names = FALSE
    )

    H <- htmt_matrix(
        d,
        example_constructs,
        method = "pearson"
    )

    expected <- matrix(
        c(
            1.000000000000000, 0.204267526162471, 0.236232267231236,
            0.204267526162471, 1.000000000000000, 0.267147172726584,
            0.236232267231236, 0.267147172726584, 1.000000000000000
        ),
        nrow = 3,
        byrow = TRUE,
        dimnames = list(
            c("C1", "C2", "C3"),
            c("C1", "C2", "C3")
        )
    )

    testthat::expect_equal(H, expected, tolerance = 1e-12)
})

testthat::test_that("HTMT+ reproduces the fixed Spearman benchmark", {
    d <- utils::read.csv(
        testthat::test_path("..", "..", "examples", "htmt_example.csv"),
        check.names = FALSE
    )

    H <- htmt_matrix(
        d,
        example_constructs,
        method = "spearman"
    )

    expected <- matrix(
        c(
            1.000000000000000, 0.147178929330293, 0.222930886242476,
            0.147178929330293, 1.000000000000000, 0.268662751866541,
            0.222930886242476, 0.268662751866541, 1.000000000000000
        ),
        nrow = 3,
        byrow = TRUE,
        dimnames = list(
            c("C1", "C2", "C3"),
            c("C1", "C2", "C3")
        )
    )

    testthat::expect_equal(H, expected, tolerance = 1e-12)
})

testthat::test_that("HTMT+ is invariant to indicator sign reversal", {
    d <- data.frame(
        x1 = c(1, 2, 4, 5, 7, 9, 10, 12),
        x2 = c(2, 1, 5, 4, 8, 7, 11, 10),
        x3 = c(1, 3, 3, 6, 6, 8, 9, 11),
        y1 = c(9, 7, 8, 5, 6, 3, 4, 2),
        y2 = c(8, 9, 6, 7, 4, 5, 2, 3),
        y3 = c(10, 8, 9, 6, 7, 4, 5, 1)
    )

    constructs <- list(
        A = c("x1", "x2", "x3"),
        B = c("y1", "y2", "y3")
    )

    H1 <- htmt_matrix(d, constructs)

    d$x2 <- -d$x2
    H2 <- htmt_matrix(d, constructs)

    testthat::expect_equal(H1, H2, tolerance = 1e-12)
})

testthat::test_that("complete-case HTMT+ fails informatively when too few complete rows remain", {
    d <- data.frame(
        x1 = c(1, NA, 3, NA),
        x2 = c(NA, 2, 3, NA),
        y1 = c(1, 2, NA, 4),
        y2 = c(NA, 2, 3, 4)
    )

    constructs <- list(
        A = c("x1", "x2"),
        B = c("y1", "y2")
    )

    testthat::expect_error(
        htmt_matrix(
            d,
            constructs,
            use = "complete.obs"
        ),
        "At least two complete observations"
    )
})

testthat::test_that("zero-variance indicators return a non-estimable pair rather than Inf", {
    d <- data.frame(
        x1 = 1:8,
        x2 = c(1, 2, 4, 3, 6, 5, 8, 7),
        y1 = 8:1,
        y2 = rep(1, 8)
    )

    H <- htmt_matrix(
        d,
        list(
            A = c("x1", "x2"),
            B = c("y1", "y2")
        )
    )

    testthat::expect_true(is.na(H["A", "B"]))
})

testthat::test_that("non-syntactic indicator names are preserved", {
    d <- data.frame(
        "@x 1" = 1:8,
        "x-2" = c(1, 2, 4, 3, 6, 5, 8, 7),
        "Türkçe y1" = 8:1,
        "y 2" = c(8, 7, 5, 6, 3, 4, 1, 2),
        check.names = FALSE
    )

    H <- htmt_matrix(
        d,
        list(
            A = c("@x 1", "x-2"),
            B = c("Türkçe y1", "y 2")
        )
    )

    testthat::expect_true(is.finite(H["A", "B"]))
})

testthat::test_that("invalid construct specifications fail clearly", {
    d <- data.frame(
        x1 = 1:6,
        x2 = 2:7,
        y1 = 6:1,
        y2 = 7:2
    )

    testthat::expect_error(
        htmt_matrix(
            d,
            list(
                A = c("x1", "x2"),
                B = c("x2", "y2")
            )
        ),
        "must not be repeated"
    )

    testthat::expect_error(
        htmt_matrix(
            d,
            list(
                A = c("x1"),
                B = c("y1", "y2")
            )
        ),
        "at least two indicators"
    )

    testthat::expect_error(
        htmt_matrix(
            d,
            list(
                A = c("x1", "x2"),
                B = c("missing", "y2")
            )
        ),
        "Unknown indicator"
    )
})
