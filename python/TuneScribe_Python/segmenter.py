# import python pitch tracker
# now 'porting' praat.

import numpy
from YIN import Yin


def segmenter(y, fs):
    # frq_path, autoCorr_path, time, amp = praat_pd(y, fs)

    ytracker = Yin(fs)
    frq_path, amp = ytracker.trackPitch(y)

    freqs = frq_path[0]
    time = frq_path[1]
    # amps = amp / numpy.median(amp)
    # Normalize the amp values to be between 0 and 1
    amps = (amp - min(amp)) / (max(amp) - min(amp))
    # print amps
    N = len(freqs)

    # strict freq threshold
    # posHalfStep = pow(2, (1/12.))
    # negHalfStep = pow(2, (-1/12.))

    # More lenient freq threshold that identifies more note changes.
    # Needed for real-life instrument recordings lacking perfect pitch.
    posHalfStep = pow(2, (50/1200.))
    negHalfStep = pow(2, (-50/1200.))

    # The offset vector contains the times of the offsets where a new note
    # begins, and 0s elsewhere.
    offsets = numpy.zeros((N, 1))

    for k in range(1, N):
        # If two consecutive frequencies vary by more than a half step,
        # enter their time offset information into the offsets vector.
        if freqs[k] / freqs[k-1] >= posHalfStep:
            offsets[k] = time[k]
        elif freqs[k] / freqs[k-1] <= negHalfStep:
            offsets[k] = time[k]
        elif amps[k] - amps[k-1] > 0.1:
            offsets[k] = time[k]

    return freqs, offsets