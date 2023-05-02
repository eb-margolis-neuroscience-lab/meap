#' Remove Time Off Baseline
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param baseline_cutoff `numeric` trim the given amount of the start of the
#'   baseline
#' @param baseline_treatment_name `character` name of the baseline treatment
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, but with the
#'   baseline condition trimmed.
#'
#' @export
rm_time_off_baseline <- function(
    exp,
    baseline_cutoff,
    baseline_treatment_name = "Baseline") {

  if (!(baseline_treatment_name %in% names(exp$firing$treatment))) {
    stop(paste0(
      "There is no baseline treatment named '", baseline_treatment_name, "'.",
      "The treatments are [", paste(exp$firing$treatment, sep = ", "), "]"))
  }

  exp$firing$begin <- ifelse(
    exp$firing$treatment == "Baseline",
    exp$firing$begin + baseline_cutoff,
    exp$firing$begin)

  exp$firing <- exp$firing |>
    dplyr::filter(
      time_step >= begin,
      time_step <= end)

  exp
}

#' Trim 60 Seconds off of the Beginning of all Treatments Except the Baseline
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param baseline_treatment_name `character` name of the baseline treatment
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, but with the
#'   each trimmed by 60 seconds
#'
#' @export
rm_60s_treatments <- function(
    exp,
    baseline_treatment_name = "Baseline") {

  exp$begin <- ifelse(
    exp$treatment != baseline_treatment_name,
    exp$begin + 60,
    exp$begin)

  exp |>
    dplyr::filter(
      time_step >= begin,
      time_step <= end)
}


#' Compute the Firing Rate for Each Treatment
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#'
#' @returns `data.frame` with one treatment per row, and columns
#'   * **begin**: beginning time of the treatment (in seconds)
#'   * **end**: end time of the treatment (in seconds)
#'   * **count**: number of firing events during the treatment
#'   * **exposure**: time duration of the treatment (in seconds)
#'   * **firing_rate**: average number of firing evens per second
#'
#' @export
exposure_counts <- function(exp) {
  exp |>
    dplyr::group_by(neuron_index, treatment) |>
    dplyr::summarize(
      begin = begin[1],
      end = end[1],
      count = dplyr::n(),
      exposure = end[1] - begin[1],
      firing_rate = count / exposure,
      .groups = "drop") |>
    tidyr::complete(
      treatment,
      fill = list(
  count = 0,
  exposure = 0,
  firing_rate = 0))
}

#' Filter Neurons by the Firing Rate in the Baseline
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param lower `numeric` lower firing rate to filter by (inclusive)
#' @param upper `numeric` upper firing rate to filter by (inclusive)
#' @param baseline_treatment_name `character` name of the baseline treatment
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, but with only
#'   the neurons where the firing rate is within
#'   `lower <= <firing_rate> <= upper`
#'
#' @export
filter_data_baseline <- function(
    exp,
    lower,
    upper,
    baseline_treatment_name = "Baseline") {

  exp |>
    dplyr::group_by(neuron_index) |>
    dplyr::filter(
      firing_rate[treatment == baseline_treatment_name] >= lower,
      firing_rate[treatment == baseline_treatment_name] <= upper) |>
    dplyr::ungroup()
}


#' For Each Neuron, Normalize Firing Rate to Percent Baseline
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param baseline_treatment_name `character` name of the baseline treatment
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, add an
#'   additional column `norm_firing_rate` that is the percent of the firing rate
#'   in the Baseline condition
#'
#' @export
norm_firing <- function(
    exp,
    baseline_treatment_name = "Baseline") {
  exp |>
    dplyr::group_by(neuron_index) |>
    dplyr::mutate(
      norm_firing_rate =
  100 * firing_rate /
  firing_rate[treatment == baseline_treatment_name]) |>
    dplyr::ungroup()
}


