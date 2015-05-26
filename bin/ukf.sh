#!/bin/bash
source /etc/profile.d/modules.sh
source /etc/profile.d/quarantine.sh
module load slicer/4.4.0
module load FSL/5.0.7 
module load DTIPrep/1.2.4
module load UKFTractography/2015-05-20

if [ -z "$3" ]; then
cat <<EOF

Runs DTIPrep and UKFTractography on a DWI image

Usage:
  $0 <dwi> <outputdir> <seeds>
EOF
  exit 1
fi 

inputimage=$1           # input NRRD DWI image
outputfolder=$2         # output folder for all outputs
seeds=$3                # number of seeds in the tractography step 
stem=$(basename $inputimage .nrrd)

dtiprep_protocol=${outputfolder}/${stem}_protocol.xml   # xml spec for DTIPrep

threads=8
mkdir -p ${outputfolder}

# Run image through DTIPrep to clean up the image
if [ ! -e $outputfolder/${stem}_QCed.nrrd ]; then
  DTIPrep \
    --DWINrrdFile $inputimage \
    --xmlProtocol $dtiprep_protocol \
    --outputFolder $outputfolder \
    --numberOfThreads $threads \
    --check 
fi

if [ ! -e $outputfolder/${stem}_DTI.nrrd ]; then
  DWIToDTIEstimation \
    --enumeration WLS \
    --shiftNeg \
    $outputfolder/${stem}_QCed.nrrd \
    $outputfolder/${stem}_DTI.nrrd \
    $outputfolder/${stem}_SCALAR.nrrd
fi

if [ ! -e $outputfolder/${stem}_MASK.nrrd ]; then
  DiffusionWeightedVolumeMasking \
    --otsuomegathreshold 0.7 \
    --removeislands \
    ${outputfolder}/${stem}_QCed.nrrd \
    ${outputfolder}/${stem}_SCALAR.nrrd \
    ${outputfolder}/${stem}_MASK.nrrd

fi

if [ ! -e $outputfolder/${stem}_TRACTS.vtk ]; then
  UKFTractography \
    --labels 1 \
    --recordFA \
    --recordTensors \
    --numTensor 2 \
    --freeWater \
    --seedsPerVoxel ${seeds} \
    --numThreads $threads \
    --dwiFile ${outputfolder}/${stem}_QCed.nrrd \
    --maskFile ${outputfolder}/${stem}_MASK.nrrd \
    --tracts ${outputfolder}/${stem}_TRACTS.vtk
fi
