
users_to_ignore<-c(24597,24670,24671,24674,24633,24632,24788)

library(data.table)
library(dplyr)
library(lubridate)

wd<-getwd()
date_string<-ymd(substring(wd,nchar(wd)-5,nchar(wd)))

### REGISTRATION DATA ###

registration_data<-read.csv("form-registration.csv", stringsAsFactors = FALSE)

#remove unwanted users 
unwanted_users<-(registration_data$userid %in% users_to_ignore)
registration_data<-registration_data[!unwanted_users,]

#remove unwanted fields
registered_users<-registration_data[,c(16,22)]
registered_users$EntryDateYMD<-as.Date(strtrim(registered_users$DateCreated,10))
rm(registration_data)

### ATTACHED DEVICE DATA ###

activity_data<-read.csv("activity_summary.csv", stringsAsFactors = FALSE)

#remove unwanted users 
unwanted_users<-(activity_data$UserId %in% users_to_ignore)
activity_data<-activity_data[!unwanted_users,]

## SYMPTOM DATA - CLEAN UP ##
#This is necessary because the sleep data is being written on a different row 

#take subset of only dates after launch
activity_data_keep<-subset(activity_data,activity_data$EntryDate>"2018-04-05")
activity_data_keep<-activity_data_keep[,c(2,3,4,5,6,7,8,9,10)]
activity_data_keep$EntryDateYMD<-as.Date(strtrim(activity_data_keep$EntryDate,10)) 
#activity_data_keep$DateCreated<-strptime(activity_data_keep$DateCreated,"%Y-%m-%d %H:%M:%S")

#reorder by user and activity data (needed for what's coming next)
activity_data_keep<-activity_data_keep[order(activity_data_keep$UserId,activity_data_keep$Source,activity_data_keep$EntryDate), ]

activity_data_null_source<-subset(activity_data_keep,activity_data_keep$Source == "")
activity_data_has_source<-subset(activity_data_keep,activity_data_keep$Source != "")

#clean up the error
clean_activity_data_has_source<-data.frame()

for (i in 1:nrow(activity_data_has_source)) {
        b<-activity_data_has_source[i,]
        
        if (i == nrow(activity_data_has_source)) {  #deal with last row
                bminusone<-activity_data_has_source[i-1,]
                
                #can't be first row in pair
                firstrowpair <-FALSE
                
                #check for second row in pair
                secondrowpair<-b$UserId==bminusone$UserId && b$Source==bminusone$Source && b$EntryDateYMD==bminusone$EntryDateYMD
                
                #check for solo row
                solo<-b$EntryDateYMD != bminusone$EntryDateYMD
                
        }
        else {if (i == 1) { #deal with first row
                bplusone<-activity_data_has_source[i+1,]
                
                #check for first row in pair
                firstrowpair<-b$UserId==bplusone$UserId && b$Source==bplusone$Source && b$EntryDateYMD==bplusone$EntryDateYMD
                
                #can't be second row in pair
                secondrowpair<-FALSE
                
                #check for solo row
                solo<-b$EntryDateYMD != bplusone$EntryDateYMD
                
        }
                else
                {
                        bplusone<-activity_data_has_source[i+1,]
                        bminusone<-activity_data_has_source[i-1,]
                        
                        #check for first row in pair
                        firstrowpair<-b$UserId==bplusone$UserId && b$Source==bplusone$Source && b$EntryDateYMD==bplusone$EntryDateYMD
                        
                        #check for second row in pair
                        secondrowpair<-b$UserId==bminusone$UserId && b$Source==bplusone$Source && b$EntryDateYMD==bminusone$EntryDateYMD
                        
                        #check for solo row
                        solo<-b$EntryDateYMD != bplusone$EntryDateYMD && b$EntryDateYMD != bminusone$EntryDateYMD
                }
        }
        
        if (firstrowpair == 1) {
                
                #check whether first or second row has NA sleep data; complete the relevant row and write it to dataframe
                if (is.na(bplusone$Sleep)) {
                        bplusone$Sleep<-b$Sleep
                        clean_activity_data_has_source<-rbind(clean_activity_data_has_source,bplusone)
                }
                
                else
                {
                        b$Sleep<-bplusone$Sleep
                        clean_activity_data_has_source<-rbind(clean_activity_data_has_source,b)
                }
        }
        
        if (solo == 1) {
                
                #write solo row to dataframe
                clean_activity_data_has_source<-rbind(clean_activity_data_has_source,b)
        }
}

#combine with the data fron other devices
activity<-rbind(clean_activity_data_has_source,activity_data_null_source)

#remove dataframes that are no longer needed
rm(activity_data,activity_data_has_source,activity_data_null_source,activity_data_keep,b,bminusone,bplusone, clean_activity_data_has_source)


## SYMPTOM DATA - COMBINE BINARY AND VALUED SYMPTOMS INTO OWN DATASET BY USER DATE AND SYMPTOM ##

motif_segmentvalue<-read.csv("motif_segmentvalue.csv", stringsAsFactors = FALSE)
motif_segment<-read.csv("motif_segment.csv", stringsAsFactors = FALSE)

motif_segmentvalue<-data.table(motif_segmentvalue)
motif_segment<-data.table(motif_segment)
setkey(motif_segment,Id)
setkey(motif_segmentvalue,SegmentId)

merged <- motif_segmentvalue[motif_segment, nomatch=0]
#syntax from here https://rstudio-pubs-static.s3.amazonaws.com/52230_5ae0d25125b544caab32f75f0360e775.html

