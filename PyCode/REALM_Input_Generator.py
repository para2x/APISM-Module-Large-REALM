# Name: REALM_Input_Generator.py
# Description: This code Masks the gSSURGO and takes the soils selected by biochar suitiblibty analysis then it converts
# them into polygon and then dissolvs it
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


# ----------------- Function for just reading the masked raster and producing the dissolved polygon
def rastopolydis(raster,name,address):
    env.workspace = address
    os.chdir(address)
    try:
        #-- Creating a directory for the output if it doesn't exist
        if not os.path.exists(name+"_REALMPoly"):
            os.makedirs(name+"_REALMPoly")
        #--  Doing the conversion and disolve
        memoryFeature = "in_memory/Poly"
        arcpy.RasterToPolygon_conversion(raster, memoryFeature, "SIMPLIFY", "VALUE")
        print "Dissolving ...... " + name+"\n"
        arcpy.Dissolve_management(memoryFeature, name+"_REALMPoly/"+name + "_dissolved.shp", "GRIDCODE")
    except Exception as e:
        print "Error processing", raster
        print "Error", e
#-------------------- Function that masked the raster gssurgo based on raster suitibility analysis
def mask_gssurgo_biochar(inraster,inMaskData,address):
    env.workspace = address
    name = inraster[0:2].upper()
    print "Masking ...... "+name+"\n"
    # ----------------
    # Execute ExtractByMask
    outExtractByMask = ExtractByMask(inraster, inMaskData)
    compressedRaster = arcpy.sa.ApplyEnvironment(outExtractByMask)  # making sure we have applied the compression settings
    #compressedRaster.save(name+"_masked.tif")  # and finally save
    #----------------
    # Polygon and dissolve
    rastopolydis(compressedRaster,name,address)
#------------------------------------------------------------- MAIN FUNCTION
if __name__ == '__main__':
    print len(sys.argv)
    #print sys.argv
    #print "This is the name of the script: ", sys.argv[0]
    #--- Reading arguments frm consol
    if len(sys.argv)==1:
        address = r'C:\Users\Para2x\Dropbox\Hamze Dokoohaki\Projects\Large-scale APSIM Simulation\REAL-Biochar\Data\IA'
        inras="IA.tif"
        inMask=r"E:\Bayesian Network\OutputRasters\CF\CF15\IA_CFB15_pRR_A750.tif"
    if len(sys.argv) == 4:
        address = sys.argv[1]
        inras=sys.argv[2]
        inMask=sys.argv[3]
        #-- setting the GIS setting for analysis - compression and pyramid
        env.workspace=address
        #--- Running the first function
        mask_gssurgo_biochar(inras,inMask,address)