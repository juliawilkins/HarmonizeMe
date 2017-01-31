# Porting YIN from JAVA
import numpy


# /**
# * This pitch tracker is an implementation of the YIN pitch tracker described in the paper
#  * A. de Cheveigne and H. Kawahara," YIN, a fundamental frequency estimator for speech and music,"
#  * The Journal of the Acoustical Society of America, 111:1917, 2002
#  *
#  * It is designed to track pitch in single-channel audio encoded as PCM and stored in an array of doubles.
#  *
#  * Example Usage:
#  *            sampleRate, monoAudioBuffer = someWaveFileReader.read('audio.wav')
#  *            ytracker = new Yin(sampleRate)
#  *            freqs = ytracker.trackPitch(monoAudioBuffer)
#  *            print(freqs)
#  *
#  * JAVA version was created Nov 7, 2010
#  * Copyright Bryan Pardo. All rights reserved.
#  * @author pardo
#  * @see <a href="http://www.ircam.fr/pcm/cheveign/pss/2002_JASA_YIN.pdf">YIN, a fundamental frequency estimator for speech and music</a>
#  */

class Yin:
    def __init__(self, sampleRateInHz):
        # holds the input audio to be evaluated for a fundamental frequency (pitch)
        self.analysisWindow = []
        # holds the output of step2 of Yin
        self.d = []
        # holds the output of step3 of Yin
        self.dprime = []
        # sample rate of input audio
        self.sampleRateInHz = sampleRateInHz
        # Below default values may change. AW orig was .025 (40 Hz lowest)
        # the size of the audio buffer (measuered in seconds) used to hold a window of audio and analyze it
        self.analysisWindowSizeInSec = .05
        # This is used to decide when not to label a buffer with a pitch.
        # A value of 0.15 looks like it would be good, based on the paper.
        self.aperiodicityThreshold = .15
        # This is the distance between analysis window centers in seconds.
        self.hopSizeInSec = .05  # use this to make Time vector (Note: was originally .01, took too long)
        # We smooth our pitch track by picking the median pitch over a window centered on the current hop.
        # This variable determines how far away (measured in hops) to do smoothing.
        # E.g. a value of 3 makes for a window of 7 pitch estimates, centered on the current estimate.
        self.halfSmoothingWindowSizeInHops = 1
        # Pitch trackers make octave errors. This value helps set a bias. if epsilon is positive, it will skew the
        # pitch tracker to pick shorter periods (positive octave bias). If epsilon is negative, it will skew things
        # towards lower octaves.
        self.epsilon = .02
        # The lowest frequency Yin can detect is determined by the lngth of the analysis window.
        # The highest is determined by this value. The default is currently 4200 Hz, or just higher than the
        # highest note on the piano.
        self.highestAllowedFrequencyInHz = 4200
        self.shortestAllowedPeriodInFrames = round(float(self.sampleRateInHz) / float(self.highestAllowedFrequencyInHz))

    def trackPitch(self, audio):
        """
        Tracks the pitch over the the length of an array of doubles assumed to represent PCM-encoded audio.
        The hop size between windows is currently the default value of a window of analysis (i.e. analysisWindowSize).
        :param audio: an audio signal
        :return: pitchEstimate, an array where pitchEstimate[0][i] gives the ith pitch estimate in Hz
        and pitchEstimate[1][i] gives the time at the ith estimate
        """
        # figure out how big our analysis window and hop size are in audio frames
        hopSize = int(round(self.hopSizeInSec * self.sampleRateInHz))
        analysisWindowSizeInFrames = int(round(self.analysisWindowSizeInSec * self.sampleRateInHz))

        # print an exception if audio is too short
        maxHop = (len(audio) / hopSize) - 1
        if maxHop < 0:
            print("Audio buffer passed to Yin.trackPitch is shorter than the default audio buffer")

        # estimate the pitch at each hop and put that estimate in an output array.
        pitchEstimate = numpy.zeros((2, maxHop))
        amp = numpy.zeros(maxHop)
        for hop in range(0, maxHop):
            startIdx = hop * hopSize
            endIdx = startIdx + analysisWindowSizeInFrames - 1
            pitchEstimate[0][hop] = self.getPitchInHz(audio[startIdx:endIdx])
            # print('Pitch Estimate:')
            # print(pitchEstimate[0][hop])
            pitchEstimate[1][hop] = float(startIdx) / float(self.sampleRateInHz)
            # print('Time:')
            # print(pitchEstimate[1][hop])
            amp[hop] = numpy.sqrt(numpy.mean(((audio[startIdx:endIdx]) - numpy.mean(audio[startIdx:endIdx])) ** 2))

        # apply median smoothing to estimate by picking the median of a window around the original estimate
        distFromWinCenter = self.halfSmoothingWindowSizeInHops
        origPitch = pitchEstimate[0]
        for i in range(distFromWinCenter, maxHop - distFromWinCenter):
            myArray = origPitch[(i - distFromWinCenter):(i + distFromWinCenter)]
            self.insertionSort(myArray)
            pitchEstimate[0][i] = myArray[distFromWinCenter]
            # print('New Pitch Estimate:')
            # print(pitchEstimate[0][i])

        return pitchEstimate, amp

    @staticmethod
    def insertionSort(num):
        """
        Classic insertion sort.
        :param num: An array to be sorted
        :return: The sorted array
        """
        for j in range(1, len(num)):
            key = num[j]
            i = j - 1

            while i >= 0 and num[i - 1] > key:
                num[i + 1] = num[i]
                i -= 1

            num[i + 1] = key

    def getPitchInHz(self, analysisWindow):
        """
        Takes analysisWindow and finds the best pitch estimate for it in Hz. Note the length of the buffer
        and the sample rate determine the lowest detectable pitch.
        :param analysisWindow: expected to hold linearly encoded PCM audio. Length must be a multiple of 2.
        The lowest pitch detectable will have a period 1/2 the length of the analysisWindow.
        :return: pitchInHz: a pitch estimate in Hz for the window
        """
        self.analysisWindow = analysisWindow

        # do step 2 (which wraps step 1 from the paper into it) of the Yin algorithm
        self.differenceFunction()

        # do step 3 (which calculates a ratio of aperiodic to periodic energy)
        self.cumulativeMeanNormalizedDifferenceFunction()

        # do steps 4 & 6 to generate the pitch estimate (note, step 5 does little, so we leave it out)
        periodInFrames = self.findBestPeriod()

        # now determine the pitch
        # note that self.sampleRateInHz refers to the sample rate of the input audio in the analysisWindow
        pitchInHz = -1
        if periodInFrames > 0:
            pitchInHz = self.sampleRateInHz / periodInFrames

        # return the pitch we found
        return pitchInHz

    def differenceFunction(self):
        """
        Implements Step 2 from Yin paper. Specifically, equation 6
        """
        # now do the formula from the paper
        # self.d = numpy.zeros(int(len(self.analysisWindow) / 2.0))
        # W = len(self.d)
        # for tau in range(0, W):
        #     self.d[tau] = 0
        #     for j in range(0, W):
        #         diff = self.analysisWindow[j] - self.analysisWindow[j + tau]
        #         diff = numpy.float64(diff)  # Fixes overflow error
        #         self.d[tau] += (diff * diff)
         # now do the formula from the paper
        self.d = numpy.zeros(int(len(self.analysisWindow) / 2.0))
        W = len(self.d)
        
        x=self.analysisWindow[0:W]
        Mat1=numpy.tile(x,(W,1))
        Mat2=numpy.zeros((W,W))
        for i in range(0,W):
            Mat2[i,:]=self.analysisWindow[i+1:i+W+1]
            
        self.d=numpy.sum((Mat1-Mat2)**2,axis=1)   
     
    def cumulativeMeanNormalizedDifferenceFunction(self):
        """
        Step 3: Cumulative mean normalized difference function. Equation 8 in the Yin paper.
        This is supposed to capture the ratio of periodic energy (d[t][tau]) to aperiodic energy.
        """
        # self.dprime = numpy.zeros(len(self.d))
        # W = len(self.d)
        # self.dprime[0] = 1
        # for tau in range(1, W):
        #     dsum = 0
        #     for j in range(1, tau + 1):
        #         dsum += self.d[j]
        #     self.dprime[tau] = tau * self.d[tau] / dsum
        self.dprime = numpy.zeros(len(self.d))
        W = len(self.d)
        self.dprime[0] = 1

        Matsum=numpy.zeros((W-1,W-1))
        for j in range(0,W-1):
            Matsum[j,0:j+1]=self.d[1:2+j]

        dsum=numpy.sum(Matsum,axis=1)
        self.dprime[1:]=(self.d[1:]*(1+numpy.arange(W-1)))/dsum

    def findBestPeriod(self):
        """
        picking the best period (tau)
        :return: bestTau: the best period
        """
        tauMin = int(self.shortestAllowedPeriodInFrames)
        if tauMin < 1:
            tauMin = 1

        # now do the formula from the paper
        bestTau = 0

        for tau in range(tauMin, len(self.dprime)):
            if (self.dprime[tau] < (self.dprime[bestTau] - self.epsilon)) and (self.dprime[tau] <
                                                                               self.aperiodicityThreshold):
                bestTau = tau

        return bestTau