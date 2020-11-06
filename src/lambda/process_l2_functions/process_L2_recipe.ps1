param (
[string]$L2_GSF_Location = 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/transit/FK200930/EM320_L2/',
[string]$UUID = '125d8c3b-1e07-4652-a01a-cb3d3aef880a',
[string]$Product_Name = 'Great_Barrier_Reef_Cape_York_2020',
[string]$Vessel_File = 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/Vessel Files/RV_Falkor_EM302.hvf',
[string]$Target_Location = 's3://ausseabed-public-warehouse-bathymetry/L2/',
[string]$License_Server = '172.31.23.28',
[string]$Depth_Ranges_File = 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/depth_ranges.txt',
[string]$Cube_Config_File = 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/CUBEParams_AusSeabed_2019.xml',
[string]$Completion_Token = 'xxyy' ,
[string]$S3_Account_Canonical_Id = '4442572c4082cf5ca3abf21157b0db95bab63d0b312e6cf82f3d58a95405762e',
[string]$MSL_Reference = 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/s45e135inv.asc',
[string]$Resolution = '64m',
[string]$Working_Directory_Root = 'D:\'
)

echo "$L2_GSF_Location"
echo "$UUID"
echo "$Product_Name"
echo "$Vessel_File"
echo "$Target_Location"
echo "$License_Server"
echo "$Depth_Ranges_File"
echo "$Cube_Config_File"
echo "$Completion_Token"
echo "$S3_Account_Canonical_Id"
echo "$MSL_Reference"
echo "$Resolution"
echo "$Working_Directory_Root"

[Environment]::GetEnvironmentVariable("PATH","Machine")

# Download local files
$Working_Directory = "D:\$UUID\"
$Process_Log = "$Working_Directory$Product_Name\process_log.txt"
$Error_Log = "$Working_Directory$Product_Name\error_log.txt"
$Log_Config_Path = "$Working_Directory$Product_Name\amazon-cloudwatch-agent-schema.json"
aws s3 sync $L2_GSF_Location $Working_Directory 

# Get local names for s3 files
$Vessel_File_Array = $Vessel_File.Split('/')
$index = $Vessel_File_Array.count - 1
$Vessel_File_Local = $Vessel_File_Array.GetValue($index)

$Depth_Ranges_File_Array = $Depth_Ranges_File.Split('/')
$index = $Depth_Ranges_File_Array.count - 1
$Depth_Ranges_File_Local = $Depth_Ranges_File_Array.GetValue($index)

$Cube_Config_File_Array = $Cube_Config_File.Split('/')
$index = $Cube_Config_File_Array.count - 1
$Cube_Config_File_Local = $Cube_Config_File_Array.GetValue($index)

$MSL_Reference_Array = $MSL_Reference.Split('/')
$index = $MSL_Reference_Array.count - 1
$MSL_Reference_Local = $MSL_Reference_Array.GetValue($index)

# Download reference files
aws s3 cp $Vessel_File $Working_Directory$Vessel_File_Local 
aws s3 cp $Depth_Ranges_File $Working_Directory$Depth_Ranges_File_Local 
aws s3 cp $Cube_Config_File $Working_Directory$Cube_Config_File_Local 
aws s3 cp $MSL_Reference $Working_Directory$MSL_Reference_Local 

# Start processing
Set-Location -Path $Working_Directory

# Specify license to use
carisbatch --set-option General/General/LicenseHost $License_Server 

# L2 GSF in ellipsoid
$Hips_File = "file:///$Working_Directory$Product_Name\$Product_Name.hips"
$Ext_Ellipsoid = "Ellipsoid"
$Ext_Auto_Ellipsoid = "Auto_Ellipsoid"
$Ext_Auto_MSL = "Auto_MSL"
$Ellipsoid_Csar_File = "file:///$Working_Directory$Product_Name\$Product_Name$Ext_Ellipsoid.csar"
$Auto_Ellipsoid_Csar_File = "file:///$Working_Directory$Product_Name\$Product_Name$Ext_Auto_Ellipsoid.csar"
$Auto_Msl_Csar_File = "file:///$Working_Directory$Product_Name\$Product_Name$Ext_Auto_MSL.csar"
$Target_TIF_Local = "file:///$Working_Directory$Product_Name\$Product_Name.tif"
$Target_BAG_Local = "file:///$Working_Directory$Product_Name\$Product_Name.bag"
$Target_Location_Folder = "$Target_Location$UUID/"

carisbatch.exe --run CreateHIPSFile $Hips_File 
carisbatch.exe --run ImportToHIPS --input-format GSF --depth-source TRUE --vessel-file "file:///$Working_Directory$Vessel_File_Local" "$Working_Directory\*.gsf" $Hips_File 

