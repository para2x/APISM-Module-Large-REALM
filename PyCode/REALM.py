# Name: REALM_Core.py
# Description: This code creates simulation units from dissolved polygons of the region
# Requirements: Spatial Analyst Extension
# Author: Hamze Dokoohaki - Nov 2017
# ---------------------------------------------------------------------------------------
from multiprocessing import Pool, TimeoutError
import arcpy
from arcpy import env
from arcpy.sa import *
import os
import sys
arcpy.CheckOutExtension("Spatial")
#

def REALM_Core(dirR,raduis):
    address=dirR
    arcpy.env.overwriteOutput = True
    arcpy.env.parallelProcessingFactor="100%"
    arcpy.env.workspace=os.path.join(address)
    os.chdir(arcpy.env.workspace)
    ################################
    fc = arcpy.ListFeatureClasses("*_Dissolved*")[0]
    arcpy.MakeFeatureLayer_management(fc,"dissolved_Layer")
    name=fc[0:2].upper()
    OIDField = arcpy.Describe(fc).OIDFieldName # get OID/FID field name
    auxfold="REALMOutput"
    ###
    if not os.path.exists(auxfold):
        os.mkdir(auxfold)
    pocursor = arcpy.SearchCursor ("dissolved_Layer")
    try:
        for porow in pocursor:
            print name+"->"+"FID"+str (porow.getValue(OIDField))
            ##################### Subsetting
            sql = '"' + OIDField + '" = ' + str (porow.getValue(OIDField)) #SQL to select one feature
            arcpy.SelectLayerByAttribute_management ("dissolved_Layer", "", sql) #Select polygon feature by OID
            memoryFeature=auxfold+"\\"+name + "_FID_" + str (porow.getValue(OIDField))+".shp"
            arcpy.CopyFeatures_management("dissolved_Layer", memoryFeature)
            arcpy.SelectLayerByAttribute_management ("dissolved_Layer", "CLEAR_SELECTION")
            arcpy.MakeFeatureLayer_management(memoryFeature,"selected_Poly")
            ############## Tessleation
            description = arcpy.Describe(memoryFeature)
            extent = description.extent
            memoryFeature_Tes=auxfold+"\\"+name + "_Tessel_" + str (porow.getValue(OIDField))+".shp"
            arcpy.GenerateTessellation_management(memoryFeature_Tes, extent, "HEXAGON", raduis+" SquareMiles")
            ############### Clip
            memoryFeature_Tes_clip = auxfold + "\\" + "Tessel_cliped_"+ str (porow.getValue(OIDField))+".shp"
            arcpy.Clip_analysis(memoryFeature_Tes, memoryFeature, memoryFeature_Tes_clip)
            ############### Spatial Join
            Tes_spatialJoin=auxfold+"\\"+name + "_Tessel_Joined_" + str (porow.getValue(OIDField))+".shp"
            arcpy.SpatialJoin_analysis(memoryFeature_Tes_clip, "selected_Poly", Tes_spatialJoin)
            del porow
            arcpy.Delete_management(memoryFeature)
            arcpy.Delete_management(memoryFeature_Tes)
            arcpy.Delete_management(memoryFeature_Tes_clip)
        del pocursor
        #--- Now it's time to put togther small piceses
        arcpy.env.workspace=os.path.join(address,auxfold)
        arcpy.Merge_management(arcpy.ListFeatureClasses("*"),name+"_merged.shp")
        #--- deleting small pieces
        for objFeatureClass in arcpy.ListFeatureClasses("*_Tessel_Joined*"):
            arcpy.Delete_management(objFeatureClass)
        #-- Calculate centroid
        arcpy.AddField_management(name+"_merged.shp", "xCentroid", "DOUBLE", 18, 11)
        arcpy.AddField_management(name+"_merged.shp", "yCentroid", "DOUBLE", 18, 11)
        arcpy.CalculateField_management(name+"_merged.shp", "xCentroid", "!SHAPE.CENTROID.X!", "PYTHON_9.3")
        arcpy.CalculateField_management(name+"_merged.shp", "yCentroid", "!SHAPE.CENTROID.Y!", "PYTHON_9.3")
        print "Done ......"
    except Exception as e:
        print "Error processing", fc
        print "Error", e
#############################################
if __name__ == '__main__':
    #print len(sys.argv)
    print sys.argv
    #print "This is the name of the script: ", sys.argv[0]
    #--- Reading arguments frm consol
    if len(sys.argv) == 3:
        address = sys.argv[1]
        raduis=sys.argv[2]
        #-- setting the GIS setting for analysis - compression and pyramid
        env.workspace=address
        #--- Running the first function
        REALM_Core(address,raduis)
