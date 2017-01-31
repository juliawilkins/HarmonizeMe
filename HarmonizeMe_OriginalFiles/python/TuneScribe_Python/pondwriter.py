import numpy
import os
import subprocess


def pondwriter(tempo, note_bin, octave, note_length, filename, timeSig='4/4', keySig='c', pickup='0'):
    """
    write notes into text file, which can then be read/copied into LilyPond
    :param note_bin: The pitch bins of notes
    :param octave: Octaves of notes
    :param note_length: The length of notes
    :param filename: The filename of the input audio to be translated into filename of the output PDF
    :return:
    """
    # TODO: Fix the below loop. It makes some pieces better, and some worse.
    # Intention is to line up all the bins.
    # if len(note_length) < len(note_bin):
    #     if note_bin[-1] == 0:
    #         # account for last rest
    #         note_length = numpy.append(note_length, 0)
    #     else:
    #         # add zeros to note durations
    #         # note_length = numpy.pad(note_length, len(note_bin) - len(note_length), 'constant')
    #         note_length = numpy.append(note_length, numpy.zeros((len(note_bin) - len(note_length),1)))
    # else:
    #     # add zeros to note letters
    #     # note_bin = numpy.pad(note_bin, len(note_length) - len(note_bin), 'constant')
    #     note_bin = numpy.append(note_bin, numpy.zeros((len(note_length) - len(note_bin), 1)))

    # # make sure octave and letter match up
    # if len(octave) < len(note_bin):
    #     octave = numpy.pad(octave, len(note_bin) - len(octave), 'constant')
    # else:
    #     # note_bin = numpy.pad(note_bin, len(octave) - len(note_bin), 'constant')
    #     note_bin = numpy.append(note_bin, numpy.zeros((len(octave) - len(note_bin), 1)))

    # print note_bin.size
    # print note_length.size
    # print octave.size
    # write to text file
    # header/title
    lilypond_file = filename[:-4] + '.ly'
    lilyfile = open(lilypond_file, 'w')
    lilyfile.write("%s" % '\\version "2.18.2" \n\\header{ \n \t title = "Transcribed Music Score" \n} \n\n')
    lilyfile.write("%s" % '\\score{ \n')
    # choose and write clef
    lilyfile = open(lilypond_file, 'a')

    # find average range of all notes to determine clef
    octave_notinf = octave[~(numpy.isnan(octave))]
    octave_notinf = octave_notinf[~(numpy.isinf(octave_notinf))]
    # print octave_notinf
    avg_octave = numpy.mean(octave_notinf)
    # print avg_octave
    # print note_bin

    if avg_octave > 3.5:  # treble clef (c4 is baseline octave)
        clef = 1
        # all notes are adjusted relative to c4
        lilyfile.write("%s" % "\\relative c' { \n \t \\clef treble \n")
    else:  # bass clef (c3 is baseline octave)
        clef = 0
        # all notes are adjusted relative to c3
        lilyfile.write("%s" % "\\relative c { \n \t \\clef bass \n")

    # Write time and key signatures and pickups based on input values from front-end
    lilyfile.write("%s" % "\\key "+keySig+" \\major")
    lilyfile.write("%s" % "\\time "+timeSig)
    if pickup != "0":
        lilyfile.write("%s" % "\\partial "+pickup)

    # write note names, duration, octave
    # letter values of notes
    note_names = ['c', 'cis', 'd', 'ees', 'e', 'f', 'fis', 'g', 'aes', 'a', 'bes', 'b']
    note_names = numpy.array(note_names)

    # loop through all notes
    aa = 0
    while aa < len(note_bin):
        # % for debugging purposes
        # All below commented out code is copy/paste from matlab
        # current_bin = note_bin[aa];
        # current_length = note_length(aa];
        # current_octave = octave[aa];
        #
        # %% false note (length <= 0 or >= 20)
        if (note_length[aa] <= 0.0) or (note_length[aa] >= 20.0):
            # delete that note
            note_length = numpy.delete(note_length, aa)
            note_bin = numpy.delete(note_bin, aa)
            octave = numpy.delete(octave, aa)

        # true note (length > 0) and not a rest (bin > 0)
        if note_bin[aa] > 0:
            # DEAL WITH CHANGES IN OCTAVE #
            oct_adj = ""
            if aa == 0:  # first note
                if clef == 1:  # treble
                    diff = (note_bin[aa]+(octave[aa]*12)) - (1+(4*12))
                    if diff > 6:
                        oct_adj = "'"
                    elif diff <= -6:
                        oct_adj = ","
                elif clef == 0:  # bass
                    diff = (note_bin[aa]+(octave[aa]*12)) - (1+(3*12))
                    if diff <= -6:
                        oct_adj = ","
                    elif diff > 6:
                        oct_adj = "'"
            else:  # subsequent notes (i.e. not the first note)
                # go a further note back if last "note" was a rest
                step = 1
                first = 0
                while note_bin[aa-step] == 0:
                    if aa-step == 0:
                        # go back to start of note array
                        first = 0
                        break
                    else:
                        # step back further
                        step += 1

                # if we're back at the beginning of array, pretend the current note is the first note
                if first == 1:
                    if clef == 1:  # treble
                        # difference relative to c4
                        diff = (note_bin[aa]+(octave[aa]*12)) - (1+(4*12))
                        if diff > 6:
                            oct_adj = "'"
                        elif diff <= -6:
                            oct_adj = ","
                    elif clef == 0:  # bass clef
                        # difference relative to c3
                        diff = (note_bin[aa]+(octave[aa]*12)) - (1+(3*12))
                        if diff <= -6:
                            oct_adj = ","
                        elif diff > 6:
                            oct_adj = "'"

                else:  # found the previous note
                    # difference in half steps between current and previous note
                    diff = (note_bin[aa]+(octave[aa]*12)) - (note_bin[aa-step]+(octave[aa-step]*12))
                    # adjust octave if diff is greater than a fourth (6 half steps)
                    if diff >= 6:
                        oct_adj = "'"
                    elif diff <= -6:
                        oct_adj = ","
            # done with octaves #

            # DETERMINE BEST WAY TO NOTATE #
            # simple notes
            # TODO: Figure out floor issue
            if numpy.mod(numpy.log2(note_length[aa]/0.25),
                         numpy.floor(numpy.log2(note_length[aa]/0.25))) == 0 and (note_length[aa] <= 4):
                current_note = note_names[int(note_bin[aa])-1] + oct_adj + str(int(4.0/note_length[aa]))
            # simple dotted notes
            elif numpy.mod(numpy.log2(note_length[aa]/0.75),
                         numpy.floor(numpy.log2(note_length[aa]/0.75))) == 0 and (note_length[aa] <= 4):
                current_note = note_names[int(note_bin[aa])-1] + oct_adj + str(int(4.0/(note_length[aa]*2/3))) + '.'

            # tied notes
            else:
                # prepare to add notes
                current_note = ''
                # TODO: SEE IF CURRENT NOTE EVEN HAS A SIZE? it's a string!

                # first, deal with really long notes
                if note_length[aa] > 4:
                    long_note = note_length[aa]
                    while long_note > 4:
                        long_note -= 4
                        # add properly tied whole notes
                        if len(current_note) == 0:
                            current_note = current_note + note_names[int(note_bin[aa])-1] + oct_adj + str(1)
                        else:
                            current_note = current_note + ' ~ ' + note_names[int(note_bin[aa])-1] + str(1)

                    # the leftover bit at the end - treat like normal-length note
                    val = long_note
                else:  # for normal length notes
                    val = note_length[aa]

                # establish reference note length values
                note_values = [4, 2, 1, 0.5, 0.25]
                dur = numpy.zeros((len(note_values), 1))

                # determine composition of notes based on reference lengths
                # loop through all note values
                for qq in range(0, len(dur)):
                    if val-note_values[qq] >= 0:
                        # determine presence of that note value
                        dur[qq] = 1
                        val = val-note_values[qq]

                        # if it's there, add properly tied notes
                        if len(current_note) == 0:
                            current_note = current_note + note_names[int(note_bin[aa])-1] + oct_adj + str(int(4/note_values[qq]))
                        else:
                            current_note = current_note + ' ~ ' + note_names[int(note_bin[aa])-1] + str(int(4/note_values[qq]))

            # rests (length > 0, bin <= 0)
        else:
            # prepare to add rests
            current_note = ''

            # first deal with really long rests
            if note_length[aa] > 4:
                long_note = note_length[aa]
                while long_note > 4:
                    long_note -= 4

                    # add properly tied whole notes
                    if len(current_note) == 0:
                        current_note = current_note + 'r' + str(1)
                    else:
                        current_note = current_note + ' r' + str(1)
                # the leftover bit at the end - treat like normal-length rest
                val = long_note

            else:  # for normal length notes
                val = note_length[aa]

            # establish reference rest length values
            note_values = [4, 2, 1, 0.5, 0.25]
            dur = numpy.zeros((len(note_values), 1))

            # determine composition of rests based on reference lengths
            for qq in range(0, len(dur)):
                if val-note_values[qq] >= 0:
                    # determine presence of that REST value
                    dur[qq] = 1
                    val = val - note_values[qq]

                    # add rests
                    if len(current_note) == 0:
                        current_note = current_note + 'r' + str(int(4/note_values[qq]))
                    else:
                        current_note = current_note + ' r' + str(int(4/note_values[qq]))

        # formatting for each note
        lilyfile.write('\t')
        lilyfile.write('%s' % current_note)
        lilyfile.write('\n')

        # move onto next note
        aa += 1

    # end notation section
    lilyfile.write('%s' % '} \n')
    # Allow for the PDF layout and the MIDI file to be created upon compilation
    lilyfile.write("%s" % '\\layout{ } \n')
    # Record the tempo found in beatmatcher to the MIDI file
    lilyfile.write("%s" % '\\midi{ \n \t \\tempo 4 = ' + str(int(tempo)))
    lilyfile.write("%s" % '\n } \n')
    # end file
    lilyfile.write("%s" % '}')
    # print('text file written')


    # Call lilypond from command line
    subprocess.Popen(['/Applications/Lilypond.app/Contents/Resources/bin/lilypond', lilypond_file])

