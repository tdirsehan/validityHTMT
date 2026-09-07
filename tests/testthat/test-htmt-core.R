source(file.path("R", "htmt-core.R"))

example_constructs <- list(
    C1 = c("C1_1", "C1_2", "C1_3", "C1_4"),
    C2 = c("C2_1", "C2_2", "C2_3", "C2_4"),
    C3 = c("C3_1", "C3_2", "C3_3", "C3_4")
)

testthat::test_that("HTMT+ reproduces the fixed Pearson benchmark", {
    d <- utils::read.csv(
        file.path("examples", "htmt_example.csv"),
        check.names = FALSE
    )

    H <- htmt_matrix(
        d,
        example_constructs,
        method = "pearson"
    )

    expected <- matrix(
        c(
            1.00000000, 0.30525247, 0.20524750,
            0.30525247, 1.00000000, 0.29918240,
            0.20524750, 0.29918240, 1.00000000
        ),
        nrow = 3,
        byrow = TRUE,
        dimnames = list(
            c("C1", "C2", "C3"),
            c("C1", "C2", "C3")
        )
    )

    testthat::expect_equal(H, expected, tolerance = 1e-7)
})

testthat::test_that("HTMT+ reproduces the fixed Spearman benchmark", {
    d <- utils::read.csv(
        file.path("examples", "htmt_example.csv"),
        check.names = FALSE
    )

    H <- htmt_matrix(
        d,
        example_constructs,
        method = "spearman"
    )

    expected <- matrix(
        c(
            1.00000000, 0.28122732, 0.21208079,
            0.28122732, 1.00000000, 0.29532938,
            0.21208079, 0.29532938, 1.00000000
        ),
        nrow = 3,
        byrow = TRUE,
        dimnames = list(
            c("C1", "C2", "C3"),
            c("C1", "C2", "C3")
        )
    )

    testthat::expect_equal(H, expected, tolerance = 1e-7)
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
