#' Simple lattice plot of the waveforms
#'
#'   Plot a grid of plots, with x-axis in microseconds and y-axis in voltage
#'   One for each waveform in the waveform data.frame
#'
#' @param experiment [meapr-experiment] data set loaded with
#'   [load_experiment_matlab] or [load_experiment_phy]
#'
#' @param plot_width `numeric` width of the output plot
#' @param plot_height `numeric` height of the output plot
#' @param verbose `logical` print out verbose output
#'
#' @returns: [ggplot2::ggplot] of the plot and it saves the result to
#'   `product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.pdf`
#'   and
#'   `product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.png`
#'   It save both .pdf and .png because it's easier to email etc small pngs
#'   while for use in an a manuscript having the vector version means that it`
#'   can be tweaked with illustrator
#'
#'@export
plot_waveform_lattice <- function(
  experiment,
  plot_width = 10,
  plot_height = 10,
  output_base = "product/plots",
  verbose = FALSE) {

  p <- ggplot2::ggplot(data = experiment$waveform) +
    ggplot2::theme_bw() +
    ggplot2::geom_line(mapping = ggplot2::aes(x = time_step, y = voltage)) +
    ggplot2::facet_wrap(~neuron_index) +
    ggplot2::ggtitle("Neuron waveform cluster mean", subtitle = experiment$tag) +
    ggplot2::scale_x_continuous("microsecond") +
    ggplot2::scale_y_continuous("Voltage")

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
      output_base, "/waveform_lattice_", experiment$tag,
      "_", date_code(), ".pdf")
    if (verbose) {
      cat(
        "Saving waveform_lattice plot for experiment ",
        "'", experiment$tag, "' to '", pdf_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      pdf_path,
      width = 10,
      height = 10)

    png_path <- paste0(
      output_base, "/waveform_lattice_", experiment$tag,
      "_", date_code(), ".png")
    if (verbose) {
      cat(
        "Saving waveform_lattice plot for experiment ",
        "'", experiment$tag, "' to '", png_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      png_path,
      width = plot_width,
      height = plot_height)
  }

  invisible(p)
}
