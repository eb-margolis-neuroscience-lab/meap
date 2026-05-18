

#' Load MED64 Recording Trace
#' 
#' @description Load the raw recording trace in as an array. This assumes the
#' data is organized as raw signed 16bit integers as a little endian
#' column-major array.
#' 
#' @param data_path `character` path to `modat.bin` file
#' @param n_channels `integer` number of channels (Default: 64)
#' @param verbose `logical` verbose output (Default: FALSE)
#' 
#' @returns `matrix` with dimensions `[n_channels, n_samples]` with values
#'   as signed integers, typically in the range e.g. `[-100, 100]`.

#' @examples
#' \dontrun{
#'   recording <- meapr::load_recording(
#'     data_path = '20250131_15h42m41s.modat.bin')
#'   shape(recording)
#' }
#'
#' \dontrun{
#'   extract_path <- tempdir()
#'   unzip(
#'     zipfile = "20250131_15h42m41s.modat.bin.filtered.zip",
#'     extdir = extract_path)
#'   recording <- meapr::load_recording(
#'     data_path = paste0(extract_path, "/20250131_15h42m41s.modat.bin"))
#' }
#' 
#' @export
load_recording <- function(
    data_path,
    n_channels = 64,
    verbose = FALSE) {
  
  # Open binary connection
  if (is.character(data_path) && length(data_path) == 1) {
    if (!file.exists(data_path)) {
      cat(
        "WARNING: Input data path '", data_path, "' doesn't exist \n",
        sep = "")
    }
    
    if (verbose) {
      cat("Reading file '", data_path, "' ",
          "with '", file.info(data_path)$size, "' bytes\n", sep = "")
    }
    con <- file(data_path, "rb")
  } else {
    stop("Input must be a file path")
  }
  
  # Read entire file as int16
  data_flat <- readBin(
    con,
    what = integer(),
    n = file.info(data_path)$size / 2,
    size = 2,          # int16 = 2 bytes
    signed = TRUE,
    endian = "little"
  )
  close(con)
  
  # Check divisibility
  n_total <- length(data_flat)
  if (n_total %% n_channels != 0) {
    stop(
      paste0(
        "File length is not divisible by the number of channels: ",
        "'", n_channels, "'\n"))
  }
  
  n_samples <- n_total / n_channels
  
  recording <- matrix(
    data_flat,
    nrow = n_channels,
    ncol = n_samples,
    byrow = FALSE)
  
  recording
}