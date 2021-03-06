#!/bin/bash
set -e 
source /etc/profile.d/modules.sh
source /etc/profile.d/quarantine.sh
module load python/2.7.8-anaconda-2.1.0
module load python-extras/2.7.8
module load whitematteranalysis/latest

if [ -z "$2" ]; then
cat <<EOF

Runs the WMA pipeline on input VTK files

Usage:
$0 <inputdir> <outputdir>

Arguments:
  <inputdir>       Folder of subject whole brain vtks (expects dir/*/*_TRACTS.vtk)
  <outputdir>      Parent dir
EOF
  exit 1
fi 

inputfolder=$1            # output/vtks
targetdir=$2              # output/

threads=8
outputfolder=$targetdir

mkdir -p $outputfolder
mkdir -p $outputfolder/vtks
mkdir -p $outputfolder/registered_subjects

cp -l $inputfolder/*/*_TRACTS.vtk $outputfolder/vtks/

if [ ! -e $outputfolder/vtks_qc ]; then
wm_quality_control_tractography.py \
  $outputfolder/vtks $outputfolder/vtks_qc
fi 

if [ ! -e $outputfolder/output_tractography ]; then
wm_register_multisubject_faster.py \
  -f 500 -l 100 -midsag_symmetric \
  -j $threads \
  -norender \
  $outputfolder/vtks $outputfolder
fi 

cp -s \
  $(readlink -f $outputfolder/output_tractography/*.vtk) \
  $outputfolder/registered_subjects/

if [ ! -e $outputfolder/clustered_atlas ]; then
wm_cluster_atlas.py \
  -nystrom_sample 3000 \
  -f 2000 -l 80 -j 6 -k 400 \
  -j $threads \
  $outputfolder/registered_subjects \
  $outputfolder/clustered_atlas
fi 

# change SubsamplingRatio in .mrml to 1.0 to see all tracts
sed -i 's/SubsamplingRatio="0.3"/SubsamplingRatio="1.0"/g' \
  $outputfolder/clustered_atlas/clustered_tracts.mrml
