import librosa
import numpy


def beatmatcher(y, fs, offsets, note_dur):
    # track beats using time series input
    hop_length = 64
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=fs, hop_length=hop_length)
    beats = librosa.frames_to_time(beat_frames, sr=fs, hop_length=hop_length)

    # find tempo
    # if tempo[3] >= 1:
    #     best_tempo = tempo[1]
    # else:
    #     best_tempo = tempo[2]

    #### START NEW ADDITION
    # ADD IN A BEAT AT THE FINAL POINT OF THE SONG
    # WELL THIS DIDN"T FIX ANYTHING!!!
    # CHanging line 84 changes the length of last beat (else statement)
    # The final sample point of the song occurs at the last index of y
    # The time (in seconds) of this point is len(y)/fs
    lastSample = 1.0*len(y)/fs
    # print lastSample
    # print offsets
    # beats = numpy.append(beats,lastSample) 
    # offsets = numpy.append(offsets,lastSample) 
    #### END NEW ADDITION

    diffBeats = numpy.diff(beats)
    avgBeatLength = numpy.mean(diffBeats)
    # print avgBeatLength, ' seconds per beat'
    # about 20-21 samples per second???
    # NOTE: # samples/sec = 1 / self.hopSizeInSec in YIN.py
    # So if you find out how many seconds in a beat, you can calc how many samples in a beat.
    # This number of samples will be equal to a quarter note!
    # avgBeatSamples = 21.*avgBeatLength
    avgBeatSamples = 21.*avgBeatLength


    max_tempo = 180.  # max allowed tempo

    if avgBeatLength < 60/max_tempo:
        tempo_idx = numpy.zeros(numpy.size(beats))

        # get rid of every other beat
        for ii in xrange(numpy.size(beats)):
            if numpy.mod(ii, 2) == 1:
                tempo_idx[ii] = 1
        beats = beats[tempo_idx == 1]

    # find beat lengths
    diffBeats = numpy.diff(beats)
    diffBeats = numpy.concatenate(([0], diffBeats, [lastSample]))

    # try to match pitch changes to offsets
    offset_match = numpy.zeros(len(offsets))

    for offset_index in range(len(offsets)):
        # print "**"
        for beat_index in range(len(beats)):
            off_beat_diff = offsets[offset_index] - beats[beat_index]
            beatLength = diffBeats[beat_index]
            # if beat_index == len(beats)-1:
            #     off_beat_diff = .0025
            #     beatLength = .5

            # print('testloop')
            # print offset_index, beat_index, beatLength, off_beat_diff
            # print beatLength

            # round to nearest 1/4 note
            if abs(off_beat_diff) < (3*beatLength/16):
                offset_match[offset_index] = beat_index
                break

            # round to nearest 1/16 note
            elif abs(off_beat_diff) < (5*beatLength/16):
                if off_beat_diff < 0:
                    offset_match[offset_index] = beat_index-0.25
                else:
                    offset_match[offset_index] = beat_index+0.25
                break

            # round to nearest 1/8 note
            elif abs(off_beat_diff) < (beatLength/2):
                if off_beat_diff < 0:
                    offset_match[offset_index] = beat_index-0.5
                else:
                    offset_match[offset_index] = beat_index+0.5
                break
            # otherwise assume 16th note
            else:
                if offset_index > 1:
                    offset_match[offset_index] = offset_match[offset_index-1]+0.25


    # offset_match = numpy.append(offset_match,)
    # calculate number of beats per note
    # NOTE: 4 = whole note, 2 = half note, 1 = quarter note, 0.5 = 1/8 note, 0.25 = 1/16 note
    # NOTE: This was the original way of finding beats. To revert to this,
    # comment out the "NEW ADDITION" section below
    # note_length = numpy.diff(offset_match, axis=0)
    note_length = numpy.zeros(len(note_dur))
    # print offset_match
    # print note_length

    # NEW ADDITION:: USE NOTE DUR INSTEAD OF RECALCULATING
    # NOTE: note_dur is the number of sample points long a note is
    # Would it be better to use averageBeat here in some way?
    # Does this only assume that median will always be the quarter note length?
    for i, duration in enumerate(note_dur):
        # rounded = int((numpy.median(note_dur)/4.)*round(float(duration)/(numpy.median(note_dur)/4.)))
        # note_length[i] = rounded/(numpy.median(note_dur))
        rounded = int((avgBeatSamples/4.)*round(float(duration)/(avgBeatSamples/4.)))
        note_length[i] = round((rounded/avgBeatSamples)*4)/4
    # print note_length

    return tempo, beats, offset_match, note_length
