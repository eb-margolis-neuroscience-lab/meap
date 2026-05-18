

# questions/comments
#
#  what is wf_i, I don't see where it is defined


# Style:
#   
#  For naming stick to snake_case and limit abbreviations for variables e.g.
#    peak2Trough => peak_to_trough

#################
# Main Function #
#################

#' Extract Waveform Features
#'
#' @param wf `vector` of the waveform amplitudes over timesteps
#' 
#' @returns list of waveform features with fields
#'   - file_name
#'   - unit_num
#'   - file_index
#'   - class
#'   - mainLoc
#'   - locs
#'   - bpd
#'   - bpd_t
#'   - p2p
#'   - p2p_t
#'   - mainAmp
#'   - secAmp
#'   - peak2Trough
#'   - width
#'   - width_t
#'   - halfWidth
#'   - halfWidth_t
#'
#' @export 
extract_waveform_features <- function(wf) {
  # init. list of features to return
  feature.names <- c("file_name", "unit_num", "file_index", 
                  "class", 
                  "mainLoc", "locs", 
                  "bpd", "bpd_t", 
                  "p2p", "p2p_t", 
                  "mainAmp", "secAmp", "peak2Trough",
                  "width", "width_t",
                  "halfWidth", "halfWidth_t")
  features <- vector("list", length(feature.names))
  names(features) <- feature.names
  
  # classify wf and find peaks
  buffer <- classify_waveform(wf, removeNoisy = TRUE) 
  features[[wf_i]]$class <- buffer[1]
  features[[wf_i]]$mainLoc <- buffer[2]
  features[[wf_i]]$locs <- buffer[3:length(buffer)]
  
  # calculate main peak full width and half-width 
  # -> find left-most limit for finding the man peak's width
  #    (if class>5, left limit will be after small peak before main begative
  #    spike, otherwise start is at i=1 of wf)
  before_pk <- 1 
  if (features[[wf_i]]$class > 5) {
    before_pk = features[[wf_i]]$locs[1]
  }
  # -> find right-most limit
  #    (right limit will be location of peak after main deflection, otherwise the end of the wf)
  after_pk = features[[wf_i]]$locs[features[[wf_i]]$locs>features[[wf_i]]$mainLoc][1] 
  if (is.na(after_pk)){
    after_pk = n_samp
  }
  features[[wf_i]]$width = find_peak_width(wf, features[[wf_i]]$mainLoc, before_pk, after_pk, ampRatio=0)
  features[[wf_i]]$width_t = features[[wf_i]]$width[2]-features[[wf_i]]$width[1]
  features[[wf_i]]$halfWidth = find_peak_width(wf, features[[wf_i]]$mainLoc, before_pk, after_pk, ampRatio=0.5)
  features[[wf_i]]$halfWidth_t = features[[wf_i]]$halfWidth[2]-features[[wf_i]]$halfWidth[1]
  
  # calculate biphasic and peak-to-peak durations (DEFINITION NOT SET)
  # -> peak-to-peak defined as time between main spike and subsequent peak
  # -> note: biphasic defined as start of main spike to next peak 
  cond1 = c(2, 3, 5)
  cond2 = c(7)
  if (features[[wf_i]]$class %in% cond1) { 
    start = find_peak_start(wf, start=1, peakLoc=features[[wf_i]]$mainLoc) 
    features[[wf_i]]$bpd = c(start, features[[wf_i]]$locs)/fs
    features[[wf_i]]$p2p = c(features[[wf_i]]$mainLoc, features[[wf_i]]$locs)/fs
    features[[wf_i]]$bpd_t = (features[[wf_i]]$bpd[2]-features[[wf_i]]$bpd[1])/fs
    features[[wf_i]]$p2p_t = (features[[wf_i]]$p2p[2]-features[[wf_i]]$p2p[1])/fs
  } else if (features[[wf_i]]$class %in% cond2) {
    start = find_peak_start(wf, start=features[[wf_i]]$locs[1], peakLoc=features[[wf_i]]$mainLoc)
    features[[wf_i]]$bpd = c(start, features[[wf_i]]$locs[2])/fs
    features[[wf_i]]$p2p = c(features[[wf_i]]$mainLoc, features[[wf_i]]$locs[2])/fs
    features[[wf_i]]$bpd_t = (features[[wf_i]]$bpd[2]-features[[wf_i]]$bpd[1])/fs
    features[[wf_i]]$p2p_t = (features[[wf_i]]$p2p[2]-features[[wf_i]]$p2p[1])/fs
  } else { # for monophasic wfs or those w/o peak after main spike
    features[[wf_i]]$bpd = c(NA, NA)
    features[[wf_i]]$p2p = c(NA, NA)
    features[[wf_i]]$bpd_t = NA
    features[[wf_i]]$p2p_t = NA
  }
  
  # extract amplitude features 
  features[[wf_i]]$mainAmp = wf[[features[[wf_i]]$mainLoc]] 
  features[[wf_i]]$secAmp = wf[[features[[wf_i]]$locs[1]]] 
  features[[wf_i]]$peak2Trough = abs(features[[wf_i]]$secAmp/features[[wf_i]]$mainAmp)
}


