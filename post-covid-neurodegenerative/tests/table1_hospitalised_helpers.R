# Reference implementation of the original reshape/aggregate pipeline.
legacy_hospitalised_counts <- function(df) {
  for (column in names(df)[grepl("cov_bin_", names(df))]) {
    df[[column]] <- sapply(df[[column]], as.character)
  }
  df <- dplyr::mutate(df, dplyr::across(where(is.factor), as.character))
  df <- tidyr::pivot_longer(
    df,
    cols = -c(patient_id, hospitalised, nonhospitalised),
    names_to = "characteristic",
    values_to = "subcharacteristic"
  )
  df$total <- 1
  df$subcharacteristic <- ifelse(
    df$subcharacteristic == "" | df$subcharacteristic == "unknown" |
      is.na(df$subcharacteristic),
    "Missing", df$subcharacteristic
  )
  aggregate(
    cbind(total, hospitalised, nonhospitalised) ~
      characteristic + subcharacteristic,
    data = df, sum
  )
}

synthetic_hospitalised_data <- function(n, characteristics = 30L) {
  set.seed(20261030)
  df <- data.frame(
    patient_id = seq_len(n),
    hospitalised = sample(c(TRUE, FALSE), n, replace = TRUE),
    nonhospitalised = sample(c(TRUE, FALSE), n, replace = TRUE)
  )
  for (i in seq_len(characteristics)) {
    df[[paste0("cov_cat_", i)]] <- factor(sample(
      c("a", "b", "c", "", "unknown", NA_character_), n, replace = TRUE
    ), levels = c("a", "b", "c", "", "unknown", "unused"))
  }
  df$cov_bin_condition <- sample(c(TRUE, FALSE, NA), n, replace = TRUE)
  df$strat_cat_region <- sample(c("north", "south"), n, replace = TRUE)
  df$All <- "All"
  df
}

sort_counts <- function(df) {
  df <- as.data.frame(df)
  df <- df[order(df$characteristic, df$subcharacteristic), ]
  rownames(df) <- NULL
  df
}
