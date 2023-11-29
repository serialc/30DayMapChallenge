import os

slash = os.sep

print("Running script")

wd = "/home/cyrille/TwoTerra/Projects/Vanbridges/spdata/VanDSM/"
pluginHost.setWorkingDirectory(wd)

def LAS2DEM(filenames):
	# 18 arguments needed for tool
	suffix = "_IDW"
	interpParameter = "z (elevation)"
	ptReturn = "first return"
	exponent = "2.0"
	maxSearchDist = "8.0"
	pointsToUse = "4"
	gridRes = "1.0"
	maxScanAngleDeviation = "5.0"
	# excluded points...
	neverClassified = "false"
	unclassified = "false"
	bareGround = "false"
	lowVeg = "false"
	mediumVeg = "false"
	highVeg = "false"
	buildings = "false"
	lowPoints = "false"
	keyPoints = "false"
	water = "false"
	args = [filenames, suffix, interpParameter, ptReturn, exponent, maxSearchDist,
	pointsToUse, gridRes, maxScanAngleDeviation, neverClassified, unclassified,
	bareGround, lowVeg, mediumVeg, highVeg, buildings, lowPoints, keyPoints, water]
	
	print("Processing...")
	try:
		pluginHost.runPlugin("LiDAR_IDW_Interpolation", args, False, False)
	except Exception, e:
	    print e
	    pluginHost.showFeedback("Error during script execution.")
	return

# START MODIFCATIONS HERE
# GET A LIST OF 'CODES' HERE - MANUALLY OR READ FILENAMES IN FOLDER

# we can add semicolon separated files
codes = ["4920E_54590N", "4910E_54590N", "4890E_54590N", "4900E_54590N", "4920E_54570N", "4920E_54580N"]

lidarfp = [wd + "COV_" + fn + slash + "CoV_" + fn + ".las" for fn in codes]

# make DEMs from lidar data
#LAS2DEM(";".join(lidarfp))

demfp = [wd + "COV_" + fn + slash + "CoV_" + fn + "IDW.dep" for fn in codes]

# Display all the DEM
for thisdem in demfp:
	pluginHost.returnData(thisdem)

# save in raster format for export
pluginHost.runPlugin("ExportArcAsciiGrid", [";".join(demfp)], False)
	