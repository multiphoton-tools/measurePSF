function params = parseInputVariable(varargin)

    % Parse laser power and wavelength from record functions
    %
    % function [laser_power_in_mW, laser_wavelength] = parsePowerAndWavelength(varargin)
    %
    % Purpose
    % Recording functions need the power and wavelength supplied by the user. The user
    % may either do this as input args or, if they do not, as interactive inputs. This
    % function handles this. The can supply the arguments in any order.
    % See mpsf.record.uniform_slide and mpsf.record.lens_paper for examples
    %
    %
    % Rob Campbell


      % Make the inputParser object
    params = inputParser;
    params.CaseSensitive = false; % So we do not have to be case sensitive
    % add parameters
    params.addParameter('wavelength', [], @(x) isnumeric(x));
    params.addParameter('power', [], @(x) isnumeric(x));
    params.addParameter('depthMicrons', [], @(x) isnumeric(x));
    params.addParameter('stepSize', 0.25, @(x) isnumeric(x));

    % Parse the input arguments
    params.parse(varargin{:});

    % Extract the variables
    % wavelength=params.Results.wavelength
    % power=params.Results.power
    % depthMicrons=params.Results.depthMicrons
    % stepSize=params.Results.stepSize

    d=dbstack;
    d.file;


    if isempty(params.Results.depthMicrons) &&  strcmp(d(2).file,'PSF.m')
        %ASK QUESTION
        default=20;
        response = input(sprintf('Please enter depth to image (default = %d microns): ', default));
        if iesmpty(response)
            params.Results.depthMicrons = default;
        end
    end

   if isempty(params.Results.stepSize) &&  strcmp(d(2).file,'PSF.m')
        %ASK QUESTION
        default=0.25;
        response = input(sprintf('Please enter step size (default = %d microns): ', default));
        if iesmpty(response)
            params.Results.depthMicrons = default;
        end
    end

    if isempty(params.Results.wavelength)
        %ASK QUESTION
        % default=0.25;
        response = input(sprintf('Please enter wavelength (nm): '));
        % if iesmpty(response)
            % params.Results.depthMicrons = default;
        % end
    end

    if isempty(params.Results.power)
        %ASK QUESTION
        % default=0.25;
        response = input(sprintf('Please enter power (mW): '));
        % if iesmpty(response)
            % params.Results.depthMicrons = default;
        % end
    end

    % if doInteractive
    %     [laser_power_in_mW, laser_wavelength] = ineractive_nm_mW();
    % else
    %     laser_power_in_mW = power;
    %     laser_wavelength = wavelength;
    % 
    % end
    % 
    % 
    % laser_power_in_mW = round(laser_power_in_mW);
    % laser_wavelength = round(laser_wavelength);



    % Internal functions follow
    % function [laser_power_in_mW, laser_wavelength] = power_wavelength_from_args(varargin)
    %     IN = sort(cell2mat(varargin{1}));
    %     laser_power_in_mW = IN(1);
    %     laser_wavelength = IN(2);
    % 
    % 
    % function [laser_power_in_mW, laser_wavelength] = ineractive_nm_mW()
    % 
    %     laser_power_in_mW = [];
    %     while isempty(laser_power_in_mW)
    %         txt = input('Please enter laser power in mW: ','s');
    %         laser_power_in_mW = str2num(txt);
    %     end
    % 
    %     laser_wavelength = [];
    %     while isempty(laser_wavelength)
    %         txt = input('Please enter laser wavelength in nm: ','s');
    %         laser_wavelength = str2num(txt);
    %     end