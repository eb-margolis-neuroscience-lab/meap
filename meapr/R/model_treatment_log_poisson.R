library(rstan)

#' Model Average Firing rate as a Function of Treatment Using Log-Poisson
#'  Regression
#'
#'
#' @description Build a Bayesian hierarchical model for the firing rate
#'  as a function of the treatment and other covariates. This uses log-poisson
#'  regression which  directly estimates the number of firing events with
#'  taking into account the exposure.
#'
#'  treatment as a fixed effect
#'    => treatment
#'
#'  average neuron firing rate as a random effect
#'    => (1|neuron_index)
#'
#'  assume a general linear model with log-poisson link
#'
#' @param experiment [meapr-experiment] data set loaded with
#'   [load_experiment_matlab] or [load_experiment_phy]
#' @param output_base `character` path where the model should be saved. The
#'   output file is `<output_base>/model_log_poisson_<experiment$tag>.stan`
#' @param ...arguments are passed to [brms::brm]
#' @param verbose `logical` print out verbose output
#'
#' @returns [brms::brmsfit] object with the fit model
#'
#'
#'@export
model_treatment_log_poisson <- function(
  experiment,
  output_base = "intermediate_data/models",
  verbose = FALSE,
  ...) {

  exposure_counts <- experiment$firing |>
    dplyr::group_by(neuron_index, treatment) |>
    dplyr::summarize(
      count = dplyr::n(),
      exposure = end[1] - begin[1]) |>
    dplyr::ungroup()


  if (verbose) {
    cat(
      "Fitting log-poisson model for firing counts for experiment ",
      "'", experiment$tag, "'\n", sep = "")
  }

  if (!is.na(output_base)) {
    model_path <- paste0(
      output_base, "/model_log_poisson_", experiment$tag, ".stan")
    cat("Saving stan model to '", model_path, "'\n", sep = "")
  } else {
    model_path <- NULL
  }

  fit_log_poisson <- brms::brm(
    data = exposure_counts,
    formula = count ~ offset(log(exposure)) + treatment + (1 | neuron_index),
    family = stats::poisson(link = "log"),
    save_model = model_path,
    ...)

  if (!is.null(output_base)) {
    if (!dir.exists(output_base)) {
      if (verbose) {
        cat("creating output directory '", output_base, "'\n", sep = "")
      }
      dir.create(
        output_base,
        showWarnings = FALSE,
        recursive = TRUE)
    }

    fit_path <- paste0(
      output_base, "/model_log_poisson_fit_", experiment$tag, ".Rdata")
    if (verbose) {
      cat("Saving log-poisson model fit to '", fit_path, "'\n", sep = "")
    }
    save(fit_log_poisson, file = fit_path)

    summary_path <- paste0(
      output_base, "/model_log_poisson_summary_", experiment$tag, ".txt")
    if (verbose) {
      cat(
        "Saving log-poisson model summary to ",
        "'", summary_path, "'\n", sep = "")
    }
    summary(fit_log_poisson) |>
      utils::capture.output(file = summary_path)
  }

  invisible(fit_log_poisson)
}
