function uniform_slide(laser_power_in_mW,laser_wavelength)
    % Image uniform slide
    %
    % function record.uniform_slide(laser_power_in_mW,laser_wavelength)
    %
    % User must supply power and wavelengths as integers.
    % This is for logging purposes.
    %
    % e.g.
    % >> record.uniform_slide(10,920)
    %
    % Rob Campbell, SWC 2022

    if nargin<2 || ( ~isnumeric(laser_power_in_mW) || ~isnumeric(laser_wavelength) )
        fprintf('Supply power and wavelength as input args. See function help\n')
        return
    end

    laser_power_in_mW = round(laser_power_in_mW);
    laser_wavelength = round(laser_wavelength);

    % Connect to ScanImage using the linker class
    API = sibridge.silinker;
    if ~strcmp(API.scannerType,'resonant')
        fprintf('%s only safe with resonant scanner. Quitting. \n',mfilename)
        return
    end

    if length(API.hSI.hChannels.channelSave) > 1
        fprintf('Select just one channel to save\n')
        return
    end

    % Create 'diagnostic' directory in the user's desktop
    saveDir = mpsf.tools.makeDesktopDirectory('diagnostic');
    if isempty(saveDir)
        return
    end

    %Record the state of all ScanImage settings we will change so we can change them back
    settings = mpsf.tools.recordScanImageSettings(API);


    %Apply common setting
    if API.versionGreaterThan('2020') 
        API.hSI.hStackManager.numSlices=1;
        API.hSI.hStackManager.numVolumes = 1;
    else
        API.hSI.hStackManager.numSlices=1;
        API.hSI.hFastZ.numVolumes=1;
    end

    API.hSI.hStackManager.framesPerSlice=20; % We will record multiple frames
    API.hSI.hRoiManager.pixelsPerLine=256;

    API.hSI.hScan2D.logAverageFactor = 1;
    API.hSI.hDisplay.volumeDisplayStyle='Current';


    API.hSI.hRoiManager.scanZoomFactor = 1; % Set zoom

    API.hSI.hChannels.loggingEnable=true;

    fileStem = sprintf('uniform_slice_zoom__%s_%dnm_%dmW__%s', ...
            strrep(num2str(API.hSI.hRoiManager.scanZoomFactor),'.','-'), ...
            laser_wavelength, ...
            laser_power_in_mW, ...
            datestr(now,'yyyy-mm-dd_HH-MM-SS'));
    API.hSI.hScan2D.logFileStem=fileStem;
    API.hSI.hScan2D.logFilePath=saveDir;
    API.hSI.hScan2D.logFileCounter=1;

    API.acquireAndWait;


    mpsf.tools.reapplyScanImageSettings(API,settings);

    % Report where the file was saved
    mpsf.tools.reportFileSaveLocation(saveDir,fileStem)