# Helper functions --------------------------------------------------------

# returns vector of [class id, main peak loc, any other detected peaks]
# class id's defined as... 
# -> 0: noisy 
# -> 1: positive-spiking, monophasic: (+++)
# -> 2: positive-spiking, biphasic: (+++) -> (-)
# -> 3: positive-spiking, triphasic: (+++) -> (-) -> (+)
# -> 4: negative-spiking, monophasic:
# -> 5: negative-spiking, biphasic: (---) -> (+)
# -> 6: negatve-spiking, biphasic: (+) -> (---)
# -> 7: negative-spiking, triphasic: (+) -> (---) -> (+)

# parameters:
# -> steps: number of increasing and decreasing steps for peak detection
# -> ampRatio: % of largest peak's magnitude used to determine min height of other peaks 
# -> noiseAmpRatio: analogous to ampRatio but for detecting noisy peaks
# -> noisySteps: analogous to steps but for detecting noisy peaks 
classify_waveform <- function(wf, steps=1, ampRatio=0.1, noiseAmpRatio=0.1, noisySteps=1)
{
  # signal properties 
  n = length(wf)
  
  # find main deflection
  main_loc = which.max(abs(wf)) # location
  main_amp = wf[main_loc] # amplitude
  phase = sign(main_amp[[1]]) # phase (positive of negative)
  
  # peak detection parameters 
  ampThresh = ampRatio*abs(main_amp) # min absolute magnitude of peak or valleys 
  noiseThresh = (noiseAmpRatio)*abs(main_amp) # for detecting noisy peaks (usually in the form of oscillations)
  
  # classify waveform
  class <- 0
  returnVal <- c(class, main_loc)
  if (phase>0) { # positive-spiking, determine if class 1-3
    # find peaks and valleys past main peak 
    peaks = pracma::findpeaks(wf[main_loc:n], nups=steps, minpeakheight=ampThresh, sortstr=TRUE, zero='+') 
    valleys = pracma::findpeaks(-wf[main_loc:n], nups=steps, minpeakheight=ampThresh, sortstr=TRUE, zero='+')
    if (length(valleys)>0) { # make magnitude of peaks negative again
      valleys[,1] = -valleys[,1]
    }
    
    # categorize into class 1-3 based on peaks/valleys found
    if (is.null(peaks) && is.null(valleys)) { # monophasic
      class = 1
      returnVal = matrix(c(class, main_loc), nrow=1)
    } else if (!is.null(valleys) && is.null(peaks)) { # biphasic
      class = 2
      valley = which(wf==valleys[1,1])[1]
      returnVal = matrix(c(class, main_loc, valley), nrow=1)
    } else if (!is.null(peaks) && !is.null(valleys) && peaks[1,2]>valleys[1,2]) { # triphasic
      class = 3
      valley = which(wf==valleys[1,1])[1]
      peak = which(wf==peaks[1,1])[1]
      returnVal = matrix(c(class, main_loc, valley, peak), nrow=1)
    }
  } else if (phase<0) { # negative-spiking, determine if class 4-7
    
    # find peaks to the left and right of main, negative spike
    left_peaks = pracma::findpeaks(wf[1:main_loc], nups=steps, minpeakheight=ampThresh, sortstr=TRUE, zero='+')
    right_peaks = pracma::findpeaks(wf[main_loc:n], nups=steps, minpeakheight=ampThresh, sortstr=TRUE, zero='+')
    
    # categorize into class 4-7 based on peaks found 
    if (is.null(left_peaks) && is.null(right_peaks)) { # monophasic 
      class = 4
      returnVal = matrix(c(class, main_loc), nrow=1)
    } else if (is.null(left_peaks) && !is.null(right_peaks)) { # biphasic; peak right of negative spike 
      class = 5
      peak = which(wf==right_peaks[1,1])[1]
      returnVal = matrix(c(class, main_loc, peak), nrow=1)
    } else if (!is.null(left_peaks) && is.null(right_peaks)) { # biphasic; peak left of negative spike
      class = 6
      peak = which(wf==left_peaks[1,1])[1]
      returnVal = matrix(c(class, main_loc, peak), nrow=1)
    } else if (!is.null(left_peaks) && !is.null(right_peaks)) { # triphasic
      class = 7
      # left_peak = which(wf==left_peaks[1,1])[1]
      # right_peak = which(wf==right_peaks[1,1])[1]
      # if (wf[left_peak]>wf[right_peak]) {
      #   class = 7
      # } else {
      #   class = 8
      # }
      returnVal = matrix(c(class, main_loc, left_peak, right_peak))
    }
  }
  
  # check for and classify noisy wfs
  if (class!=0)
  {
    # classify as noise if wf is symmetric about the main peak
    main_loc = which.max(abs(wf)) 
    left = wf[1:main_loc]
    right = rev(wf[main_loc:(2*main_loc-1)])
    r = cor(left, right)
    
    # test for quickness to peak 
    if (class>=6){
      main_start = returnVal[3]
    } else {
      main_start = 1
    }
    peakStart  = find_peak_start(wf, start=main_start, peakLoc=returnVal[2])
    i_rise =returnVal[2]-peakStart
    
    # -> label as noise
    if (r>0.985 && i_rise<3)
    {
      returnVal[1] = 0
    }
    
    # classify as noise there are excess peaks (only looking at areas between detected "true" peaks)
    pks = sort(returnVal[2:length(returnVal)])
    pks = c(1, pks, length(wf))
    excessPks = 0
    window = 3
    for (i in 1:(length(pks)-1))
    {
      start = pks[i]
      stop = pks[i+1]
      smoothed_seg = stats::filter(wf[start:stop], filter = rep(1/window, window), sides = 2) |> as.numeric()
      p = pracma::findpeaks(smoothed_seg, nups=noisySteps, minpeakheight=ampThresh, sortstr=TRUE, zero='+')
      v = pracma::findpeaks(-smoothed_seg, nups=noisySteps, minpeakheight=ampThresh, sortstr=TRUE, zero='+')
      excessPks = excessPks+(length(p)/4)+(length(v)/4) # count # of rows of p,v and sum
    }
    # -> label as noise
    if (excessPks>1)
    {
      returnVal[1] = 0
    }
  }
  
  return(returnVal)
}

