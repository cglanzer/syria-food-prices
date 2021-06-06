#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ########################################################################
# Script "clean_data.py"
# Cleans the data and prepares it for model evaluation.
# ########################################################################

import pandas as pd
import numpy as np
import os

# Before running please read the information below!

''' ########################################################################
Input files

modified_original_xslx_file:
This is the original .xslx file given to us by IMPACT, where the first row
in the sheet "Subdistrict_Time Series" is deleted manually.

imputation_team_supercoarse_file:
This is a file given to us by the imputation team.
It contains data from all subdistricts and all months and all separate item prices (flour, water etc.).
SMEB can be calculated from this file by simply summing up all column prices and multiplying the result by the float value.
If this file is unavailable, it is still possible to create testing data using this script. In this case,
only run the testing data part below (Part I) separately and manually.
'''

modified_original_xslx_file = "../../data/raw/reach_syr_dataset_market monitoring_redesign_august2019_without_first_row.xlsx"
imputation_team_supercoarse_file = "../../data/raw/impute_supercoarse.csv"
''' ######################################################################### '''


# Data extraction settings
SMEB_column = "Price_SMEB_total_wfloat" # Which value should we extract? (column name)
calculate_median = True # False: Use mean. We use median per default.
debug_output = True # Prints debug output for the extracted files.
months_to_be_dropped = ["2016-11", "2016-12", "2017-01"] # We ignore / remove the first three months from our testing and training set as this data is typically missing!
testing_subdistricts = ["SY020001", "SY020400", "SY020600", "SY070002", "SY070005", "SY070301", "SY070402", "SY070403"] # We select those subdistricts as testing data. These are exactly those subdistricts where we have all but at most one value from all months (ignoring the first three months). The missing value, if existant, is interpolated linearly.

'''
Function get_all_unique_items
Input:
    df: (list): List of dataframes where we extract unique values from.
    column_name: (string): String of the name of the column for which you want to extracat all unique values.
    checker: (string) Every entry of the column where we extract unique elements from is assumed to contain this string.
                      E.g. every subdistrict has 'SY' in it. This ensure that there are no errors during the extraction.
Output:
    items (set): Set of unique items extracted from column 'column_name*.
'''
def get_all_unique_items(df, column_name = "q_sbd" , checker = "SY"):
    items = set()       
    try:
        for i, data_frame in enumerate(df):
            try:
                temp = data_frame[column_name].unique()
                usual_item = True
                for unit in temp:
                    if checker not in unit:
                        usual_item = False
                        break
                if(usual_item):
                    items |=set(temp)
                else:
                    print("Skipping for {}th dataframe , becuause of unusual elemnets".format(i))
            except :
                print("Couldn't query {} column for {}th month".format(column_name, i))
        return items        
    except:
        print("Something went wrong with the input dataframe!")

''' STEP I - Create testing data out of the original .xslx file given to us by IMPACT.
We start extracting the sheet 'Subdistrict_Time Series' from modified_original_xslx_file.
This file is temporary and will be deleted by the script lateron. '''
sheets_input = ["Subdistrict_Time Series"] # This can be modified to extract more sheets: Just add new elements to this list and the filename_output list below.
filename_output = ["extracted_sheet_subdistrict.csv"]
if debug_output:
    print("Started data cleaning process...")
    print("Step I: Creating testing data from the original .xslx file.")
    print("Creating {}: Extracting the sheet {} from the original .xslx file (where the first row of the sheet Subdistrict_Time Series was removed) as CSV.".format(filename_output[0], sheets_input[0]))

i = 0
for sheet in sheets_input:
    if debug_output:
        print("Reading sheet {} of {}...".format(sheet, modified_original_xslx_file))
    df = pd.read_excel(modified_original_xslx_file, sheet_name=sheet)
    df.to_csv("../../data/processed/"+filename_output[i], index=False)
    i += 1

if debug_output:
    print("Done.")

''' Now that this sheet is created, we read it back in, read all the SMEB data for each month and district. '''
if debug_output:
    print("Started the extraction of SMEB values with interpolation to fix missing values. There could be empty mean warnings...")

# The following three lists can be modified to extract more sheets. Just add more values and modify the tempstr below.
col_names = ["q_sbd"]
output_file_names = ["subdistrict_smeb.csv"]
output_file_names_interpol = ["testing_data.csv"]

