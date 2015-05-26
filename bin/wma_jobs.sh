#!/bin/bash
# makes jobs for several parameter settings

if [ "$1" = "-n" ]; then
  pre=echo
fi

for nfibers in 1000 2000; do
  for fiberlength in 80 100; do
    for midsag in yes no; do
      for nystrom in 2000 4000; do 
        (
        unset module; 
        $pre qsub -o logs/ -j y -V -cwd -pe per_node 8 \
          -N n$nfibers-l$fiberlength-$midsag-ny$nystrom \
          -l mem_free=10G \
          ./bin/wma.sh $nfibers $fiberlength $midsag $nystrom ukf-2-seeds wma-2-seeds/

        $pre qsub -o logs/ -j y -V -cwd -pe per_node 8 \
      	  -N n$nfibers-l$fiberlength-$midsag-ny$nystrom \
          -l mem_free=10G \
          ./bin/wma.sh $nfibers $fiberlength $midsag $nystrom ukf-5-seeds wma-5-seeds/
        )
      done
    done
  done
done

