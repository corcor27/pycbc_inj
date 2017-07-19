#!/usr/bin/env bash


#Create new directory for this inference run
NAMEDIR=`date '+%Y%m%d-%H%M%S'`
#DIR=testrun
#NAMEDIR=final/${DIR}
mkdir ${NAMEDIR}

PAR=${NAMEDIR}/parameters.txt

# sampler parameters
OUTPUT=${NAMEDIR}/output.hdf
SEGLEN=8
PSD_INVERSE_LENGTH=4
IFOS="H1 L1"
STRAIN="H1:aLIGOZeroDetHighPower L1:aLIGOZeroDetHighPower"
SAMPLE_RATE=2048
F_MIN=20.
N_WALKERS=5000
N_ITERATIONS=12000
N_CHECKPOINT=1000
PROCESSING_SCHEME=cpu
NPROCS=12
CONFIG_PATH=inference_individual.ini

# get coalescence time as an integer
TRIGGER_TIME_INT=`cat times.txt` 

# start and end time of data to read in
GPS_START_TIME=$((${TRIGGER_TIME_INT} - ${SEGLEN}))
GPS_END_TIME=$((${TRIGGER_TIME_INT} + ${SEGLEN}))

# Output parameters as text file
#printf "Injection approximant = ${INJ_APPROX} \n" > ${PAR}
printf "Trigger time = ${TRIGGER_TIME_INT} \n" >> ${PAR}
#printf "Mass 1 = ${MASS1} \n" >> ${PAR}
#printf "Mass 2 = ${MASS2} \n" >> ${PAR}
#printf "RA = ${RA} \n" >> ${PAR}
#printf "Declination = ${DEC} \n" >> ${PAR}
#printf "Inclination = ${INC} \n" >> ${PAR}
#printf "Phase = ${COA_PHASE} \n" >> ${PAR}
#printf "Polarisation = ${POLARIZATION} \n" >> ${PAR}
#printf "Theta_JN = ${THETA_JN} \n" >> ${PAR}
#printf "Distance (kpc) = ${DISTANCE} \n" >> ${PAR}
#printf "Minimum frequency injected = ${INJ_F_MIN} \n" >> ${PAR}
printf "Sampler min frequency = ${F_MIN} \n" >> ${PAR}
#printf " \nSpin parameters: \n" >> ${PAR}
#printf "Spin1 min = ${MIN_SPIN1} \n" >> ${PAR}
#printf "Spin1 max = ${MAX_SPIN1} \n" >> ${PAR}
#printf "Spin1 min kappa = ${MIN_KAPPA1} \n" >> ${PAR}
#printf "Spin1 max kappa = ${MAX_KAPPA1} \n" >> ${PAR}
#printf "Spin2 min = ${MIN_SPIN2} \n" >> ${PAR}
#printf "Spin2 max = ${MAX_SPIN2} \n" >> ${PAR}
#printf "Spin2 min kappa = ${MIN_KAPPA2} \n" >> ${PAR}
#printf "Spin2 max kappa = ${MAX_KAPPA2} \n" >> ${PAR}
printf " \nSampler parameters: \n" >> ${PAR}
printf "Number of walkers = ${N_WALKERS} \n" >> ${PAR}
printf "Number of checkpoints = ${N_CHECKPOINT} \n" >> ${PAR}
printf "Number of iterations = ${N_ITERATIONS} \n" >> ${PAR}
printf "Number of processors = ${NPROCS} \n" >> ${PAR}
printf " \nOther parameters> \n" >> ${PAR}
printf "Detectors = ${IFOS} \n" >> ${PAR}
printf "Strain = ${STRAIN} \n" >> ${PAR}


# run sampler
# specifies the number of threads for OpenMP
# Running with OMP_NUM_THREADS=1 stops lalsimulation
# to spawn multiple jobs that would otherwise be used
# run sampler
# specifies the number of threads for OpenMP
# Running with OMP_NUM_THREADS=1 stops lalsimulation
# to spawn multiple jobs that would otherwise be used
# by pycbc_inference and cause a reduced runtime.
OMP_NUM_THREADS=1 \
pycbc_inference --verbose \
    --skip-burn-in \
    --update-interval 500 \
    --instruments ${IFOS} \
    --gps-start-time ${GPS_START_TIME} \
    --gps-end-time ${GPS_END_TIME} \
    --pad-data 2 \
    --strain-high-pass 16.\
    --psd-model ${STRAIN} \
    --psd-inverse-length ${PSD_INVERSE_LENGTH} \
    --sample-rate ${SAMPLE_RATE} \
    --low-frequency-cutoff ${F_MIN} \
    --channel-name H1:HWINJ_INJECTED L1:HWINJ_INJECTED \
    --frame-files H1:H-H1HWINJ_q8a0a0_T_112_588n768_fix_scale_inc_0.0-1167559433-256.gwf L1:L-L1HWINJ_q8a0a0_T_112_588n768_fix_scale_inc_0.0-1167559433-256.gwf \
    --processing-scheme ${PROCESSING_SCHEME} \
    --sampler kombine \
    --likelihood-evaluator gaussian \
    --save-psd \
    --save-stilde \
    --save-strain \
    --nwalkers ${N_WALKERS} \
    --niterations ${N_ITERATIONS} \
    --config-file ${CONFIG_PATH} \
    --output-file ${OUTPUT} \
    --checkpoint-interval ${N_CHECKPOINT} \
    --checkpoint-fast \
    --nprocesses ${NPROCS}
