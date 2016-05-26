function micsPix=Grid2MicsPerPixel(inputIM,varargin)
% Calculated the number of microns per pixel based on an imaged grid of known pitch
%
% function micsPix=Grid2MicsPerPixel(inputIM, 'param', 'val')
%
% Purpose
% Calculates the number of microns per pixel along rows and columns from 
% an imaged grid of known pitch. 
%
% 
% Inputs (required) 
% inputIM - 2D image of the grid
%
% Inputs (optional param/val pairs)
% gridPitch - pitch of the grid in microns (default is 20)
% cropProp -  proportion of image edges to trim before processing (default is 0.05)
% verbose - More output info shown (false by default)
% medFiltSize - The size of the filter to use for median filtering of the image (6 pixels by default)
% polynomDetrendOrder - The order of the polynomial used to detrend row and column averages (default: 3)
%
%
% Outputs
% Returns number of microns per pixel along the rows and columns
% NOTE: these values are currently based upon the rotated grid image. So if your image is scaled
% very differently across the rows and columns and the grid wasn't imaged in an orientation close 
% that of the scan axes then you will get inaccurate values. Of course it is straightforward to 
% calculate the true microns per pixel along the scan axes, but so far we haven't needed to so the 
% function does not do this. 
%
%
%
% PROTOCOL
% We use copper EM grids of known pitch. We use part number 2145C from www.2spi.com/category/grids
% These grids are listed as having:
% - a pitch of 25 microns
% - a hole width of 19 microns
% - a bar width of 6 microns
%
% However, using the stage coords to measure the grid, we find that:
% - hole width of about 16 microns
% - bar width of about 4.5 microns
% - so the pitch is 20 microns
%
% 
% We remove one grid and place it on microscope slide. For measurement with a 2-photon microscope
% we dab the grid with a regular office fluorescent marker pen, then seal it with a coverslip. To
% to find the grid without a camera, we place it under the objective. Set the power to about 10 mW 
% at the sample with wavelength of about 880 nm. With PMTs off we scan and look at the sample by eye. 
% When the grid is in focus, the emitted fluorescence is clearly visible by eye in a darkened room. 
% We then set the power to about 3 mW and switch on the PMTs. The grid should now be visible. The grid 
% should be oriented so that it's aligned relatively closely with the scan axes. This function will 
% attempt to rotate the grid so that it's perpendicular with the scan axes, but we suggest you get it
% correctly aligned to within about 10 degrees (see note above). Make sure the grid is in focus and 
% take and image. Feed this image to this function.
%
%
% Rob Campbell - Basel 2016


    if nargin<1
        help(mfilename)
    end

    params = inputParser;
    params.CaseSensitive = false;
    params.addParamValue('gridPitch', 20, @(x) isnumeric(x) && isscalar(x));
    params.addParamValue('cropProp', 0.05, @(x) isnumeric(x) && isscalar(x) && x>0 && x<1);
    params.addParamValue('verbose', false, @(x) islogical(x) || x==0 || x==1);
    params.addParamValue('medFiltSize', 6, @(x) isnumeric(x) && isscalar(x));
    params.addParamValue('polynomDetrendOrder', 3, @(x) isnumeric(x) && isscalar(x));

    params.parse(varargin{:});
    gridPitch = params.Results.gridPitch;
    verbose = params.Results.verbose;
    cropProp = params.Results.cropProp;
    polynomDetrendOrder = params.Results.polynomDetrendOrder;

    medFiltSize = params.Results.medFiltSize;
    medFiltSize = [medFiltSize,medFiltSize];


    %PREPARE THE IMAGE
    %Crop the image
    inputIM = double(inputIM);
    cropPix=floor(size(inputIM)*cropProp);
    inputIM = inputIM(cropPix:end-cropPix, cropPix:end-cropPix);

    %Filter the image to get rid of noise that can throw off the peak detection
    inputIM = medfilt2(inputIM,medFiltSize);



    %PLOT AND CALCULATE
    clf

    subplot(2,2,1)
    imagesc(inputIM)
    title('Original image')
    axis square



    rotAx = subplot(2,2,2);


    ang=findGridAngle(inputIM);

    imR = imrotate(inputIM,ang,'crop') ;
    imR(imR==0)=nan;
    imagesc( imR )
    title(sprintf('Corrected tilt by %0.2f degrees',ang))
    axis square


    muCols=nanmean(imR,1);
    muRows=nanmean(imR,2);

    subplot(2,2,3)
    h=peakFinder(muCols);
    fprintf('%0.3f mics/pix along columns\n', h.micsPix)
    micsPix.cols = h.micsPix;
    set(h.line,'color',[1,0.3,0.3], 'linewidth',1);
    set(h.peaks,'MarkerEdgeColor',[0.66,0,0])
    set(h.peaks,'MarkerFaceColor',[1,0.66,0.66])
    title(sprintf('columns: %0.3f \\mum/pixel',h.micsPix))
    addLinesToImage(h,2,'r')

    subplot(2,2,4)
    h=peakFinder(muRows);
    fprintf('%0.3f mics/pix along rows\n', h.micsPix)
    micsPix.rows = h.micsPix;
    set(h.line,'color',[1,1,1]*0.3, 'linewidth',1);
    set(h.peaks,'MarkerEdgeColor','k')
    set(h.peaks,'MarkerFaceColor',[1,1,1]*0.66)
    title(sprintf('rows: %0.3f \\mum/pixel',h.micsPix))
    addLinesToImage(h,1,'k')





    % -----------------------------------------------
    % Nested functions follow
    function h=peakFinder(mu)
        %Find locations of peaks along vector, mu. 
        %Peaks are supposed to correspond to where the grating is

        %Try to remove long-range trends
        mu = detrendLine(mu);

        %Estimate how far apart the peaks are
        [~,indMax] = max(abs(fft(mu-mean(mu))));
        period = round(length(mu)/indMax);

        fprintf('Period is about %d pixels\n',period)

        [pks,locs]=findpeaks(mu,'minpeakheight',std(mu)*0.8,'minpeakdistance', round(period*0.9) );

        if isempty(pks)
          error('found no peaks\n')
        end
        h.locs=locs;

        h.line=plot(mu);
        hold on 
        h.peaks=plot(locs,pks,'o');
        
        h.micsPix=gridPitch/mean(diff(locs));
        axis tight
    end %close peakFinder


    function addLinesToImage(h,axisToAdd,lineCol)
        %Overlay the calculated location of the grid lines onto the rotated image
        hold(rotAx,'on')
        for ii=1:length(h.locs)
            thisL = h.locs(ii);
            if axisToAdd == 1
                p(ii)=plot(rotAx,xlim(rotAx),[thisL,thisL]);
            elseif axisToAdd == 2
                p(ii)=plot(rotAx,[thisL,thisL],ylim(rotAx));
            end
        end

        if length(p)>10
            lWidth=0.5;
        elseif length(p)<10 && length(p)>5;
            lWidth=1;
        else
            lWidth=2;
        end

        set(p,'linewidth',lWidth,'color',lineCol);
    end %close addLinesToImage


    function bestAng=findGridAngle(inputIM)
        startAngleRange=25;
        startRes=5;
        minRes=0.05;

        currentRes = startRes;
        currentAngle=startAngleRange;
        bestAng = 0 ;
        T=1;

        if verbose
          fprintf('Finding angle of grating: ')
        end
        if verbose
            optFig=figure
        end

        while currentRes>=minRes

          angs = -currentAngle : currentRes : currentAngle;
          angs = angs + bestAng;
          thisV = zeros(size(angs));
          n=1;
          for a=angs
            thisV(n) = getVar(inputIM,a);
            n=n+1;
            T=T+1;
          end

          %update variables
          [~,ind]=max(thisV);
          bestAng = angs(ind);

          if verbose
            fprintf(' -> %0.1f (%0.2f)', bestAng, currentRes)
          end

          currentRes = currentRes * 0.6 ;
          currentAngle = currentAngle * 0.4;
        end

        if verbose
            close(optFig)
            fprintf('\n')
        end


        fprintf('Angle %0.3f in %d iterations\n', bestAng, T)
    end %close findGridAngle


    function v=getVar(im,ang)
        %rotate grid by angle "ang", project to x and y. calculate total variance along these axes
        tmp=imrotate(im,ang,'crop');

        if verbose

          subplot(1,2,1)
          imagesc(tmp)
        end
          
        tmp(tmp==0)=nan;

        m1 = nanmean(tmp,1);
        m2 = nanmean(tmp,2);

        if verbose
          subplot(1,2,2)
          cla
          plot(m1,'-r')
          hold on
          plot(m2,'-k')
          axis tight
          xlim([1,length(m1)])
          drawnow
        end
        v = var(m1) + var(m2);
    end %close getVar


    function out = detrendLine(data)
        %detrend data using a polynomial
        data=data(:);

        x=1:length(data);
        x=x';

        [p,s,mu] = polyfit(x,data,polynomDetrendOrder);
        f_y = polyval(p,x,[],mu);

        out = data-f_y;
    end
    

end %close Grid2MicsPerPixel