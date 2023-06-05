#'Load Firing Data for an Experiment from MATLAB
#'
#' @param units_fname `character`. A file name to a should be a `.mat` file
#'   exported from the Margolis lab multi-electrode experimental MATLAB
#'   processing pipeline containing the following information for each neuron
#'   that was detected
#'   \itemize{
#'     \item{\strong{1) }}{The time steps (in seconds) when it fired during the
#'       experiment}
#'     \item{\strong{2) }}{The waveform of the cluster center across all
#'       firings}
#'   }
#'
#' @param treatments `data.frame` or `character`. If a `data.frame` it should
#'   have columns `[treatment, begin, end]` for each treatment in the
#'   experiment, where begin and end are given as seconds since the beginning of
#'   the experiment. If it is a `character` it should be a path to a `.csv` file
#'   with the same columns. To help detect problems, an warning is given if the
#'   treatments are not disjoint and given chronologically.
#'
#' @param experiment_tag `character` an identifier for the experiment, set
#'   in the return data structure and path to save to disk if null (default),
#'   then use \code{treatments |> basename() |> stringr::str_replace(".mat$",
#'   "")}
#' @param time_steps_per_second `numeric` scaling factor to convert time steps
#'   to seconds. E.g. if the recording is done at 20k Hz, then use `20000`.
#' @param save_path `character` file path where loaded data set should be
#'   cached: `<save_path>/<experiment_tag>`
#' @param verbose `logical` print out verbose output.
#'
#' @returns [meapr-experiment] S3 class with the following elements
#'   \itemize{
#'     \item{\strong{tag: }}{<experiment_tag>}
#'     \item{\strong{treatment: }}{\code{\link[tibble]{tibble}} with columns
#'       \code{[treatment, begin, end]}}
#'     \item{\strong{firings: }}{\code{\link[tibble]{tibble}} with columns
#'       \code{[neuron_index, time_step, treatment, begin, end]} and a row for
#'       each detected firing}
#'     \item{\strong{waveform: }}{\code{\link[tibble]{tibble}} with columns
#'       \code{[neuron_index, time_step, voltage]} for each neuron}
#'   }
#'
#'@export
load_experiment_matlab <- function(
    units_fname,
    treatments,
    experiment_tag = NULL,
    time_steps_per_second = 1,
    save_path = "intermediate_data/experiment_datasets",
    verbose = FALSE) {

  treatments <- load_treatments_file(treatments)

  # If requesting to save the data set exists, make sure it does before trying
  # to read it in.
  if (!is.null(save_path)) {
    if (!dir.exists(save_path)) {
      if (verbose) {
  cat("Creating save path '", save_path, "' ...\n", sep = "")
      }
      dir.create(save_path)
    }
  }

  if (verbose) {
    cat(". Reading in units from file '", units_fname, "' ...\n", sep = "")
  }

  if (!stringr::str_detect(units_fname, ".mat$")) {
    warning(
      paste0(
	"units_fname='", units_fname, "' should have extension .mat\n",
	sep = ""))
  }

  raw_data <- R.matlab::readMat(units_fname)

  ### LOAD UNITS
  firing_dim <- 1
  waveform_dim <- 2
  n_neurons <- dim(raw_data$Unit)[3]

  if (verbose) {
    cat(". Found ", n_neurons, " neurons\n", sep = "")
  }

  firing <- raw_data$Unit[firing_dim, 1, 1:n_neurons] |>
    purrr::imap_dfr(function(time_steps, neuron_index) {
      tibble::tibble(
	neuron_index = neuron_index,
	time_step = as.numeric(time_steps)) / time_steps_per_second
    })

  if (verbose) {
    cat(". Found ", nrow(firing), " firing events\n", sep = "")
  }

  firing <- firing |>
    fuzzyjoin::fuzzy_inner_join(
      treatments,
      by = c("time_step" = "begin", "time_step" = "end"),
      match_fun = list(`>=`, `<`))

  # if there is final end to treatment assume it is millisecond past at the last
  # firing event or the beginning of the last treatment (which ever is greater)
  if (is.na(treatments$end[nrow(treatments)])) {
    treatments$end[nrow(treatments)] <- max(
      treatments$begin[nrow(treatments)] + 0.0001,
      firing$time_step + 0.0001)
    if (verbose) {
      cat(
	"  Since there is no end to the final treatment, setting it past the ",
	" final firing event.", sep = "")
    }
  }

  ### LOAD WAVEFORM
  waveform <- raw_data$Unit[waveform_dim, 1, 1:n_neurons] |>
    purrr::imap_dfr(function(voltages, neuron_index) {
      tibble::tibble(
	neuron_index = neuron_index,
	time_step = seq_along(voltages),
	voltage = as.numeric(voltages))
    })

  if (is.null(experiment_tag)) {
    experiment_tag <- units_fname |>
      basename() |>
      stringr::str_replace(".mat$", "")
  }

  experiment <- list(
    tag = experiment_tag,
    treatments = treatments,
    firing = firing,
    waveform = waveform) |>
    structure(class = "meapr_experiment")

  if (!is.null(save_path)) {
    path <- paste0(save_path, "/", experiment_tag, ".Rdata")
    if (verbose) {
      cat("Saving experiment data to '", path, "'\n", sep = "")
    }
    save(experiment, file = path)
  }

  invisible(experiment)
}
