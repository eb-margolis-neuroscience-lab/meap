#' Plot Baseline Firing density to evaluate the stability
#'
#' @param experiment [meapr-experiment] data set loaded with
#'   [load_experiment_matlab] or [load_experiment_phy]
#' @param baseline_treatment_name `character` name of the baseline treatment
#' @param event_reshold `numeric` how many events should be used to set the
#'   baseline treshold
#' @param plot_width `numeric` width of the output plot
#' @param plot_height `numeric` height of the output plot
#' @param verbose `logical` print out verbose output.
#'
#' @returns: [ggplot2::ggplot] of the plot and it saves the result to
#'   `product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.pdf`
#'   and
#'   `product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.png`
#'   It save both .pdf and .png because it's easier to email etc small pngs
#'   while for use in an a manuscript having the vector version means that it`
#'   can be tweaked with illustrator
#'
#'
#'@export
plot_stable_baseline <- function(
    experiment,
    baseline_treatment_name = "baseline",
    event_threshold = 200,
    plot_width = 10,
    plot_height = 4,
    output_base = "product/plots",
    verbose = FALSE) {

  if (!(baseline_treatment_name %in% experiment$treatments$treatment)) {
    stop(
      "The baseline treatment '", baseline_treatment_name, "' is not a ",
      "treatment in the experiment '", experiment$tag, "'. The treatments are ",
      "[", paste(experiment$treatments$treatment, collapse = ", "), "]")
  }

  baseline_end <- experiment$treatments[
    experiment$treatments$treatment == baseline_treatment_name,
    "end"] |>
    as.numeric()

  thresholds <- experiment$firing |>
    dplyr::filter(time_step < baseline_end) |>
    dplyr::group_by(neuron_index) |>
    dplyr::mutate(total_events = dplyr::n()) |>
    dplyr::arrange(dplyr::desc(time_step)) |>
    dplyr::slice_head(n = event_threshold) |>
    dplyr::summarize(
      threshold = ifelse(
	total_events[1] > event_threshold,
	min(time_step),
	-Inf),
      .groups = "drop")

  data <- tibble::tibble(
    begin = seq(
      from = 0,
      to = baseline_end,
      length.out = 500),
    end = baseline_end) |>
    dplyr::rowwise() |>
    dplyr::do({

      baseline <- .
      experiment$firing |>
	dplyr::filter(
	  time_step < baseline$end[1],
	  time_step >= baseline$begin[1]) |>
	dplyr::group_by(neuron_index) |>
	dplyr::summarize(
	  baseline_begin = baseline$begin[1],
	  baseline_end = baseline$end[1],
	  firing_rate = dplyr::n() / (baseline$end[1] - baseline$begin[1]),
	  .groups = "drop") |>
	dplyr::left_join(thresholds, by = "neuron_index") |>
	dplyr::mutate(keep = baseline_begin >= threshold)
    })

  p <- ggplot2::ggplot(data = data) +
    ggplot2::theme_bw() +
    ggplot2::geom_hline(
      yintercept = 0.5,
      color = "lightgray",
      size = 2) +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
	x = baseline_begin,
	y = firing_rate,
	group = paste(neuron_index, keep),
	color = keep)) +
    ggplot2::ggtitle(
      "Firing Rate by Baseline Duration",
      subtitle = experiment$tag) +
    ggplot2::scale_x_continuous("Time Step (s)") +
    scale_y_log_firing_rate()

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

    pdf_path <- paste0(
      output_base, "/stable_baseline_", experiment$tag,
      "_", date_code(), ".pdf")
    if (verbose) {
      cat(
	"Saving firing density by neuron plot for experiment ",
	"'", experiment$tag, "' to '", pdf_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      pdf_path,
      width = plot_width,
      height = plot_height)

    png_path <- paste0(
      output_base, "/stable_baseline_", experiment$tag,
      "_", date_code(), ".png")
    if (verbose) {
      cat(
	"Saving firing density by neuron plot for experiment ",
	"'", experiment$tag, "' to '", png_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      png_path,
      width = plot_width,
      height = plot_height)
  }

  invisible(p)
}
