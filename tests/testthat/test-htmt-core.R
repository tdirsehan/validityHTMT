source(file.path("R", "htmt-core.R"))

testthat::test_that("HTMT matrix is symmetric with unit diagonal", {
    set.seed(123)
    f1 <- rnorm(300)
    f2 <- rnorm(300)
    d <- data.frame(
        x1 = .8*f1 + rnorm(300, sd=.5),
        x2 = .8*f1 + rnorm(300, sd=.5),
        x3 = .8*f1 + rnorm(300, sd=.5),
        y1 = .8*f2 + rnorm(300, sd=.5),
        y2 = .8*f2 + rnorm(300, sd=.5),
        y3 = .8*f2 + rnorm(300, sd=.5)
    )
    H <- htmt_matrix(d, list(A=c("x1","x2","x3"), B=c("y1","y2","y3")))
    testthat::expect_equal(H, t(H))
    testthat::expect_equal(diag(H), c(1,1))
    testthat::expect_true(H[1,2] < .30)
})

testthat::test_that("HTMT rises when constructs are strongly overlapping", {
    set.seed(456)
    f <- rnorm(400)
    d <- data.frame(
        x1 = .9*f + rnorm(400, sd=.25), x2 = .9*f + rnorm(400, sd=.25),
        x3 = .9*f + rnorm(400, sd=.25), y1 = .9*f + rnorm(400, sd=.25),
        y2 = .9*f + rnorm(400, sd=.25), y3 = .9*f + rnorm(400, sd=.25)
    )
    H <- htmt_matrix(d, list(A=c("x1","x2","x3"), B=c("y1","y2","y3")))
    testthat::expect_true(H[1,2] > .90)
})
