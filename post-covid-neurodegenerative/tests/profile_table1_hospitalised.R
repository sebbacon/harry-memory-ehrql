# Run each method in a fresh process; see docs/table1_hospitalised_memory.md.
options(warn = 2)
suppressPackageStartupMessages(library(dplyr))
loadNamespace("tidyr")
source("tests/table1_hospitalised_helpers.R")
args <- commandArgs(trailingOnly = TRUE)
method <- args[[1]]
n <- as.integer(args[[2]])
characteristics <- as.integer(args[[3]])
df <- synthetic_hospitalised_data(n, characteristics)
if (method == "legacy") {
  count <- legacy_hospitalised_counts
} else if (method == "incremental") {
  source("analysis/table1/fn-hospitalised_counts.R")
  count <- hospitalised_counts
} else {
  stop("Method must be legacy or incremental")
}
gc()
elapsed <- system.time(result <- count(df))[["elapsed"]]
cat(sprintf(
  "method=%s patients=%d characteristics=%d elapsed_seconds=%.3f rows=%d\n",
  method, n, characteristics + 3L, elapsed, nrow(result)
))
cat(sprintf("R=%s dplyr=%s tidyr=%s\n", getRversion(),
            packageVersion("dplyr"), packageVersion("tidyr")))