# returns vector containing start and stop index of peak width
# parameters: 
# -> wf: input waveform
# -> peakLoc: index of peak of interest
# -> start: start index of wf for measuring width (TODO: default to ) 
# -> stop: stop index of wf for measuring width
# -> ampRatio: % of peak of interest's magnitude used for determining width 
find_peak_width <- function(wf, peakLoc, start, stop, ampRatio=0)
{
  # TODO: check if start and stop arguments provided. If not, default to start/stop of wf 
  
  # determine phase and threshold value for determining width
  phase = sign(wf[peakLoc]) # positive or negative-spiking wf 
  ampThresh = abs(wf[peakLoc]*ampRatio) # abs magnitude (% of peakLoc height) to use for detecting start/stop of peak
  
  # interpolate signal 
  factor = 5
  t_spline <- seq(t[start], t[stop], length.out=length(t)*factor) 
  wf_spline <- pracma::cubicspline(t[start:stop], wf[start:stop], t_spline, endp2nd = TRUE) 
  # -> split signal w.r.t. peakLoc
  peakLoc_spline = which.max(abs(wf_spline)) # location of peakLoc in interpolated signal
  left_spline = wf_spline[peakLoc_spline:1] # all interpolated points left of peakLoc 
  right_spline = wf_spline[peakLoc_spline:length(wf_spline)] # all interpolated points right of peakLoc
  
  # find start of peak width by looking at interpolated points before peakLoc
  left_width = which(phase*left_spline<=ampThresh)[1] 
  if (length(left_width)==0){ # useful for when threshold=0 but wf never baselines at zero 
    left_width = DescTools::Closest(phase*left_spline, ampThresh, which=TRUE)
  }
  left_width = t_spline[which(wf_spline==left_spline[left_width])] # value is returned in time units not index
  
  # find stop of peak width by looking at interpolated points before peakLoc
  right_width = which(phase*right_spline<=ampThresh)[1]
  if (length(right_width)==0){ # useful for when threshold=0 but wf never baselines at zero 
    right_width = DescTools::Closest(phase*right_spline, ampThresh, which=TRUE)
  }
  right_width = t_spline[which(wf_spline==right_spline[right_width])] # value is returned in time units not index
  
  return(c(left_width, right_width))
}


# returns index where peak starts using slope / first-derivative 
# paramters:
# -> wf: input waveform
# -> start: index of wf to start search
# -> peakLoc: location of peak of interest
# -> slopeRatio: % of largest dv found during rise to peak for use in determining start of peak
find_peak_start  <- function(wf, start, peakLoc, slopeRatio=0.25)
{
  phase = sign(wf[peakLoc])
  dv = diff(phase*wf[start:peakLoc])
  slopeThresh = max(dv)*slopeRatio
  peak_start = which(dv>=slopeThresh)[1]
  if (peak_start==0) {
    peak_start = start
  } else {
    peak_start = as.numeric(names(peak_start))-1
  }
  
  return(peak_start)
}