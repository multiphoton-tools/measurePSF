function uniform_slide_laser_stability(fname)
    % Make nice plots of the uniform slide data



    [inputPSFstack,metadata] = mpsf_tools.scanImage_stackLoad(fname);
    micsPerPixelZ = metadata.stackZStepSize;
    micsPerPixelXY = metadata.micsPerPixelXY;


    % Make a new figure or return a plot handle as appropriate
    fig = mpsf_tools.returnFigureHandleForFile([fname,'stability']);


    subplot(1,2,1)
    im_mu = mean(inputPSFstack,3);
    im_var = var(inputPSFstack,[],3);

    imagesc(im_mu/im_var)
    axis equal tight
    colormap gray

    colorbar

    mpsf_tools.add_scale_axis_tick_labels(gca,micsPerPixelXY)
    title('Mean over variance')

    subplot(1,2,2)
    imagesc(im_var)
    axis equal tight

    colorbar

    mpsf_tools.add_scale_axis_tick_labels(gca,micsPerPixelXY)

    title('Variance')