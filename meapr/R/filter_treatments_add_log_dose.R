#' Filter to the Treatment Condition and the log10(treatment dose)
#'
#' @param labeled_data `data.frame`
#'
#'@export
treatment_log_dose <- function(labeled_data) {

  treatments_only <- labeled_data |>
    dplyr::filter(condition == "treatment")

  treatments_only$treatment <- as.character(treatments_only$treatment)

  treatments_only |> dplyr::mutate(
    log_dose = dplyr::case_when(
      startsWith(treatment,  "1pM") ~ -12,
      startsWith(treatment,  "10pM") ~ -11,
      startsWith(treatment,  "100pM") ~ -10,
      startsWith(treatment,  "1nM") ~ -9,
      startsWith(treatment,  "10nM") ~ -8,
      startsWith(treatment,  "100nM") ~ -7,
      startsWith(treatment,  "1uM") ~ -6))
}
