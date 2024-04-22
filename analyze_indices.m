function analyze_indices(rasterFilename)
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

        % Plot DEM outline (if available)
        try
            [x, y] = getoutline(DEM, true);
            hold on;
            plot(x, y, 'k'); % Correct plot call for the outline
        catch outlineError
            warning('Failed to plot DEM outline: %s', outlineError.message);
        end

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

        % Calculate basin asymmetry and plot
        [~, AS] = dbasymmetry(FD, St, 'extractlongest', true);
        figure('Visible', 'off');
        imageschs(DEM, AS, 'caxis', [0 1], 'colormap', ttscm('broc'));
        print('Figure4_Basin_Asymmetry.jpg', '-djpeg');

        % Calculate area and stream length
        A   = flowacc(FD)*DEM.cellsize^2;
        a   = getnal(S,A);
        d   = distance(S,'max_from_ch');

        % Plot area vs stream length
        f5 = figure('Visible', 'off');
        plot(a,d,'.')
        xlabel('Area [m^2]')
        ylabel('Stream length [m]')
        print(f5, 'Figure5_Area_vs_Stream_Length.jpg', '-djpeg');

        % Fit power-law relationship
        b = nlinfit(a,d,@(b,X) b(1)*X.^b(2),[0.002 0.6]);

        % Plot fitted power-law curve
        f6 = figure('Visible', 'off');
        plot(a,d,'.')
        hold on
        fplot(@(X) b(1)*X.^b(2),xlim)
        hold off
        xlabel('Area [m^2]')
        ylabel('Stream length [m]')
        print(f6, 'Figure6_Fitted_Power_Law.jpg', '-djpeg');

        % Plot stream network with stream network and hypsometric curves
        f7 = figure('Visible', 'off');
        imageschs(DEM,[],'colormap',[1 1 1],'colorbar',false)
        hold on
        h = plotdbfringe(FD,S,'colormap',parula,'width',30);
        plot(S,'b')
        hold off

        % Inpaint nans in DEM and recalculate flow direction
        DEM = inpaintnans(DEM);
        FD = FLOWobj(DEM);

        % Calculate upslope statistics
        Hmax  = upslopestats(FD,DEM,'max');
        Hmin  = upslopestats(FD,DEM,'min');
        Hmean = upslopestats(FD,DEM,'mean');

        % Handle large stream components and plot results
        S   = STREAMobj(FD,'minarea',10000);
        S   = klargestconncomps(S,1);
        CS  = STREAMobj2cell(S);
        clr = lines(numel(CS));
        ax(1) = subplot(1,2,1);
        imagesc(~isnan(DEM));
        colormap(flipud(flowcolor));
        niceticks;
        hold on
        ax(2) = subplot(1,2,2);
        hold on
        xlabel('Cum. frequency [%]')
        ylabel('Elevation [m]')
        box on
        for r = 1:numel(CS)
            plot(CS{r},'parent',ax(1),'color',clr(r,:))
            I = drainagebasins(FD,CS{r});
            [rf,elev] = hypscurve(clip(DEM,I));
            plot(ax(2),rf,elev,'color',clr(r,:))
        end
        print(f7, 'Figure7_Stream_Network_and_Hypsometric_Curves.jpg', '-djpeg');

    catch ME
        % Display error message
        fprintf('Error occurred: %s\n', ME.message);
    end
end