# L2 GSF not in ellipsoid but contains ellipsoid data
# carisbatch.exe --run ImportToHIPS --input-format GSF --depth-source TRUE --vessel-file "file:///..\GA-1234\VesselConfig\RV_Falkor_EM710.hvf" "..\GA-1234\L2\*.gsf" "file:///..\GA-1234\GA-1234.hips?Vessel=RV_Falkor_EM710" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"
# carisbatch.exe --run GeoreferenceHIPSBathymetry --vertical-datum-reference GPS --compute-gps-vertical-adjustment --sounding-datum-offset 0m --heave-source HEAVE --compute-tpu --tide-measured 0.0m --tide-zoning 0.1m --sv-measured 1.0m/s --sv-surface 0.2m/s --source-navigation VESSEL --source-sonar VESSEL --source-gyro VESSEL --source-pitch VESSEL --source-roll VESSEL --source-heave VESSEL --source-tide STATIC --output-components "file:///..\GA-1234\GA-1234.hips" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"
# carisbatch.exe --run ExportHIPS --output-format GSF --include-time-series "file:///..\GA-1234\GA-1234.hips" "..\GA-1234\Products\L2\" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"

# LS GSF not in ellipsoid and requires ellipsoid from auxiliary data
# carisbatch.exe --run ImportToHIPS --input-format GSF --depth-source TRUE --vessel-file "file:///..\GA-1234\VesselConfig\RV_Falkor_EM710.hvf" "..\GA-1234\L2\*.gsf" "file:///..\GA-1234\GA-1234.hips" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"
# carisbatch.exe --run ImportHIPSFromAuxiliary --input-format APP_POSMV --allow-partial --maximum-gap 1000sec --gps-height 0sec --gps-height-rms 0sec "..\GA-1234\Aux\*.*" "file:///..\GA-1234\GA-1234.hips" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"
# carisbatch.exe --run GeoreferenceHIPSBathymetry --vertical-datum-reference GPS --compute-gps-vertical-adjustment --sounding-datum-offset 0m --heave-source HEAVE --compute-tpu --tide-measured 0.0m --tide-zoning 0.1m --sv-measured 1.0m/s --sv-surface 0.2m/s --source-navigation VESSEL --source-sonar VESSEL --source-gyro VESSEL --source-pitch VESSEL --source-roll VESSEL --source-heave VESSEL --source-tide STATIC --output-components "file:///..\GA-1234\GA-1234.hips" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"
# carisbatch.exe --run ExportHIPS --output-format GSF --include-time-series "file:///..\GA-1234\GA-1234.hips" "..\GA-1234\Products\L2\" >> "..\GA-1234\process_log.txt" 2>> "..\GA-1234\error_log.txt"

# Common to 1, 2 & 3
carisbatch.exe --run CreateVRSurface --estimation-method RANGE --range-file "file:///$Working_Directory$Depth_Ranges_File_Local" --range-method PERCENTILE --range-percentile 50 --input-band DEPTH --max-grid-size 64 --min-grid-size 4 --include-flag ACCEPTED $Hips_File $Ellipsoid_Csar_File  
carisbatch.exe --run PopulateVRSurface --population-method CUBE --input-band Depth --include-flag ACCEPTED --iho-order S44_2 --vertical-uncertainty "Depth TPU" --horizontal-uncertainty "Position TPU" --display-bias HIGHEST --disambiguation-method DENSITY_LOCALE --cube-config-file="file:///$Working_Directory$Cube_Config_File_Local" --cube-config-name="AusSeabed_VR"  $Hips_File $Ellipsoid_Csar_File 

carisbatch.exe --run CreateHIPSGridWithCube --output-crs EPSG:4326 --keep-up-to-date --cube-config-file "file:///$Working_Directory$Cube_Config_File_Local" --cube-config-name="AusSeabed_VR" --iho-order S44_2 $Hips_File $Auto_Ellipsoid_Csar_File --resolution $Resolution 

carisbatch.exe --run ExportRaster --output-format GEOTIFF --include-band Depth $Auto_Ellipsoid_Csar_File $Target_TIF_Local 
carisbatch.exe --run ExportRaster --output-format BAG --include-band Depth --uncertainty Uncertainty --uncertainty-type PRODUCT_UNCERT --abstract undefined --status UNDER_DEV --vertical-datum 'Mean Sea Level' --party-name undefined --party-position undefined --party-organization undefined --party-role POINT_OF_CONTACT --legal-constraints OTHER_RESTRICTIONS --other-constraints NA --security-constraints UNCLASSIFIED --notes NA --compression-level 1 "$Auto_Ellipsoid_Csar_File" "$Target_BAG_Local"  

# Untested
carisbatch.exe --run ShiftElevationBands --input-band Depth --shift-type Raster --include-band Depth --shift-file "file:///$Working_Directory$MSL_Reference_Local" --elevation-band="Band 1" $Auto_Ellipsoid_Csar_File $Auto_MSL_CSAR_FIL  

aws s3 cp $Working_Directory$Product_Name\ $Target_Location_Folder --recursive --include "*" --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers full=id="$S3_Account_Canonical_Id" 

$payload = ConvertTo-Json -Compress -InputObject @{
    result = 'Complete'
}
aws stepfunctions send-task-success --region "ap-southeast-2" --task-token $Completion_Token --task-output '{\"result\":\"success\"}'
