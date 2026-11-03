# Static jamovi definition checks; this does not replace a running jamovi compiler.
library(yaml)
a <- yaml.load_file("jamovi/discriminantvalidity.a.yaml")
u <- yaml.load_file("jamovi/discriminantvalidity.u.yaml")
r <- yaml.load_file("jamovi/discriminantvalidity.r.yaml")
m <- yaml.load_file("jamovi/0000.yaml")
refs <- yaml.load_file("jamovi/00refs.yaml")
d <- read.dcf("DESCRIPTION")
stopifnot(
  identical(as.character(d[1, "Version"]), "1.0.3"),
  identical(as.character(a$version), "1.0.3"),
  identical(as.character(m$version), "1.0.3"),
  identical(a$options[[2]]$name, "constructs"),
  identical(a$options[[2]]$type, "Array"),
  identical(a$options[[2]]$template$type, "Group"),
  length(a$options[[2]]$template$elements) == 2L,
  all(c("henseler2015", "ringle2023") %in% names(refs$refs)),
  is.null(a$refs), # analysis-level refs are unsupported by this compiler

  !any(c("notes", "references") %in% vapply(r$items, `[[`, "", "name"))
)
optionNames <- vapply(a$options, `[[`, "", "name")
stopifnot(all(c("constructs", "correlation", "missing", "threshold", "showPairs") %in% optionNames))
matrix <- Filter(function(x) identical(x$name, "htmtMatrix"), r$items)[[1]]
stopifnot(
  length(matrix$columns) == 1L,
  identical(matrix$columns[[1]]$name, "construct"),
  setequal(unlist(matrix$refs, use.names = FALSE), c("henseler2015", "ringle2023")),
  all(c("constructs", "correlation", "missing") %in% matrix$clearWith)
)
pairTable <- Filter(function(x) identical(x$name, "pairTable"), r$items)[[1]]
stopifnot(
  !("threshold" %in% vapply(pairTable$columns, `[[`, "", "name")),
  identical(unlist(pairTable$clearWith, use.names = FALSE),
            c("constructs", "correlation", "missing", "threshold")),
  !("showPairs" %in% pairTable$clearWith),
  identical(u$compilerMode, "tame"),
  file.exists("jamovi/js/discriminantvalidity.events.js")
)
uiText <- paste(readLines("jamovi/discriminantvalidity.u.yaml"), collapse = " ")
backendText <- paste(readLines("R/discriminantvalidity.b.R"), collapse = " ")
coreText <- paste(readLines("R/htmt-core.R"), collapse = " ")
stopifnot(
  grepl("ListBox", uiText, fixed = TRUE),
  grepl("listItemAdded", uiText, fixed = TRUE),
  grepl("htmt_correlations(self$data", backendText, fixed = TRUE),
  grepl("pairTab$setNote", backendText, fixed = TRUE),
  grepl("for (j in seq.int(i, k))", backendText, fixed = TRUE),
  grepl("for (j in seq_len(i - 1L))", backendText, fixed = TRUE),
  grepl("values[[paste0(\"c\", i)]] <- \"\\u2014\"", backendText, fixed = TRUE),
  !grepl("decision threshold:", backendText, fixed = TRUE),
  sum(gregexpr("The threshold is a diagnostic", backendText,
               fixed = TRUE)[[1]] > 0) == 1L,
  !grepl("stats::cor(", backendText, fixed = TRUE),
  sum(gregexpr("stats::cor(", coreText, fixed = TRUE)[[1]] > 0) == 1L
)
cat("Static jamovi YAML and version checks passed.\n")