i = 0
for fname in filename_output:
    if debug_output:
        if i == 0:
            tempstr = "subdistrict"
        # Uncomment if you extracted more sheets previously, e.g., also district and governorate data.
        #if i == 1:
        #    tempstr = "district"
        #if i == 2:
        #    tempstr = "governorate"
        print("Extracting {} data...".format(tempstr))
    
    df = pd.read_csv("../../data/processed/"+fname)

    month_list = get_all_unique_items([df], column_name="month2", checker="20")
    month_list = sorted(month_list)

    # In what follows, we use 'subdistrict' here although
    # it could be governorate / district / subdistrict depending on i / tempstr.
    subdistrict_list = get_all_unique_items([df], column_name=col_names[i], checker="SY")
    subdistrict_list = sorted(subdistrict_list)
    
    # In what follows, we create an empty dataset subdistrict_data, which will later contain our data.
    # We start by setting everything to nan and creating row indices which correspond to the months
    # and column names corresponding to the subdistrict indices.
    subdistrict_data = pd.DataFrame()
    subdistrict_data["month"] = month_list
    for subdist in subdistrict_list:
        subdistrict_data[subdist] = np.nan
    subdistrict_data = subdistrict_data.set_index("month")
    
    # Now, we fill this dataset with data. We run through months & subdistricts
    # and calculate the median values we have for each month & subdistrict combination.
    # (in case we have multiple values). Then, we fill it into our data frame.
    for subdist in subdistrict_list:
        for month in month_list:
            # Get available data for this month & subdistrict
            dat = df[(df["month2"] == month) & (df[col_names[i]] == subdist)]
            
            # Calc median / mean
            if calculate_median:
                subdistrict_data.loc[month,subdist] = dat[SMEB_column].median()
            else:
                subdistrict_data.loc[month,subdist] = dat[SMEB_column].mean()
    
    # Fill NaN - values by linear interpolation for the testing data.
    subdistrict_interpolated_data = subdistrict_data.copy().interpolate()
    
    if debug_output:
        for subdist in subdistrict_list:
            cnt = 0;
            for month in month_list:
                val_orig = subdistrict_data.loc[month,subdist]
                val_interpol = subdistrict_interpolated_data.loc[month,subdist]
                if not np.isnan(val_interpol) and np.isnan(val_orig):
                    cnt += 1
            print("{}: Interpolated {} values out of {}".format(subdist, cnt, subdistrict_interpolated_data[subdist].count()))
            
    
    # We remove the first three months as this data is typically missing!
    subdistrict_data = subdistrict_data.drop(months_to_be_dropped)
    subdistrict_interpolated_data = subdistrict_interpolated_data.drop(months_to_be_dropped)
        
    # Select only the districts which are of interest for us in terms of testing (the ones which have at most one value missing) to be part of the testing dataset
    subdistrict_testing_data = subdistrict_interpolated_data.loc[:,testing_subdistricts]
    
    # Export data
    subdistrict_data.to_csv("../../data/processed/"+output_file_names[i])
    subdistrict_testing_data.to_csv("../../data/processed/"+output_file_names_interpol[i])
    
    if debug_output:
        print("Stored as {} and {}".format("../../data/processed/"+output_file_names[i], "../../data/processed/"+output_file_names_interpol[i]))
        
    i += 1
    
# Remove temporary files
for fname in filename_output:
    os.remove("../../data/processed/"+fname)

if debug_output:
    print("Done with Step I.")

# If the imputated file from the imputation team is unavailable, comment everything out from this point.

''' STEP 2: Generate training data from the file we obtained from the imputation team.
Their file contains columns of the prices of items multiplied by the correct factor. It's just necessary to add up all columns and multiply
the result by the float value. '''
print("Step II: Loading processed data of the imputation team.")
df = pd.read_csv(imputation_team_supercoarse_file)
print("Processing data and calculating SMEB values.")

month_list = get_all_unique_items([df], column_name="month2", checker="20")
month_list = sorted(month_list)
subdistrict_list = get_all_unique_items([df], column_name="q_sbd", checker="SY")
subdistrict_list = sorted(subdistrict_list)

# In what follows, we create an empty dataset subdistrict_data, which will later contain our data.
# We start by setting everything to nan and creating row indices which correspond to the months
# and column names corresponding to the subdistrict indices.
imputation_data = pd.DataFrame()
imputation_data["month"] = month_list
for subdist in subdistrict_list:
    imputation_data[subdist] = np.nan
imputation_data = imputation_data.set_index("month")

# Now, we fill this dataset with the data we have.
for subdist in subdistrict_list:
    for month in month_list:
        # Get available data for this month & subdistrict
        dat = df[(df["month2"] == month) & (df["q_sbd"] == subdist)]
        prices = dat.drop(["month2","q_sbd"], axis=1)
        
        # Calc SMEB
        imputation_data.loc[month,subdist] = float(prices.sum(axis=1)*1.075)

# We remove the first three months as those data is typically missing!
imputation_data = imputation_data.drop(months_to_be_dropped)

# Export data
imputation_data.to_csv("../../data/processed/imputed_training_data.csv")

print("Done with Step II.")
print("Data extraction complete.")
