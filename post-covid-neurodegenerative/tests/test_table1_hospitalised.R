options(warn = 2)
source("tests/table1_hospitalised_helpers.R")
source("analysis/table1/fn-hospitalised_counts.R")

check_counts <- function(df) {
  expected <- sort_counts(legacy_hospitalised_counts(df))
  actual <- sort_counts(hospitalised_counts(df))
  stopifnot(isTRUE(all.equal(actual, expected)))
  invisible(actual)
}

df <- synthetic_hospitalised_data(1000)
result <- check_counts(df)
stopifnot(result$total[result$characteristic == "All"] == nrow(df))
stopifnot("Missing" %in% result$subcharacteristic)
stopifnot(!"unused" %in% result$subcharacteristic)

# The formula method omits an entire patient from all three counts when
# either exposure indicator is missing, even though total itself is present.
df$hospitalised[c(1, 5, 8)] <- NA
df$nonhospitalised[c(2, 5, 9)] <- NA
result <- check_counts(df)
stopifnot(result$total[result$characteristic == "All"] == 995)

# Single observed groups, all missing categories, and logical categories.
df$cov_cat_1 <- factor(rep(NA_character_, nrow(df)), levels = "unused")
df$cov_cat_2 <- "single"
df$cov_cat_3 <- rep(c("Missing", "", "unknown", NA, "TRUE", "FALSE"),
                    length.out = nrow(df))
check_counts(df)
check_counts(df[3, ])

# Both implementations reject inputs with no complete response rows.
df$hospitalised[] <- NA
stopifnot(inherits(try(hospitalised_counts(df), silent = TRUE), "try-error"))
stopifnot(inherits(try(legacy_hospitalised_counts(df), silent = TRUE), "try-error"))
message("Hospitalised counts match the original implementation.")
