#!/bin/bash 
if [ "$1" = "-n" ]; then
  pre=echo
fi

for i in input/*.nrrd; do 
  bn=$(basename $i .nrrd); 
  id=${bn/.nrrd/}; 
  (
    unset module; 
    $pre qsub -o logs/ -j y -V -cwd -pe per_node 8 -N $id-ukf-5 ./bin/ukf.sh $i ukf-5-seeds/$id 5
  ); 
done
