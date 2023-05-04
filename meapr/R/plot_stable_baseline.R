#' Plot Baseline Firing density to evaluate the stability
#'
#' @param experiment [meapr-experiment] data set loaded with
#'   [load_experiment_matlab] or [load_experiment_spyking_circus]
#' @param baseline_treatment_name `character` name of the baseline treatment
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

  data <- tibble::tibble(
    begin = seq(
      from = 0,
      to = baseline_end,
      length.out = 300),
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
          firing_rate = dplyr::n() / (baseline$end[1] - baseline$begin[1])) |>
        dplyr::ungroup()
    })
  p <- ggplot2::ggplot(data = data) +
    ggplot2::theme_bw() +
    ggplot2::geom_smooth(
      mapping = ggplot2::aes(
        x = baseline_begin,
        y = firing_rate,
        group = neuron_index,
        color = neuron_index),
      method = "gam",
      formula = y ~ s(x, bs = "cs", k=50),
      se = FALSE) +
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
