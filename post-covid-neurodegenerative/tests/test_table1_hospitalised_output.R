# Compare both CSV outputs, including suppression, percentages and median rows,
# against the original aggregation within the full script on synthetic inputs.
options(warn = 2)
source("tests/table1_hospitalised_helpers.R")
script <- readLines("analysis/table1/table1_hospitalised.R")
project_dir <- getwd()
scratch <- tempfile("hospitalised-output-")
dir.create(scratch)

run_output_checks <- function() {
  on.exit(unlink(scratch, recursive = TRUE))
  on.exit(setwd(project_dir), add = TRUE, after = FALSE)
  for (directory in c("analysis/table1", "tests", "output/dataset_clean")) {
    dir.create(file.path(scratch, directory), recursive = TRUE)
  }
  file.create(file.path(scratch, ".here"))
  for (path in c("analysis/utility.R", "analysis/table1/fn-hospitalised_counts.R",
                 "tests/table1_hospitalised_helpers.R")) {
    stopifnot(file.copy(path, file.path(scratch, path)))
  }
  df <- synthetic_hospitalised_data(1000)
  df$hospitalised <- df$nonhospitalised <- NULL
  df$All <- NULL
  df$sub_bin_covidhistory <- rep(c(FALSE, FALSE, TRUE), length.out = nrow(df))
  df$sup_bin_preex <- rep(c(TRUE, FALSE), length.out = nrow(df))
  df$cov_num_age <- rep(c(25, 55, 70, 90), length.out = nrow(df))
  df$cov_num_consrate2019 <- rep(0:9, length.out = nrow(df))
  df$exp_date_covid <- rep(as.Date(c("2020-06-01", NA)), length.out = nrow(df))
  df$sub_cat_covidhospital <- factor(rep(
    c("hospitalised", "no_infection", "non_hospitalised"), length.out = nrow(df)
  ))
  # Also exercise factor categories and binary missing values in tibble input.
  df <- tibble::as_tibble(df)
  setwd(scratch)
  for (cohort in c("prevax", "vax", "unvax")) {
    saveRDS(df, paste0("output/dataset_clean/input_", cohort, "_clean.rds"))
    for (preex in c("All", "TRUE", "FALSE")) {
      outputs <- list()
      for (method in c("legacy", "incremental")) {
        code <- script
        code[grepl("^args <- commandArgs", code)] <- sprintf(
          'args <- c("%s", "18;50;65;85;111", "%s")', cohort, preex
        )
        if (method == "legacy") {
          code <- sub("analysis/table1/fn-hospitalised_counts.R",
                      "tests/table1_hospitalised_helpers.R", code, fixed = TRUE)
          code <- sub("df <- hospitalised_counts(df)",
                      "df <- legacy_hospitalised_counts(df)", code, fixed = TRUE)
        }
        writeLines(c("options(warn = 2)", code), "run.R")
        log <- system2(file.path(R.home("bin"), "Rscript"), "run.R",
                       stdout = TRUE, stderr = TRUE)
        stopifnot(is.null(attr(log, "status")))
        files <- sort(list.files("output/table1", full.names = TRUE))
        stopifnot(length(files) == 2)
        outputs[[method]] <- lapply(files, readLines)
        unlink(files)
      }
      stopifnot(identical(outputs$legacy, outputs$incremental))
    }
  }
  message("Both CSV outputs match for all cohorts and pre-existing condition filters.")
}
run_output_checks()
