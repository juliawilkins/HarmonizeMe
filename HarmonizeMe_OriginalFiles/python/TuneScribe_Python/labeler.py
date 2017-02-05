import numpy


def labeler(freqs, offsets):
    """Takes the output of segmenter.m, finds the median (or mean?) of the pitch
     in each segment, and then assigns which note it is closest to (freq
    bins). The outputs will be notes, time offsets, the note 'letter' (e.g.
    C#) bin, octave number, and note duration in terms of number of repeats)."""

    N = len(freqs)
    L = len(offsets)

    # index stores the indices at which there are time offsets
    index = numpy.zeros((L, 1))

    j = 0
    for i in range(0, L):
        if offsets[i] > 0:
            index[j] = i
            j += 1

    # Remove all 0 values at the end of the array. Song is over at this point.
    index = index[index != 0]

    # Get rid of zeros in offsets
    offsets = offsets[offsets > 0]

    # Get rid of consecutive offsets (most likely not real)
    t = 1
    unique_index = numpy.ones(numpy.size(index))
    while t < len(index):
        if index[t] == index[t-1]+1:
            unique_index[t] = 0
        t += 1

    index = index[unique_index == 1]
    offsets = offsets[unique_index == 1]

    # replace the first zero in offsets
    offsets = numpy.concatenate(([0], offsets))

    # prepare to find notes
    I = len(index)

    notes = numpy.zeros((N, 1))

    # For each segment of frequencies (aligned with an offset as a starting
    # point), find the median pitch. Apply this to the entire length of the
    # note.
    for k in range(0, I-1):
        notes[index[k]:index[k+1]] = numpy.median(freqs[index[k]:index[k+1]])
        # A possible kludge to deal with octave errors and unwanted medians by ignoring
        # the beginning and end of the note?
        # notes[index[k]:index[k+1]-1] = numpy.median(freqs[index[k]+1:index[k+1]-1])
    # consolidate frequencies and numbers of repeats
    current_freq = notes[0]
    repeats = 1
    note_dur = []
    note_freq = []

    # Save each unique frequency and number of repeats (to give duration)
    for p in range(1, len(notes)):
        # repeated frequency
        if notes[p] == current_freq and p != len(notes):
            repeats += 1  # increase number of repeats
        else:
            note_freq.append(notes[p-1])  # save frequency
            note_dur.append(repeats)  # save number of repeats

            current_freq = notes[p]  # new reference frequency
            repeats = 1  # reset number of repeats

    note_freq = numpy.array(note_freq)
    note_dur = numpy.array(note_dur)
    # print "**LOOK"
    # print note_freq
    # print note_dur
    # offsets = numpy.array(offsets)

    # TODO: Check and modify the below loop - got rid of all the extra zeros and -1s. might want to make more accurate
    # TODO: Make the below work with offsets. 
    # Get rid of false notes
    k =0
    # print note_dur
    ## GET RID OF RESTS/SILENCE AT THE BEGINNING
    ## I.e. start notation on the first pitch.
    starting_rest = True
    while starting_rest == True:
        # print note_dur, len(note_dur)
        # print note_freq, len(note_freq)
        if note_freq[0] <= 0.:
            # print note_freq[0], 'deleted'
            note_freq = numpy.delete(note_freq, 0)
            note_dur = numpy.delete(note_dur, 0)
        else:
            starting_rest = False

    while k+1 < len(note_dur):
        if note_dur[k] <= 4:
            # Check if this could be an octave error
            # If the division of the frequencies, rounded to the nearest integer,
            # is equal to a multiple of 2, then they are octaves of each other
            octavecheck1 = int(note_freq[k+1]/note_freq[k])%2
            octavecheck2 = int(note_freq[k]/note_freq[k+1])%2
            # If so, add the duration of this note to the duration of the following note
            if octavecheck1 == 0 or octavecheck2 == 0:
                note_dur[k+1] += note_dur[k]

            # Delete the original "false" note
            note_dur = numpy.delete(note_dur, k)

            # note_freq[k+1] += note_freq[k]


            note_freq = numpy.delete(note_freq, k)
    # #         # note_bin[k] = []
    # #         # if k < len(offsets):
    # #         #     offsets = numpy.delete(offsets, k)
    # #         # offsets[k] = 0
    # #         # print('ok')
    # #         # octave[k] = []
        else:
            k += 1
    # offsets = offsets[offsets > 0]
    # offsets = numpy.concatenate(([0], offsets))



    # print(notes)
    # print(note_dur)
    # print(note_freq)
    # print(offsets)
    # Determine note letter/octave using chroma numbers
    note_chroma = numpy.log2(note_freq) - numpy.floor(numpy.log2(note_freq))
    octave = numpy.floor(numpy.log2(note_freq)) - 4
    # A kludge to fix the -inf at the beginning when zero-padding is added.
    # This zero-padding was making octave[0] = -inf which for some reason
    # printed all notes one octave higher on the staff than their actual values
    octave[0] = octave[1] 
    # print "OCTAVE"
    # print note_freq
    # print octave

    # Determine center frequencies for each pitch class (equal temperament)
    scale = numpy.zeros((12, 1))
    for k in range(0, 12):
        scale[k] = 440 * pow(2, (k/12.0))

    # print(scale)

    # shift start of scale to 'C' so that chroma bins are arranged from smallest to largest number
    scale = numpy.roll(scale, -3)

    # print(scale)
    # determine center chromas for each pitch class
    ref_chroma = numpy.log2(scale) - numpy.floor(numpy.log2(scale))

    # print(note_chroma)
    # print(ref_chroma)

    # loop through chroma number of each frequency
    note_bin = numpy.zeros((len(note_chroma), 1))

    for d in range(0, len(note_chroma)):
        # no pitch case
        if numpy.isinf(note_chroma[d]):
            note_bin[d] = 0

        # find the right bin for the chroma number
        elif note_chroma[d] < numpy.mean(ref_chroma[1:2]):  # bin 1:C
            note_bin[d] = 1

        elif numpy.mean(ref_chroma[-2:]) <= note_chroma[d]:  # bin 12:B
            note_bin[d] = 12

        else:
            # all other bins (2-11: C#-A#)
            for n in range(2, 11):
                if (numpy.mean(ref_chroma[n-1:n]) <= note_chroma[d]) and note_chroma[d] < numpy.mean(ref_chroma[n:n+1]):
                    note_bin[d] = n
                    break
    # print note_bin,'FINAL1'
    # print note_dur,'FINAL2'
    # print note_bin
    # print len(note_dur),len(note_bin)
    return notes, offsets, note_bin, octave, note_dur