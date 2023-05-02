library(purrr)
library(meapr)
mc.cores <- 4


## load trimmed experiments
meapr::load_experiment(
  experiment_tag = "demo_firing_trimmed",
  units_fname = "raw_data/demo_firing_units.mat",
  treatments_fname = "raw_data/demo_firing_treatments_trimmed.csv")

meapr::load_experiment(
  experiment_tag = "20190405_15h50m35s_trimmed",
  units_fname = "raw_data/20190405_15h50m35s_units.mat",
  treatments_fname = "raw_data/20190405_15h50m35s_treatments_trimmed.csv")

meapr::load_experiment(
  experiment_tag = "20190405_12h28m32s_trimmed",
  units_fname = "raw_data/20190405_12h28m32s_units.mat",
  treatments_fname = "raw_data/20190405_12h28m32s_treatments_trimmed.csv")

meapr::load_experiment(
  experiment_tag = "20190405_12h28m32s_extraclean_trimmed",
  units_fname = "raw_data/20190405_12h28m32s_extraclean_units.mat",
  treatments_fname = "raw_data/20190405_12h28m32s_treatments_trimmed.csv")



library(purrr)
library(meapr)
mc.cores <- 4

experiments <- c(
  #"intermediate_data/experiment_datasets/demo_firing_trimmed.Rdata",
  #"intermediate_data/experiment_datasets/20190405_12h28m32s_trimmed.Rdata",
  "intermediate_data/experiment_datasets/20190405_15h50m35s_trimmed.Rdata") |>
  #"intermediate_data/experiment_datasets/20190405_12h28m32s_extraclean_trimmed.Rdata") |>
  purrr::map(function(dataset_fname) {
    load(dataset_fname)
    experiment
  })

# summarize the firing and waveform for each experiment
experiments |> purrr::map(function(experiment) {
  #experiment |> meapr::plot_firing_rate_by_neuron()
  #experiment |> meapr::plot_firing_rate_by_treatment()
  #experiment |> meapr::plot_firing_qqplot_by_treatment()
  #experiment |> meapr::plot_lines_firing_rate_by_treatment()
  experiment |> meapr::plot_unit_response_by_treatment()
})

# fit a log-poisson model for each experiment
experiments |> purrr::map(function(experiment) {
  fit <- experiment |> meapr::model_treatment_log_poisson(
    control = list(
      adapt_delta = .9,
      max_treedepth = 15))
  fit |> meapr::plot_model_marginal_effects(
    model_tag = paste0("log_poisson_", experiment$tag))
})

project <- list(
  tag = "Ro_vs_DA_project",
  treatments = experiments |> purrr::map_dfr(
    function(experiment) {
      experiment$treatments |> dplyr::mutate(experiment = experiment$tag)}),
  firing = experiments |> purrr::map_dfr(
    function(experiment) {
      experiment$firing |> dplyr::mutate(experiment = experiment$tag)}),
  waveform = experiments |> purrr::map_dfr(
    function(experiment) {
      experiment$waveform |> dplyr::mutate(experiment = experiment$tag)})) |>
  structure(class = "meapr_experiment")

exposure_counts <- project$firing |>
  dplyr::group_by(neuron_index, treatment, experiment) |>
  dplyr::summarize(
    count = dplyr::n(),
    exposure = end[1] - begin[1]) |>
  dplyr::ungroup()

fit_log_poisson_project <- brms::brm(
  data = exposure_counts,
  formula = count ~
    offset(log(exposure)) +
    treatment +
    (1 | neuron_index) +
    (1 | experiment),
  family = stats::poisson(link = "log"))
