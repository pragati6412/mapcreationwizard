function analyze_hypsometric_integral(rasterFilename)
    % Check if the input file exists
    if ~exist(rasterFilename, 'file')
        error('File does not exist: %s', rasterFilename);
    end

    try
        % Load Digital Elevation Model (DEM) from raster file
        DEM = GRIDobj(rasterFilename);
        FD  = FLOWobj(DEM);
        S   = STREAMobj(FD, 'minarea', 1000);
        S   = klargestconncomps(S, 1);

        % Visualization of the DEM with streams
        f1 = figure('Visible', 'off'); % Set figure to be invisible
        imageschs(DEM, [], 'colormap', [1 1 1], 'colorbar', false);
        hold on;
        plotdbfringe(FD, S, 'colormap', parula, 'width', 30);
        plot(S, 'b');
        hold off;
        % Save figure
        print(f1, 'Figure1_DEM_Streams.jpg', '-djpeg');

        % Inpaint nans in DEM and recalculate flow direction
        DEM = inpaintnans(DEM);
        FD = FLOWobj(DEM);

        % Calculate statistics
        Hmax  = upslopestats(FD, DEM, 'max');
        Hmin  = upslopestats(FD, DEM, 'min');
        Hmean = upslopestats(FD, DEM, 'mean');

        % Calculate normalized accumulated lengths
        S = STREAMobj(FD, 'minarea', 1000);
        Hmean = getnal(S, Hmean);
        Hmin  = getnal(S, Hmin);
        Hmax  = getnal(S, Hmax);
        HI = (Hmean - Hmin) ./ (Hmax - Hmin);

        % Plot hypsometric integral
        f2 = figure('Visible', 'off'); % Set figure to be invisible
        plotc(S, HI);
        axis image;
        padextent(2000);
        [x, y] = getoutline(DEM, true);
        hold on;
        plot(x, y, 'k'); % Correct plot call for the outline
        % Save figure
        print(f2, 'Figure2_Hypsometric_Integral.jpg', '-djpeg');

        % Handle large stream components and plot results
        St = trunk(klargestconncomps(S));
        Hmean = nal2nal(St, S, Hmean);
        Hmax = nal2nal(St, S, Hmax);
        Hmin = nal2nal(St, S, Hmin);
        HI   = nal2nal(St, S, HI);

        f3 = figure('Visible', 'off'); % Set figure to be invisible
        plotdzshaded(St, [Hmax, Hmean], 'facecolor', [0.3010 0.7450 0.9330]);
        hold on;
        plotdzshaded(St, [Hmean, Hmin], 'facecolor', [0.9290 0.6940 0.1250]);
        plotdz(St, DEM, 'color', 'k');
        yyaxis right;
        plotdz(St, HI, 'color', 'b', 'LineWidth', 1.5);
        ylabel('Hypsometric integral');
        xlim([0 max(St.distance)]);
        legend('Hmax | Hmean', 'Hmean | Hmin', 'River profile', 'Hypsometric integral', 'location', 'northwest');
        box on;
        % Save figure
        print(f3, 'Figure3_Shaded_Profile_Hypsometric_Curve.jpg', '-djpeg');
    catch ME
        % Display error message
        fprintf('Error occurred: %s\n', ME.message);
    end
end
