# About this repo

This repo contains files that can be used to analyse the data extracted from the UMotif app for White Swan's Nightingale project. 

Separately, you need to have access to an export of Nightingale data. To get started:

- Download and unzip the data into a directory with is named all-data yymmdd (where yymmdd is the date of the export)
- Copy the files in this repo into that directory

Note: currently the programmes read the directory name to find out what the export date, thus it is important that you follow the naming convention mentioned above, or rewrite the code.

# About the symptoms recorded by UMotif

The input file motif_segmentvalue.csv (which is keyed by motif_segment.csv so refer to that for codes) include all symptom data captured by the app plus some other user-entered data such as adherence to exercise schedule (code 615) and use of anti-inflammatories (code 613). Some of the "symptoms" are actually binary states - those coded 610 (flare status),629 (flare of psoriasis),630 (red painful eyes),628 (blood in stool) - so these have been converted into binary variables. 

You may wish to take a different approach to the coding of flares which here are treated as simply occurring if they started, continued or stopped, or not occurring in any other case.

Note that many users have gaps in their recording of symptoms - ie days with no data at all. To calculate flare duration, we took a conversative view, and assumed that if no flare symptom data has been recorded on a give day, the flare had not continued on that day. 

Certain user IDs are associated with project insiders. These include UserIDs 24597,24670,24671,24674,24633,24632 and 24788. These are included in a string called users_to_ignore

# About the programmes

| Programme | Description |
| ------ | ------ |
| create_output 2.R | Run this to clean up certain files. It will create give output files in the directory. These are detailed below.  |
| Nightingale_analysis_for_UCB_yymmdd | This is a mark down file which will create a short report for UBC detailing user registrations, attached devices, number of regular users, and some boxplots by month showing steps, distance and sleep. Run this once the programme mentioned above has created the output files. |

# About the files created by create_output 2.R

| File | Description |
| ------ | ------ |
| output_registered_users.csv | Is based on the input file output_registered_users.csv. Selects only the needed users and columns  |
| output_activity.csv | Is based on the input file activity_summary.csv. This file has the sleep data is written on a different row from other data captured by the attached device (fitbit, garmin etc.). The output file has this corrected. |
| output_symptom_data.csv | Is based on the input file motif_segmentvalue.csv and motif_segment.csv. The unwanted users have been removed. This file combines the valued and binary syptoms together but excludes the adherence and anti-inflammatory information (on the basis that these are not symptoms).  |
| output_user_date_binaryandvaluedsymptoms.csv | Is based on the file mentioned above, but this dataset has only a single row per user-date-symptom. This collapsing of the data is achieved by taking the mean of the valued data (ie if a user reported a symptom twice on the same data a mean is taken of the reported values; and a simple toggle (whether symptom occurred or not) in the binary data. |
| output_flaresonly_user_date_duration.csv | Is based on the output file discussed above, and calculates duration for each flare by user and start date |


# Notes