#remove unwanted users
unwanted_users<-(merged$UserId %in% users_to_ignore)
merged<-merged[!unwanted_users,]

#Convert all dates to day only; NOTE that this loses time of day information
merged$EntryDateYMD<-as.Date(strtrim(merged$EntryDate,10))

#create a smaller dataset of user, symptom, value and date created
symptom_data<-merged[,c(5,12,22,3)]

#finish housekeeping
rm(motif_segment)
rm(motif_segmentvalue)
rm(merged)

#identify type of symptom
symptom_data$binary_symptom<-symptom_data$SegmentCategoryId %in% c(610,629,630,628)
symptom_data$antiinf_symptom<-symptom_data$SegmentCategoryId ==613
symptom_data$adherence_symptom<-symptom_data$SegmentCategoryId ==615
symptom_data$valued_symptom<-as.numeric(symptom_data$binary_symptom)+as.numeric(symptom_data$antiinf_symptom)+as.numeric(symptom_data$adherence_symptom)==0

#put valued symptoms into own dataframe 
#first, a dataframe with multiple rows per user-date-symptom
symptom_data_allvaluedrows<-symptom_data[valued_symptom==TRUE,c(1,2,3,4)] 
#then reduce to single rows per user-date-symptom by taking the mean
user_date_valuedsymptom_mean <- as.data.frame(symptom_data_allvaluedrows[, mean(Value, na.rm = TRUE), by = list(UserId,EntryDateYMD,SegmentCategoryId)])
rm(symptom_data_allvaluedrows)

#put binary symptoms into own dataframe 
#first, a dataframe with multiple rows per user-date-symptom
symptom_data_allbinaryrows<-symptom_data[binary_symptom==TRUE,c(1,2,3,4)]
#create a binary variable from the Value data
symptom_data_allbinaryrows$symptom_today<-symptom_data_allbinaryrows$Value %in% c(1,2,3)
#then reduce to single rows per user-date-symptom, summing binary variables ( may get >1 if mult syptoms entered on one date)
user_date_binarysymptom <- as.data.frame(symptom_data_allbinaryrows[, sum(symptom_today), by = list(UserId,EntryDateYMD,SegmentCategoryId)])
#so convert to binary to allow for values >1
user_date_binarysymptom$symptom_today<-as.numeric(user_date_binarysymptom$V1>0)
user_date_binarysymptom$V1<-NULL
rm(symptom_data_allbinaryrows)

#combine the binary and valued symptom datasets together again - NOTE symptom_today variable combined mean and binary
colnames(user_date_valuedsymptom_mean)<-colnames(user_date_binarysymptom)
user_date_binaryandvaluedsymptoms<-rbind(user_date_binarysymptom,user_date_valuedsymptom_mean)
rm(user_date_valuedsymptom_mean,user_date_binarysymptom)

## Other possibly useful code for symptom data
#use data table function to create table of symptom value labels - maybe useful for reference; not used in code
#symptom_labels <- as.data.frame(motif_segment[, mean(MotifId, na.rm = TRUE), by = list(SegmentCategoryId,Name,Text1,Text2,Text3,Text4,Text5)])

#creating a mean score for each symptom for each user - not sure this is needed
#user_mean_all_dates<-aggregate(symptom_today ~ UserId + SegmentCategoryId, data = user_date_binaryandvaluedsymptoms,mean)

###   FLARE DATA   ####

#looking specifically at flare data
flare_data<-user_date_binaryandvaluedsymptoms[user_date_binaryandvaluedsymptoms$SegmentCategoryId==610,]
#find mean flare score - represents proportion of days of user's flare data records when a flare actually occurred
flaresonly_user_proportionofdays<-aggregate(symptom_today ~ UserId + SegmentCategoryId, data = flare_data,mean)

## calculuate flare duration

#set order
flare_data_ordered<-setorder(data.table(flare_data),UserId, EntryDateYMD)

lastuser<-0
lastflarestartdate<-ymd("2018-01-01")

output <- data.frame()

for (i in (1:nrow(flare_data_ordered))) {
        input<-flare_data_ordered[i]
        if(input$symptom_today == 1) {
                if (input$UserId == lastuser) {
                        if (input$EntryDateYMD != (ymd(lastflarestartdate) + 1)) {
                                output<-rbind(output,c(input$UserId, ymd(input$EntryDateYMD), 1))
                                lastflarestartdate <- input$EntryDateYMD
                        }
                        else {
                                output$X1[nrow(output)]<-output$X1[nrow(output)]+1
                        }
                        
                }
                else
                        output<-rbind(output,c(input$UserId,input$EntryDateYMD,1))
                lastuser<-input$UserId
                lastflarestartdate <- input$EntryDateYMD
        }
}

colnames(output)<-c("UserID","EntryDateYMD","Duration")
output$EntryDateYMD<-as_date(output$EntryDateYMD)
flaresonly_user_date_duration<-output
rm(flare_data_ordered,flare_data,input,output)

###  WRITE OUTPUT FILES  ###

write.csv(registered_users,"output_registered_users.csv", row.names = FALSE)
write.csv(activity,"output_activity.csv", row.names = FALSE)
write.csv(symptom_data,"output_symptom_data.csv", row.names = FALSE)
write.csv(user_date_binaryandvaluedsymptoms,"output_user_date_binaryandvaluedsymptoms.csv", row.names = FALSE)
write.csv(flaresonly_user_date_duration,"output_flaresonly_user_date_duration.csv", row.names = FALSE)


```