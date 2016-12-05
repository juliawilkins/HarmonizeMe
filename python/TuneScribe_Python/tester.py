from segmenter import segmenter
from beatmatcher import beatmatcher
from labeler import labeler
from pondwriter import pondwriter
import os
import subprocess

import scipy.io.wavfile
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy

import sys
import time
# import librosa

from music21 import converter, metadata

# t = time.time()

filename = sys.argv[1]
# timeSig = sys.argv[2]
# keySig = sys.argv[3]
# pickup = sys.argv[4]
timeSig = '4/4'
keySig = 'c'
pickup = '0'


# If the file is not a WAV file, add the extension to make it one.
if filename.endswith('.wav') == False:
	filetemp = filename + '.wav'
	os.rename(filename, filetemp)
	filename = filetemp


# Retrieve WAV file

fs, y = scipy.io.wavfile.read(filename)
# y, fs = librosa.load(filename, sr=44100)

# If the file has two audio channels, just read the first channel.
if y.shape[0] != y.size:
	y = y[:, 0]

# PAD START OF SIGNAL WITH ZEROS HERE 
# fs = samples/second
# samples = fs*seconds
# So how many seconds of silence do we want? 
# --> Let's go with 1/2 a second for now
numZeros = fs/2.0
zeroPadFront = numpy.zeros(numZeros)
y = numpy.append(zeroPadFront,y)

# Pitch

fq, offsets = segmenter(y, fs)
notes, offsets, note_bin, octave, note_dur = labeler(fq, offsets)

# Beats
tempo, beats, offset_match, note_length = beatmatcher(y, fs, offsets, note_dur)


# print offsets
# print offset_match
# Write to text file
pondwriter(tempo, note_bin, octave, note_length, filename, timeSig, keySig, pickup)

# When LilyPond generates the PDF, it automatically puts it in the directory that launched the node server.
# The below code moves the PDF from that directory into the public/uploads directory that holds the
# .wav and .ly files, so now all 3 files are in the uploads directory, and therefore can be accessed by the server.
time.sleep(2)
curr_path = os.getcwd()
orig_pdf = [f for f in os.listdir(curr_path) if f.endswith('.pdf')]
orig_pdf = orig_pdf[0]
pdf_file = filename[:-4] + '.pdf'
os.rename(orig_pdf, pdf_file)

print pdf_file

# elapsed = time.time() - t
# print elapsed

# The following moves the midi to the correct directory as well
orig_midi = [f for f in os.listdir(curr_path) if f.endswith('.midi')]
orig_midi = orig_midi[0]
midi_file = filename[:-4] + '.midi'

os.rename(orig_midi, midi_file)

MIDIName = midi_file

XMLName = filename[:-4] + '.xml'

# Use music21 to convert the generated MIDI file into XML
midi_to_xml = converter.parse(MIDIName)
midi_to_xml.metadata = metadata.Metadata()
midi_to_xml.metadata.title = 'Transcribed Music Score'
midi_to_xml.metadata.composer = 'www.tunescribemusic.com'
midi_to_xml.write('xml', XMLName)

# print note_bin
# print tempo
# print beats
# print offset_match
# print note_length

# Plot the beat track and note onsets
fig = plt.figure()
# beatFig = fig.add_subplot(211)
# beatFig.plot(beats, numpy.ones(numpy.size(beats)), '*')
# beatFig.plot(offsets, 0.95*numpy.ones(numpy.size(offsets)), 'k*')
# beatFig.axis([0, 30, 0, 1.2])
# # beatFig.set_xlabel('Time (Seconds)')
# beatFig.set_title('Beats and Onsets')

# # Plot the pitch track and notes
# pitchFig = fig.add_subplot(212)
# pitchFig.plot(fq, 'k')
# pitchFig.plot(notes)
# pitchFig.set_ylabel('Frequency (Hz)')
# pitchFig.set_xlabel('Time (Seconds)')
# pitchFig.set_title('Pitches')
# fig.savefig(filename[:-4] + '-Plots.png')

# This gets rid of the unsightly hops to zero between segments
for i, note in enumerate(notes):
	if note == 0:
		notes[i] = notes[i-1]
# Plot the pitch track and notes
pitchFig = fig.add_subplot(211)
# Kludge to get correct seconds amount on x axis (rather than seconds * 10)
ax = plt.gca()
scale = 10
ticks = matplotlib.ticker.FuncFormatter(lambda x, pos: '{0:g}'.format(x/(2*scale)))
ax.xaxis.set_major_formatter(ticks)
# Set background color so lines are easier to see.
ax.set_axis_bgcolor('0.75')
pitchFig.step(notes, 'k', linewidth="2", label="Segmented Notes") #Step makes vertical lines

pitchFig.plot(fq, 'r.', linewidth="3", label="Pitch Track")
# pitchFig.step(notes, 'k', linewidth="2", label="Segmented Notes") #Step makes vertical lines
pitchFig.set_ylabel('Frequency (Hz)')
# pitchFig.set_xlabel('Time (Seconds)')
pitchFig.set_title('Pitches')

beatFig = fig.add_subplot(212)
beatFig.plot(beats, numpy.ones(numpy.size(beats)), 'r*', label="Beat Track")
beatFig.plot(offsets, 0.95*numpy.ones(numpy.size(offsets)), 'k*', label="Onsets")
beatFig.set_ylim([0, 1.2])
beatFig.set_xlabel('Time (Seconds)')
beatFig.set_title('Beats and Onsets')

# pitchFig.legend(loc='lower right')
beatFig.legend(loc='lower right')
plt.tight_layout()
fig.savefig(filename[:-4] + '-Plots.png')