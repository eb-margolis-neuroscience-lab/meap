#' Run the Curate Units Shiny Application
#'
#'  Usage:
#'
#'    1) Select a loaded data set
#'
#'    2) Unit --> Firing pattern
#'        - Select a unit from a list or small-multiples plot
#'        - Highlight firing rate of unit in plots
#'             - Average firing rate of unit across treatments
#'             - Firing density across the experiment duration
#'             - Firing qq-plot across treatments
#'
#'    3) Brushing Firing Patterns
#'        - Select query/response plots
#'        - Select unit in query plot
#'        - highlight unit in response plot
#'
#' @export
shiny_run_curate_units <- function() {
  appDir <- system.file("shiny-apps", "curate_units", package = "meapr")
  if (appDir == "") {
    stop(paste0(
      "Could not find Shiny Apps directory. Try re-installing the `meapr` ",
      "package.", call. = FALSE))
  }

  shiny::runApp(appDir, display.mode = "normal")
}
