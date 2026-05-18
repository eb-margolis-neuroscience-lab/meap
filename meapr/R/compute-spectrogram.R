


compute_spectrogram_multitaper <- function(
    recording,
    k = 5,
    nw = 3,
    Fs = 20000){
  
  # Multitaper spectrogram
  spec <- multitaper::spec.mtm(
    recording,
    k = 5,          # number of tapers
    nw = 3,         # time-bandwidth product
    deltat = 1/Fs,
    plot = FALSE
  )
  plot(spec)
}


#' Multitaper Spectrogram (Chronux-style)
#'
#' Compute a multitaper spectrogram using discrete prolate spheroidal
#' sequences (DPSS), similar to the MATLAB function
#' \code{mtspecgramc} from the Chronux toolbox.
#'
#' The function segments a univariate time series into overlapping windows,
#' applies DPSS tapers within each window, computes the Fourier transform,
#' and averages power across tapers to obtain a time–frequency representation.
#'
#' @param data Numeric vector. Univariate time series.
#'
#' @param movingwin Numeric vector of length 2.
#'   \describe{
#'     \item{movingwin\[1\]}{Window length in seconds.}
#'     \item{movingwin\[2\]}{Step size between successive windows in seconds.}
#'   }
#'
#' @param params List containing spectral parameters:
#'   \describe{
#'     \item{Fs}{Sampling frequency (Hz).}
#'     \item{tapers}{Numeric vector \code{c(TW, K)}, where
#'       \code{TW} is the time-bandwidth product and
#'       \code{K} is the number of tapers.}
#'     \item{fpass}{Numeric vector \code{c(fmin, fmax)} specifying
#'       the frequency band of interest in Hz.}
#'     \item{pad}{(Optional) Integer padding factor. If provided,
#'       FFT length is \eqn{2^(nextpow2(N) + pad)}. Default is no padding.}
#'   }
#'
#' @return A list with components:
#'   \describe{
#'     \item{S}{Matrix of spectral power estimates
#'       (rows = time windows, columns = frequencies).}
#'     \item{times}{Vector of window center times (seconds).}
#'     \item{freqs}{Vector of frequency bins (Hz).}
#'   }
#'
#' @details
#' The multitaper estimate at time window \eqn{t} and frequency \eqn{f} is:
#'
#' \deqn{
#' S(t, f) = \frac{1}{K} \sum_{k=1}^{K}
#' \left| \mathcal{F}\{ x_t \cdot v_k \}(f) \right|^2
#' }
#'
#' where \eqn{v_k} are DPSS tapers with time-bandwidth product
#' \eqn{TW} and \eqn{K} tapers.
#'
#' The implementation relies on the \code{multitaper} package for DPSS
#' generation and uses \code{mvfft()} for efficient column-wise FFT.
#'
#' @section Differences from Chronux:
#' \itemize{
#'   \item Adaptive weighting and jackknife variance estimation
#'   are not included by default.
#'   \item Multi-trial averaging is not implemented.
#'   \item Padding behavior must be explicitly specified via \code{pad}.
#' }
#'
#' @examples
#' Fs <- 1000
#' t <- seq(0, 5, by = 1/Fs)
#' data <- sin(2*pi*10*t) + 0.5*sin(2*pi*40*t)
#'
#' result <- mtspecgramc(
#'   data,
#'   movingwin = c(0.5, 0.05),
#'   params = list(
#'     Fs = Fs,
#'     tapers = c(3, 5),
#'     fpass = c(0, 100)
#'   )
#' )
#'
#' image(result$times, result$freqs,
#'       10*log10(result$S),
#'       xlab = "Time (s)",
#'       ylab = "Frequency (Hz)")
#'
#' @references
#' Mitra, P., & Bokil, H. (2008).
#' Observed Brain Dynamics.
#' Oxford University Press.
#'
#' @seealso \code{\link[multitaper]{dpss}}
#' @importFrom multitaper dpss
#' @importFrom stats mvfft
#'
#' @export
mtspecgramc <- function(data, movingwin, params) {
  
  Fs <- params$Fs
  TW <- params$tapers[1]
  K  <- params$tapers[2]
  fpass <- params$fpass
  
  win_len <- as.integer(movingwin[1] * Fs)
  step    <- as.integer(movingwin[2] * Fs)
  
  n_windows <- floor((length(data) - win_len)/step) + 1
  
  nfft <- win_len
  freqs <- seq(0, Fs/2, length.out = floor(nfft/2) + 1)
  
  fmask <- which(freqs >= fpass[1] & freqs <= fpass[2])
  freqs <- freqs[fmask]
  
  S <- matrix(0, n_windows, length(freqs))
  
  # Precompute DPSS tapers
  tapers <- multitaper::dpss(win_len, k=K, nw=TW)
  
  for (i in 1:n_windows) {
    
    start <- (i-1)*step + 1
    segment <- data[start:(start+win_len-1)]
    
    # Elementwise multiply each taper by the signal
    tapered <- tapers$v * segment
    
    # FFT along columns
    spec  <- mvfft(tapered)
    power <- Mod(spec)^2
    
    nfreq <- floor(nrow(power)/2) + 1
    freqs_full <- seq(0, Fs/2, length.out=nfreq)
    
    fmask <- which(freqs_full >= fpass[1] & freqs_full <= fpass[2])
    
    S[i,] <- rowMeans(power[1:nfreq, ][fmask, ])
  }
  
  times <- seq(0, by=movingwin[2], length.out=n_windows)
  
  return(list(S=S, times=times, freqs=freqs))
}
