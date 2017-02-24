# ONSET TEST SCRIPT

import numpy as np
import matplotlib.pyplot as plt
import librosa
import matplotlib.patches as mpatches

with open("test_text_files/Female_1a_Amp_4096.txt") as f:
    rms_vals = [line.rstrip('\n') for line in f]

rms_vals = str(rms_vals).strip('[').strip(']').strip('[').strip(']').strip("'").strip('[').strip(']')
new_array = rms_vals.split(", ")
new_array = [float(i) for i in new_array]

print("RMS: " + str(new_array))

ta, rate = librosa.load("Female_1a.wav", sr=44100)
dur = librosa.get_duration(ta, sr=44100)

#make time stamps
times = np.linspace(0, dur, len(new_array))

# ONSET TEST SCRIPT

# make array of third character (we will see silent values)
with open("test_text_files/Female_1a_Labels.txt", 'r+') as f:
    third_char = [line.split()[2] for line in f] #this gets first word
    
# make array of first character (start onset)    
with open("test_text_files/Female_1a_Labels.txt", 'r+') as f: 
    first_char = [line.split()[0] for line in f]

#find indices of SIL       
index_array = [i for i,val in enumerate(third_char) if val!='SIL']

ground_truth_onsets = [first_char[x] for x in index_array]
ground_truth_onsets = [float(i) for i in ground_truth_onsets]

print("GROUND TRUTH ONSETS: " + str(ground_truth_onsets))

# opening amp labels from detector
with open("test_text_files/Female_1a_Amp_Onsets.txt") as f:
    onset_detector_tests = [line.rstrip('\n') for line in f]

onset_detector_tests = str(onset_detector_tests).strip('[').strip(']').strip('[').strip(']').strip("'").strip('[').strip(']')
amp_array = onset_detector_tests.split(", ")
amp_array = [float(i) for i in amp_array]

print("ONSET DETECTOR TESTS: " + str(amp_array))

# MIDI LABELS - from detector
with open("test_text_files/Female_1a_MIDI_4096.txt") as f:
    midi_detector_tests = [line.rstrip('\n') for line in f]

midi_detector_tests = str(midi_detector_tests).strip('[').strip(']').strip('[').strip(']').strip("'").strip('[').strip(']')
midi_array = midi_detector_tests.split(", ")
midi_array = [float(i) for i in midi_array]


#open labels from frequency onsets detector
with open("test_text_files/Female_1a_FreqOnsets_4096.txt") as f:
    freq_detector_tests = [line.rstrip('\n') for line in f]

freq_detector_tests = str(freq_detector_tests).strip('[').strip(']').strip('[').strip(']').strip("'").strip('[').strip(']')
freq_array = freq_detector_tests.split(", ")
freq_array = [float(i) for i in freq_array]

new_freqs = []
for freq in freq_array:
    new_freqs.append(freq / 44100)
print('freq array' + str(new_freqs))


pitch_times = np.linspace(0, dur, len(midi_array))
wav_times = np.linspace(0,dur, len(ta))

f, axarr = plt.subplots(3, figsize=(15, 9)) #sharex = true/false
green_patch = mpatches.Patch(color='green', label='Ground Truth Onsets')
red_patch = mpatches.Patch(color='red', label='Onset Detector Results')
axarr[0].legend(handles=[green_patch, red_patch])
axarr[0].plot(times, new_array)
axarr[0].set_title('RMS Curve')
axarr[0].set_ylabel('RMS')
axarr[0].set_xlabel('Time (s)')
axarr[1].set_xlabel('Time (s)')
axarr[2].set_xlabel('Time (s)')
axarr[0].axis([0, dur-1, np.min(new_array), np.max(new_array)])
axarr[0].vlines(ground_truth_onsets, 0, np.max(new_array), colors='g')
axarr[0].vlines(amp_array, 0, np.max(new_array), colors='r')

axarr[1].axis([0, dur-1, np.min(midi_array), np.max(midi_array)])
axarr[1].scatter(pitch_times, midi_array)
axarr[1].legend(handles=[green_patch, red_patch])
axarr[1].set_ylabel("MIDI Note Number")
axarr[1].set_title("Pitch Onset Curve")
axarr[1].vlines(ground_truth_onsets, 0, np.max(midi_array), colors='g')
axarr[1].vlines(new_freqs, 0,np.max(midi_array), colors='r')

axarr[2].legend(handles=[green_patch])
axarr[2].plot(wav_times, ta)
axarr[2].set_title("Waveform")
axarr[2].axis([0, dur-1, np.min(ta), np.max(ta)])
axarr[2].set_ylabel("Amplitude")
axarr[2].vlines(ground_truth_onsets, np.min(ta), np.max(ta), colors='g')

f.subplots_adjust(hspace=0.5)
plt.show()
