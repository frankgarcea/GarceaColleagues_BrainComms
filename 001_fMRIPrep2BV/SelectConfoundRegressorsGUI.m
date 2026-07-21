function [selectedVariables, keepForAllRuns] = ...
    SelectConfoundRegressorsGUI(header)

    % ensure cell array
    header = cellstr(header);

    % =====================================================
    % Motion regressors to prioritize
    % =====================================================

    priorityVars = { ...
        'trans_x', ...
        'trans_y', ...
        'trans_z', ...
        'rot_x', ...
        'rot_y', ...
        'rot_z', ...
        'std_dvars',...
        'framewise_displacement'};

    % =====================================================
    % Reorder header so motion vars appear first
    % =====================================================

    % keep only priority vars that actually exist
    existingPriorityVars = ...
        priorityVars(ismember(priorityVars, header));

    % all remaining variables
    remainingVars = ...
        header(~ismember(header, existingPriorityVars));

    % final ordered header
    orderedHeader = [existingPriorityVars remainingVars];

    % =====================================================
    % Find default selected indices
    % =====================================================

    defaultIndices = find(ismember(orderedHeader, priorityVars));

    % =====================================================
    % Create FIGURE (classic MATLAB GUI system)
    % More stable on Linux VMs than UIFIGURE
    % =====================================================

    fig = figure( ...
        'Name','Select Confound Regressors', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Position',[100 100 500 700], ...
        'Resize','off');

    % =====================================================
    % Title text
    % =====================================================

    uicontrol(fig,...
        'Style','text',...
        'String','Select confound regressors:',...
        'HorizontalAlignment','left',...
        'FontWeight','bold',...
        'Position',[20 660 300 20]);

    % =====================================================
% LISTBOX with scrolling support
% =====================================================

lb = uicontrol(fig,...
    'Style','listbox',...
    'String',orderedHeader,...
    'Min',0,...
    'Max',2,...
    'FontSize',10,...
    'Position',[20 120 450 530]);

% force GUI rendering
drawnow;

% force list to open at top
set(lb,'Value',defaultIndices(1));
set(lb,'ListboxTop',1);

% now restore all default selections
set(lb,'Value',defaultIndices);

    % =====================================================
    % Keep-for-all-runs checkbox
    % =====================================================

    keepCB = uicontrol(fig,...
        'Style','checkbox',...
        'String','Use these confounds for all remaining runs',...
        'Value',1,...
        'HorizontalAlignment','left',...
        'Position',[20 70 350 25]);

    % =====================================================
    % OK button
    % =====================================================

    uicontrol(fig,...
        'Style','pushbutton',...
        'String','OK',...
        'FontWeight','bold',...
        'Position',[190 20 120 35],...
        'Callback',@(src,event) uiresume(fig));

    % =====================================================
    % Wait for user
    % =====================================================

    uiwait(fig);

    % =====================================================
    % Handle case where figure is manually closed
    % =====================================================

    if ~isvalid(fig)

        warning('Confound selection GUI closed by user.');

        selectedVariables = {};
        keepForAllRuns = 0;

        return

    end

    % =====================================================
    % Get selected indices from listbox
    % =====================================================

    selectedIdx = get(lb,'Value');

    selectedVariables = orderedHeader(selectedIdx);

    keepForAllRuns = get(keepCB,'Value');

    % =====================================================
    % Close GUI
    % =====================================================

    close(fig);

end