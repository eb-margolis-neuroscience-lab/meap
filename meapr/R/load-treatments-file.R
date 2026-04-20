#' Parse Concentration
#'
#' Parse concentration with SI units into molar units
#'
#' @param concentration_string string number formatted as
#'   "<numeric> <SI units>", where <SI units> is one of
#'   \[M, mM, μM, uM, nM, pM, fM\]
#'
#' @returns numeric molar concentration
#'
#' @examples
#' \dontrun{
#'   1e-8 == parse_concentration("10 nM")
#'   1.3e-6 == parse_concentration("1.3 uM")
#' }
#'
#' @export
parse_concentration <- function(concentration_string) {
  if (is.na(concentration_string)) {
    concentration <- NA_real_
  } else if (concentration_string |> stringr::str_detect(" M$")) {
    concentration <- concentration_string |>
      stringr::str_replace(" M", "") |>
      as.numeric()
  } else if (concentration_string |> stringr::str_detect("mM$")) {
    concentration <- concentration_string |>
      stringr::str_replace("[ ]?mM$", "") |>
      as.numeric()
    concentration <- concentration * 1e-3
  } else if (concentration_string |> stringr::str_detect("μM$")) {
    concentration <- concentration_string |>
      stringr::str_replace("[ ]?μM$", "") |>
      as.numeric()
    concentration <- concentration * 1e-6
  } else if (concentration_string |> stringr::str_detect("uM$")) {
    concentration <- concentration_string |>
      stringr::str_replace("[ ]?uM$", "") |>
      as.numeric()
    concentration <- concentration * 1e-6
  } else if (concentration_string |> stringr::str_detect("nM$")) {
    concentration <- concentration_string |>
      stringr::str_replace("[ ]?nM", "") |>
      as.numeric()
    concentration <- concentration * 1e-9
  } else if (concentration_string |> stringr::str_detect("pM$")) {
    concentration <- concentration_string |>
      stringr::str_replace("[ ]?pM", "") |>
      as.numeric()
    concentration <- concentration * 1e-12
  } else if (concentration_string |> stringr::str_detect("fM$")) {
    concentration <- concentration_string |>
      stringr::str_replace("[ ]?fM", "") |>
      as.numeric()
    concentration <- concentration * 1e-15
  } else {
    warning(
      paste0(
        "Unrecognized format for concentration '", concentration_string, "', ",
        "unable to parse."))
    concentration <- NA_real_
  }
  concentration
}

#' Load treatments file
#'
#'
#' @description A treatments data table has columns `begin`, and `end`, and
#'   `treatment`, where `begin` and `end` are the time-points in seconds when
#'   the treatment is applied.
#'
#' @param treatments `data.frame` or `character`. If a `data.frame` it should
#'   have columns `[index, treatment, begin, end]` for each treatment in the
#'   experiment, where begin and end are given as seconds since the beginning
#'   of the experiment. If it is a `character` it should be a path to a `.tsv`
#'   file with the same columns. To help detect problems, an warning is given
#'   if the treatments are not disjoint and given chronologically.
#'
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

    if (!stringr::str_detect(treatments, ".tsv$")) {
      warning(
        "treatments='", treatments, "' should have '.tsv' extension.\n",
        sep = "")
    }

    treatments <- readr::read_tsv(
      file = treatments,
      col_types = readr::cols(
        begin = readr::col_integer(),
        label = readr::col_character())) |>
      dplyr::mutate(
        index = label |>
          stringr::str_extract("^[0-9]+") |>
          as.numeric(),
        index = index * units_Hz,
        treatment = label |>
          stringr::str_replace("^[0-9]+_", ""),
        is_washout = tolower(treatment) == "washout",
        is_baseline = tolower(treatment) == "baseline",
        end = begin |> dplyr::lead()) |>
      dplyr::filter(
        treatment != "END") |>
      dplyr::select(
        index,
        treatment,
        begin,
        end)
  }

  if (verbose) {
    cat("found '", nrow(treatments), "' treatments\n", sep = "")
  }

  # check each treatment has defined beginning and end points
  for (i in seq_len(nrow(treatments))) {
    if (is.na(treatments$begin[i])) {
      stop(paste0(
        "For treatment '", i, "'='", treatments$treatment[i], "'",
        " the beginning of the treatment must not be NA\n"))
    }
  }

  # the last end point can be undefined
  for (i in seq_len(nrow(treatments) - 1)) {
    if (is.na(treatments$end[i])) {
      stop(paste0(
        "For treatment '", i, "'='", treatments$treatment[i], "'",
        " the end of the treatment must not be NA\n"))
    }
  }

  for (i in seq_len(nrow(treatments) - 1)) {
    if (treatments$begin[i] >= treatments$end[i]) {
      stop(paste0(
        "treatment '", i, "'='", treatments$treatment[i], "'",
        " has begin='", treatments$begin[i], "' >=",
        " end='", treatments$end[i], "'"))
    }
  }

  # check treatments are chronological
  if (nrow(treatments) > 1) {
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
  }
  treatments
}
