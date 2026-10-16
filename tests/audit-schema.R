# Static jamovi definition checks; this does not replace a running jamovi compiler.
library(yaml)
a <- yaml.load_file("jamovi/discriminantvalidity.a.yaml")
u <- yaml.load_file("jamovi/discriminantvalidity.u.yaml")
r <- yaml.load_file("jamovi/discriminantvalidity.r.yaml")
m <- yaml.load_file("jamovi/0000.yaml")
refs <- yaml.load_file("jamovi/00refs.yaml")
d <- read.dcf("DESCRIPTION")
stopifnot(
  identical(as.character(d[1, "Version"]), "1.0.0"),
  identical(as.character(a$version), "1.0.0"),
  identical(as.character(m$version), "1.0.0"),
  identical(a$options[[2]]$name, "constructs"),
  identical(a$options[[2]]$type, "Array"),
  identical(a$options[[2]]$template$type, "Group"),
  length(a$options[[2]]$template$elements) == 2L,
  all(c("henseler2015", "ringle2023") %in% names(refs$refs)),
  !any(c("notes", "references") %in% vapply(r$items, `[[`, "", "name"))
)
optionNames <- vapply(a$options, `[[`, "", "name")
stopifnot(all(c("constructs", "correlation", "missing", "threshold", "showPairs") %in% optionNames))
matrix <- Filter(function(x) identical(x$name, "htmtMatrix"), r$items)[[1]]
stopifnot(
  length(matrix$columns) == 1L,
  identical(matrix$columns[[1]]$name, "construct"),
  all(c("constructs", "correlation", "missing") %in% matrix$clearWith)
)
stopifnot(grepl("ListBox", paste(readLines("jamovi/discriminantvalidity.u.yaml"), collapse=" ")))
cat("Static jamovi YAML and version checks passed.\n")
