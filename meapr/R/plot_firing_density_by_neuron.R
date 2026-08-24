#' Smoothed Per-Neuron Firing Density Across the Experiment
#'
#' @description Returns a heat-map of the smoothed firing rate where the x-axis
#'   is time measured in seconds and the y-axis are the neuron index. The
#'   duration of treatment interval is marked.
#'
#' @param experiment [meapr::experiment] data set loaded with
#'   [load_experiment_matlab] or [load_experiment_phy]
#' @param include_noise `logical` included noise units in the plot?
#' @param extra_layers `list` extra ggplot2 layers to be added to the plot
#'   before saving it.
#' @param treatments `data.frame` with columns ['treatment', 'begin', 'end'] that
#'   is used to demarcate and label the treatments. If it is not provided, then
#'   the one from the experiment is used. In that case, the treatment index is removed
#'   from the beginning of the treatment label.
#' @param plot_width `numeric` width of the output plot
#' @param plot_height `numeric` height of the output plot. If `include_noise`,
#'   the default is `10`, otherwise `4`.
#' @param output_base `character` the folder where the plot will be saved
#' @param verbose `logical` print out verbose output.
#'
#' @returns: [ggplot2::ggplot] of the plot and it saves the result to
#'   `<output_base>/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.pdf`
#'   and
#'   `<output_base>/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.png`
#'   It save both .pdf and .png because it's easier to email etc small pngs
#'   while for use in an a manuscript having the vector version means that it`
#'   can be tweaked with illustrator
#'
#'
#'@export
plot_firing_density_by_neuron <- function(
  experiment,
  include_noise = FALSE,
  extra_layers = list(),
  treatments = NULL,
  plot_width = 10,
  plot_height = NULL,
  output_base = "product/plots",
  verbose = FALSE) {

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
  }
  
  if (nrow(experiment$firing) == 0) {
    warning(paste0(
      "For experiment '", experiment$tag, "' ",
      "unable to plot firing density by neuron because there are ",
      "no firing events"))
    return(NULL)
  }

  if (is.null(treatments)) {
    treatments <- experiment$treatments |>
      dplyr::mutate(
        treatment = treatment |>
          stringr::str_replace("^[0-9]+_", ""))
  }
  else {
    if (!all(c("treatment", "begin", "end") %in% names(treatments))) {
      warning(paste0(
        "The treatment labels should have the following columns ",
        "['treatment', 'begin', 'end'], instead it has ",
        "['", paste0(names(treatments), collapse = "', '"), "']"))
    }
  }

  data <- experiment$firing |>
    dplyr::select(neuron_index, time_step) |>
    dplyr::mutate(group = "Good Units", .before = 1)

  if (include_noise) {
    data <- dplyr::bind_rows(
      data,
      experiment$firing_noise |>
        dplyr::select(neuron_index, time_step) |>
        dplyr::mutate(group = "Noise Units", .before = 1))
  }

  if (is.null(plot_height)) {
    if (include_noise) {
      plot_height <- 10
    } else {
      plot_height <- 4
    }
  }

  data <- data |>
    dplyr::group_by(group, neuron_index) |>
    dplyr::do({
      data_neuron <- .
      density_estimate <- stats::density(
        x = data_neuron$time_step,
        from = experiment$treatments$begin |> min(),
        to = experiment$treatments$end |> max(),
        adjust = .01,
        n = 1000)
      density_estimate <- tibble::tibble(
        group = data_neuron$group[1],
        neuron_index = data_neuron$neuron_index[1],
        time_step = density_estimate$x,
        firing_density = density_estimate$y)
      #density_estimate <- density_estimate |>
      #  dplyr::mutate(
      #    normalized_log_firing_density =
      #      log(firing_density / max(firing_density) + 1))
      density_estimate
    }) |>
    dplyr::ungroup()

  data <- data |>
    dplyr::mutate(
      normalized_log_firing_density = log10(firing_density + .001))

  p <- ggplot2::ggplot(data = data) +
    ggplot2::theme_bw() +
    ggplot2::geom_tile(
      mapping = ggplot2::aes(
        x = time_step,
        y = factor(neuron_index),
        fill = normalized_log_firing_density)) +
    ggplot2::geom_rect(
      data = experiment$treatments,
      mapping = ggplot2::aes(
        xmin = begin,
        xmax = end,
        ymin = -Inf,
        ymax = Inf,
        group = treatment),
      color = "white",
      alpha = 0) +
    ggplot2::ggtitle(
      "Per-neuron firing density across experiment",
      subtitle = experiment$tag) +
    ggplot2::scale_x_continuous(
      name = "Seconds",
      breaks = round(treatments$begin, 1),
      expand = c(0, 0),
      sec.axis = ggplot2::dup_axis(
        name = NULL,
        breaks = with(treatments, begin + (end - begin) / 2),
        labels = treatments$treatment)) +
    ggplot2::scale_y_discrete(
      name = "Neuron Index",
      expand = c(0, 0)) +
    ggplot2::scale_fill_viridis_c("Per-neuron normalized log firing density") +
    ggplot2::theme(
      legend.position = "bottom",
      axis.text.x.top = ggplot2::element_text(
        angle = 20, hjust = 0.2, vjust = 0.1),
      plot.margin = margin(t = 5.5, r = 30, b = 5.5, l = 5.5, unit = "pt")) +
    extra_layers

  if (include_noise) {
    p <- p +
      ggplot2::facet_grid(
        rows = dplyr::vars(group),
        space = 'free_y',
        scales = 'free_y')
  }

  if (!is.null(output_base)) {

    pdf_path <- paste0(
      output_base, "/firing_density_by_neuron_", experiment$tag,
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
      output_base, "/firing_density_by_neuron_", experiment$tag,
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
