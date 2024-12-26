# qCLS
A Matlab app for rapid estimation of equal-loudness contours across frequencies

This program has been created using the Matlab app designer. Run "qCLS_App.mlapp" to start.

Note that the presentation level is set according to the local calibration at the University of Washington Applied Hearing Science Lab. To adjust the level for user's own system, consider modifying the calibration information in StimGenerator.m under the "qCLS_core" folder.

To derive the category boundaries and equal-loudness contours following data collection, run data_analysis_main.m under the "data_analysis" folder. This will prompt the user to select a data file. The computational steps within this script is not simply plotting the raw results, but a post hoc fit of the data to a data-driven (PCA) model of the loudness profile, which depends on the two other files ("qCLS_PCA_Model.*") in the "data_analysis" folder.
