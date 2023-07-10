#' Load treatments file
#'
#' @description A treatments data table has columns `begin`, and `end`, and
#'   `treatment`, where `begin` and `end` are the time-points in seconds when
#'   the treatment is applied.
#'
#' @param treatments `data.frame` or `character`. If a `data.frame` it should
#'   have columns `[treatment, begin, end]` for each treatment in the
#'   experiment, where begin and end are given as seconds since the beginning
#'   of the experiment. If it is a `character` it should be a path to a `.csv`
#'   file with the same columns. To help detect problems, an warning is given
#'   if the treatments are not disjoint and given chronologically.
#' @param verbose `logical` print out verbose output
#'
#' @returns `data.frame` with treatment information. See Description for the
#'   format.
#'
#' @export
load_treatments_file <- function(
    treatments,
    verbose = FALSE) {
  ### LOAD TREATMENTS
  if (inherits(treatments, "character")) {

    if (verbose) {
      cat("Loading treatment schedule from '", treatments, "' ... ", sep = "")
    }

    if (!stringr::str_detect(treatments, ".csv$")) {
      warning(
        "treatments='", treatments, "' should have '.csv' extension.\n",
        sep = "")
    }

    treatments <- readr::read_csv(
      file = treatments,
      col_types = readr::cols(
        treatment = readr::col_character(),
        begin = readr::col_double(),
        end = readr::col_double())) |>
      dplyr::transmute(
        # this is to ensure the correct order of the conditions in plots etc.
        treatment = factor(treatment, labels = treatment, levels = treatment),
        begin,
        end)
  }

  if (verbose) {
    cat("found '", nrow(treatments), "' treatments\n", sep = "")
  }

  # check each treatment is well formed
  for (i in seq_len(nrow(treatments))) {
    if (!is.na(treatments$begin[i]) &&
       !is.na(treatments$end[i]) &&
       (treatments$begin[i] >= treatments$end[i])) {
      stop(paste0(
        "treatment '", i, "'='", treatments$treatment[i], "'",
        " has begin='", treatments$begin[i], "' >=",
        " end='", treatments$end[i], "'"))
    }
  }

  # check treatments are chronological
  for (i in 1:(nrow(treatments) - 1)) {
    if (treatments$end[i] > treatments$begin[i + 1]) {
      stop(paste0(
        "Treatments are out of chronological order:\n",
        "  treatment ", i, "='", treatments$treatment[i], "' ",
        "with begin='", treatments$begin[i], "', end='", treatments$end[i],
        "'\n",
        "  treatment ", i + 1, "='", treatments$treatment[i + 1], "' ",
        "with begin='", treatments$begin[i + 1], "', end='",
        treatments$end[i + 1], "'"))
    }
  }
  treatments
}
