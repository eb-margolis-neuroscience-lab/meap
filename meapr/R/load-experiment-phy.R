#'Load Firing Data for an Experiment from phy
#'
#'@description (Phy)[https://github.com/cortex-lab/phy] is a data exchange
#' framework for electrophysiology data. For example, the SpyKING Circus spike
#' sorter data can be exported in phy format. This function will load data from
#' the export in the `*.modat.GUI/` folder
#'
#' @param treatments `data.frame` or `character`. See [load_treatments_file]
#'   for details.
#'
#' @param data_path `character` path to phy data path. It should be
#'   a directory with the output of running phy spike sorter, usually
#'   with an extension of `.modat.GUI`.
#'
#' @param experiment_tag `character` an identifier for the experiment, set
#'   in the return data structure and path to save to disk.
#'
#' @param save_path `character` file path where loaded data set should be
#'   cached: `<save_path>/<experiment_tag>`
#' @param verbose `logical` print out verbose output
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
load_experiment_phy <- function(
    data_path,
    treatments,
    experiment_tag = NULL,
    save_path = "intermediate_data/experiment_datasets",
    verbose = FALSE) {

  treatments <- load_treatments_file(treatments)

  if (is.null(experiment_tag)) {
    experiment_tag <- data_path |>
      basename() |>
      stringr::str_replace(".modat.GUI$", "")
    if (verbose) {
      cat("Using '", experiment_tag, "' as the experiment_tag\n", sep = "")
    }
  }  
  
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
    cat("Reading in phy data from '", data_path, "' ...\n", sep = "")
  }

  if (!stringr::str_detect(data_path, ".modat.GUI$")) {
    warning(
      paste0(
        "Expected the data path to have extension '.modat.GUI'. Instead ",
        "the data path is '", data_path, "'"))
  }
  
  # check that numpy can be loaded via reticulate
  tryCatch({
    np <- reticulate::import("numpy")
  }, error = function(e){
    stop(paste0(
      "Unable to load numpy via reticulate:\n",
      e$message))
  })
  
  electrode_data <- tibble::tibble(
    channel_map = np$load(paste0(data_path, "/channel_map.npy")),
    np$load(paste0(data_path, "/channel_positions.npy")) |>
      as.data.frame() |>
      dplyr::rename(
        channel_position_X = V1,
        channel_position_Y = V2),
    channel_shanks = np$load(
      paste0(data_path, "/channel_shanks.npy")))
  
  if (verbose) {
    cat("  Found data for ", nrow(electrode_data), " electrodes\n", sep = "")
  }
  
  firing_data <- tibble::tibble(
    neuron_index = spike_clusters <- np$load(
      paste0(data_path, "/spike_clusters.npy")),
    template_id = spike_templates <- np$load(
      paste0(data_path, "/spike_templates.npy")),
    time_step = np$load(paste0(data_path, "/spike_times.npy")) / 20000,
    amplitude = np$load(paste0(data_path, "/amplitudes.npy")))

  if (verbose) {
    cat("  Found data for ", nrow(firing_data), " firing events\n", sep = "")
  }

  # cluster_group.csv and cluster_purity.csv are already in cluster_info.tsv
  neuron_data <- readr::read_tsv(
    file = paste0(data_path, "/cluster_info.tsv"),
    show_col_types = FALSE) |>
    dplyr::rename(
      neuron_inded = cluster_id)

  if (verbose) {
    cat(
      "  Found data for ", nrow(neuron_data), " waveform clusters\n",
      sep = "")
  }
  
  # if there is final end to treatment assume it is millisecond past at the last
  # firing event or the beginning of the last treatment (which ever is greater)
  if (is.na(treatments$end[nrow(treatments)])) {
    treatments$end[nrow(treatments)] <- max(
      treatments$begin[nrow(treatments)] + 0.0001,
      firing_data$time_step + 0.0001)
    if (verbose) {
      cat(
      "  Since there is no end to the final treatment, setting it past the ",
      " final firing event.", sep = "")
    }
  }
  
  if (!is.null(treatments)) {
    firing_data <- firing_data |>
      fuzzyjoin::fuzzy_inner_join(
        treatments,
        by = c("time_step" = "begin", "time_step" = "end"),
        match_fun = list(`>=`, `<`))
  } else {
    if (verbose) {
      cat("Didn't load any treatment information because treatment is NULL\n")
    }
  }

  experiment <- list(
    tag = experiment_tag,
    treatments = treatments,
    firing = firing_data,
    electrode = electrode_data,
    waveform = neuron_data,
    spike_sorter = "phy") |>
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
