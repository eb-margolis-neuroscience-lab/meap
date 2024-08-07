% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_firing_density_by_neuron.R
\name{plot_firing_density_by_neuron}
\alias{plot_firing_density_by_neuron}
\title{Smoothed Per-Neuron Firing Density Across the Experiment}
\usage{
plot_firing_density_by_neuron(
  experiment,
  include_noise = FALSE,
  plot_width = 10,
  plot_height = NULL,
  output_base = "product/plots",
  verbose = FALSE
)
}
\arguments{
\item{experiment}{\link{meapr-experiment} data set loaded with
\link{load_experiment_matlab} or \link{load_experiment_phy}}

\item{include_noise}{\code{logical} included noise units in the plot?}

\item{plot_width}{\code{numeric} width of the output plot}

\item{plot_height}{\code{numeric} height of the output plot. If \code{include_noise},
the default is \code{10}, otherwise \code{4}.}

\item{verbose}{\code{logical} print out verbose output.}
}
\value{
: \link[ggplot2:ggplot]{ggplot2::ggplot} of the plot and it saves the result to
\verb{product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.pdf}
and
\verb{product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.png}
It save both .pdf and .png because it's easier to email etc small pngs
while for use in an a manuscript having the vector version means that it`
can be tweaked with illustrator
}
\description{
Returns a heat-map of the smoothed firing rate where the x-axis
is time measured in seconds and the y-axis are the neuron index. The
duration of treatment interval is marked.
}
