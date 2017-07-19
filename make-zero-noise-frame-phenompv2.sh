#!/bin/bash

MYPWD=`pwd`

SCRIPTNAME=${BASH_SOURCE[0]}

LABEL=PhenomPv2

#Faceon
FaceOn=0.0
#Pi/4
PiBy3=1.0471975511965976
#Pi/2
PiBy2=1.5707963267948966
#Add more, as needed...

total_mass=80
network_snr=25

inclination=${FaceOn}
mode=PhenomPv2

right_ascension=-1.26157296
declination=1.94972503

polarization=1.75

INCLINATION=`python -c "import numpy; print round(${inclination} * 180/numpy.pi)"`

approx=IMRPhenomPv2

LALINF_RUNNAME=${LABEL}_SNR_${network_snr}_mode_${mode}_inc_${INCLINATION}_M${total_mass} 

GWF_ROOT=$HOME/PE_runs/Pv2/run8
GWF_DIR=${GWF_ROOT}/${LALINF_RUNNAME}

echo "*>> Making Frame File Directory"
echo "*>> ${GWF_DIR}"
mkdir -p ${GWF_DIR}

cp ./$SCRIPTNAME ${GWF_DIR}

#mkdir -p ${LALINF_RUNDIR}

echo "*>> Changing directory to Frame File Directory"
echo "$ cd ${GWF_DIR}"; cd ${GWF_DIR}

echo "*>> Copying PSD Files to Frame File Directory"
cp /home/c1549390/dat/IFO0_psd.dat ./
cp /home/c1549390/dat/IFO1_psd.dat ./

#tag for the .gwf frame file
# tag=zeronoise
tag=${LALINF_RUNNAME}

# Highest f in the waveform is 8kHz
sample_rate=4096
# sample_rate=`python -c "print(2**14)"`
# Nyquist 2^12/2 = 2048 Hz
# Nyquist 2^14/2 = 8192 Hz
psd_segment_length=16

# These two lines work but I want to see if I can get the PE to
# Run with a much shorter frame file.

data_duration=256
# The gps start time of the data (integer seconds)
gps_start_time=1167559433
# The gps end time of the data (integer seconds)
gps_end_time=`python -c "print( int( ${gps_start_time}+${data_duration} ) )"`
# The geocentric GPS end time of the injection
geocentric_end_time=`python -c "print( int( ${gps_end_time}-10 ) )"`

# The + 0.1 in f_min is so that f_min here is not EXACTLY the
# same as in the data but slightly higher: this avoids issues
f_min=26.6205520338
echo "*>> FMin value is ${f_min} Hz"
echo "*>> FMin value is ${f_min}"
f_max=`python -c "print( 80.0*${f_min} )"`

# Export f_min to file: this is the lowest frequency in Hz for the given Total_mass for this waveform
if [ -a f_min.txt ]; then
	rm f_min.txt
	touch f_min.txt
fi
echo ${f_min} >> f_min.txt

# Masses for input
mass1=60.0
mass2=20.0

# Dimensinless spin1 for input
spin1x=0.5
spin1y=0.5
spin1z=0.0
# Dimensionless spin2 for input
spin2x=0.0
spin2y=0.0
spin2z=0.0

# pycbc_generate_hwinj (which doesn't require an injection file) generates
# a single-column ASCII file containing the injection(s), which are then
# inserted into the desired data frame using pycbc_insert_frame_hwinj.
echo
echo "*>> Running pycbc_generate_hwinj..."
pycbc_generate_hwinj \
--instruments H1 L1 \
--approximant ${approx} \
--order pseudoFourPN \
--waveform-low-frequency-cutoff ${f_min} \
--mass1 ${mass1} \
--mass2 ${mass2} \
--spin1x ${spin1x} \
--spin1y ${spin1y} \
--spin1z ${spin1z} \
--spin2x ${spin2x} \
--spin2y ${spin2y} \
--spin2z ${spin2z} \
--inclination ${inclination} \
--polarization ${polarization} \
--ra ${right_ascension} \
--dec ${declination} \
--sample-rate H1:${sample_rate} L1:${sample_rate} \
--channel-name H1:DCS-CALIB_STRAIN_C01 L1:DCS-CALIB_STRAIN_C01 \
--frame-type H1:H1_HOFT_C01 L1:L1_HOFT_C01 \
--psd-estimation median \
--taper TAPER_STARTEND \
--network-snr ${network_snr} \
--psd-low-frequency-cutoff ${f_min}  \
--psd-high-frequency-cutoff ${f_max}  \
--psd-segment-length 16 \
--psd-segment-stride 8 \
--pad-data 8 \
--geocentric-end-time ${geocentric_end_time} \
--gps-start-time ${gps_start_time} \
--gps-end-time ${gps_end_time} \
--strain-high-pass 1
#NOTE: TAPER_START --> TAPER_NONE should also work, as the hybrid is already tapered

hwinj_start_time=`python -c "print( ${gps_end_time}-16 )"`


#to get zero-noise to work add:
# --fake-strain zeroNoise \
# --fake-strain-seed 1
echo
echo "*>> Processing gwf file for H1 ..."
pycbc_insert_frame_hwinj \
--gps-start-time ${gps_start_time} \
--gps-end-time ${gps_end_time} \
--pad-data 8 \
--sample-rate ${sample_rate} \
--hwinj-file hwinjcbc_${hwinj_start_time}_H1.txt  \
--hwinj-start-time ${hwinj_start_time} \
--frame-type H1_HOFT_C01 \
--channel-name H1:DCS-CALIB_STRAIN_C01 \
--ifo H1 \
--output-file H-H1HWINJ_${LABEL}_inc_${INCLINATION}-${gps_start_time}-${data_duration}.gwf \
--strain-high-pass 1 \
--fake-strain zeroNoise

echo
echo "*>> Processing gwf file for L1 ..."
pycbc_insert_frame_hwinj \
--gps-start-time ${gps_start_time} \
--gps-end-time ${gps_end_time} \
--pad-data 8 \
--sample-rate ${sample_rate} \
--hwinj-file hwinjcbc_${hwinj_start_time}_L1.txt  \
--hwinj-start-time ${hwinj_start_time} \
--frame-type L1_HOFT_C01 \
--channel-name L1:DCS-CALIB_STRAIN_C01 \
--ifo L1 \
--output-file L-L1HWINJ_${LABEL}_inc_${INCLINATION}-${gps_start_time}-${data_duration}.gwf \
--strain-high-pass 1 \
--fake-strain zeroNoise

# Store geocentric_end_time to text file for reference in ini file
if [ -a times.txt ]; then
	rm times.txt
	touch times.txt
fi
echo ${geocentric_end_time} >> times.txt