#' Add Neuron Identifier as the Experiment Name and Neuron Index
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param exp_name `character` name for the experiment
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, with two
#'   additional column, `exp_id` with the experiment name given in `exp_name`
#'   and `neuron_id` with the `<exp_name>_<neuron_index>`
#'
#' @export
add_neuron_id <- function(exp, exp_name) {
  exp |>
    dplyr::mutate(
      exp_id = exp_name,
      .before = "neuron_index") |>
    dplyr::mutate(
      neuron_id = stringr::str_c(exp$exp_id, "_", exp$neuron_index),
      .before = "treatment")
}

#' Add Treatment/Control as a Condition Column to an Experiment
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param treatment_label `character` the label for the treatment to be
#'   labeled as `"treatment"` and everything else will be labeled as
#'   `"control"`
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, with an
#'   additional column `condition` where which is either `"treatment"` or
#'   `"control"`, depending on it is the treatment specified in
#'   `treatment_label`
#'
#' @export
label_condition <- function(exp, treatment_label) {
  exp |>
    dplyr::mutate(
      condition = ifelse(
  treatment |>
    stringr::str_detect(
      {{treatment_label}}),
  "treatment",
  "control"))
}

#' Label Each Neuron by it Responsiveness Relative to a Threshold Range
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param min_threshold `numeric` lower firing rate threshold for responsiveness
#' @param max_threshold `numeric` upper firing rate threshold for responsiveness
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, with an
#'   additional column `responsive` taking values
#'   `["decreasing", "increasing", "low_response"]`, depending on whether the
#'   the where the normalized firing rate for the treatment condition below the
#'   `min_threshold`, `rises` above the `max_threshold` or stays between them
#'
#' @export
label_responsiveness <- function(
  exp,
  min_threshold,
  max_threshold) {

  responsiveness_labels <- exp |>
    dplyr::group_by(neuron_id) |>
    dplyr::mutate(
      responsive = dplyr::case_when(
  min(norm_firing_rate[condition == "treatment"],
      na.rm = TRUE) <= min_threshold ~ "decreasing",
  max(norm_firing_rate[condition == "treatment"],
      na.rm = TRUE) >= max_threshold ~ "increasing",
  min(norm_firing_rate[condition == "treatment"],
      na.rm = TRUE) >= min_threshold |
    max(norm_firing_rate[condition == "treatment"],
        na.rm = TRUE) <= max_threshold ~ "low_response")) |>
    dplyr::ungroup()

  exp |> dplyr::left_join(responsiveness_labels, by = "neuron_id")
}

#' Label Neurons That Have a Firing Rate of At least 0.5 Hz in the Baseline
#'
#' @param exp [meapr-experiment], a [meapr] experiment object
#' @param baseline_treatment_name `character` name of the baseline treatment
#'
#' @returns The [meapr-experiment] that was passed in as `exp`, with an
#'   additional column `Hz` with values `"< 0.5 Hz"` or `">= 0.5 Hz"` depending
#'   on the firing rate in the given baseline condition.
#'
#' @export
label_Hz <- function(
  exp,
  baseline_treatment_name = "Baseline") {

  experiment |>
    dplyr::group_by(neuron_id) |>
    dplyr::mutate(
      Hz = dplyr::case_when(
  firing_rate[treatment == baseline_treatment_name] < 0.5 ~ "< 0.5 Hz",
  firing_rate[treatment == baseline_treatment_name] >= 0.5 ~ ">= 0.5 Hz"))
}


clean_norm_label <- function(
  experiment,
  baseline_cutoff,
  exp_name,
  treatment_label,
  min_threshold,
  max_threshold) {

  experiment <- rm_time_off_baseline(experiment, baseline_cutoff)
  firing <- rm_60s_treatments(exp = exp$firing)
  exp <- exposure_counts(exp = exp)
  exp <- norm_firing(exp = exp)
  exp <- add_neuron_id(exp = exp, exp_name)
  exp <- label_condition(exp = exp, treatment_label)
  exp <- label_responsiveness(exp = exp, min_threshold, max_threshold)
  exp <- label_Hz(exp = exp)
  return(exp)
}
