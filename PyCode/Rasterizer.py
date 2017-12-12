# Name: Rasterizer.py
# Description: This file read the output variable produced by APSIM and the polygons produced by REALM and joins them and then
#rasterizes them.
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

def rasterizer(address,outfield,name):
    os.chdir(address)
    if not os.path.exists("RasterOutput"):
        os.makedirs("RasterOutput")
    # raster
    featureclasses = arcpy.ListFeatureClasses()[0]
    # Create a feature layer from the featureclass
    arcpy.MakeFeatureLayer_management(featureclasses, "Layer")
    #--- join the dbf
    arcpy.AddJoin_management ("Layer", "FID", "tmpout.dbf", "id")
    #-- polygon to raster
    arcpy.PolygonToRaster_conversion('Layer', "tmpout."+outfield,"RasterOutput/"+name+".img","MAXIMUM_AREA",cellsize=30)
    print "Done ..."

if __name__ == '__main__':
    #- see if we have the right arguments

    if len(sys.argv) == 4:
        address = sys.argv[1]
        outfield = sys.argv[2]
        name = sys.argv[3]
        #-- setting the GIS setting for analysis - compression and pyramid
        env.workspace=address
        #- ratserizing
        rasterizer(address,outfield,name)