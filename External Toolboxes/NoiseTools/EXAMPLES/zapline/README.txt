Example scripts to illustrate nt_zapline().


To run these scripts you'll need to download NoiseTools, and the example data 
files, and set the correct paths.  Some scripts also require FieldTrip. 

Each script is accompanied by an image file that shows the result to expect.  

The examples illustrate the point that the method is applicable to essentially 
any line-noise contaminated data. All data are available on the net.

The main parameter is the the number of noise components to remove.  The appropriate
value depends on the spatio-temporal complexity (number of distinct dimensions) of the 
power line artifact sources. Here, values of 1 to 5 are used.

A secondary parameter that is sometimes (rarely) worth adjusting is the number of 
components to keep in the (optional) PCA stage before the DSS step, that affects 
the tendency to overfit.  



example1: Monkey ECoG from the FieldTrip tutorial data.

example2: EEG, resting state data from Trujillo et al doi, doi:10.3389/fnins.2017.00425

example3: MEG data with large near-DC fluctuations from the NoiseTools example data

example4: MEG data, epoched, from the NoiseTools example data

example5: MEG data from the NoiseTools example data

example6: EEG data from the NoiseTools example data

example7: EEG recorded from electrodes in saline in a glass within a shielded booth. 
Very little artifact, very little removed.

example8: resting state EEG with high sampling rate from https://datadryad.org/resource/doi:10.5061/dryad.v9f16
