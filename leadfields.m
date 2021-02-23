function [lf,hdr]=leadfields(ptnr,ptdata,ptsave,modality)

if ~exist('sourcemodel','var'),      load([ptsave num2str(ptnr) '_BEM_headmodel_sourcemodel.mat']); end

switch modality
    case 'MEG'
        
        fif_dir = dir([ptsave 'MEG' filesep '*_load_MEG.mat']);
        fif_dir = fif_dir(1).name;
        load(fif_dir,'file_dir');
        
        for file = 1:length(file_dir)
            file_dirname=file_dir(file).name;
            
            load([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_load_MEG.mat']);
            
            hdr                  = ft_read_header([ptdata file_dirname filesep fif]);
            hdr.grad             = ft_convert_units(hdr.grad,'m');
            
            cfg                  = [];
            cfg.grad             = hdr.grad;
            cfg.headmodel        = headmodel;   % volume conduction headmodel
            cfg.sourcemodel      = sourcemodel;
            cfg.channel          = channels; % {'EEG', '-EEG001', '-EEG039'} to exclude specific channels
            lf                   = ft_prepare_leadfield(cfg); % voor FEM duurt +- 10 min per EEG elektrode!
            
            % multiply MAG leadfields with 10
            mag = regexp(lf.label,'MEG\d\d\d1'); mag = find(~cellfun(@isempty,mag));
            leadfield = lf.leadfield;
            for i=1:size(leadfield,1)
                if ~isempty(leadfield{i})
                    leadfield{i}(mag,:)=leadfield{i}(mag,:).*10;
                end
            end
            lf.leadfield = leadfield;
            
            if ~exist([ptsave 'MEG'],'dir'),     mkdir([ptsave 'MEG']); end
            save([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_MEG_lf.mat'],'lf','hdr');
            ft_notice(['Saved ' num2str(ptnr) '_' file_dirname '_MEG_lf.mat'])
        end %for-loop
        
    case 'EEG'
        
        fif_dir = dir([ptsave 'EEG' filesep '*_load_EEG.mat']);
        fif_dir = fif_dir(1).name;
        load(fif_dir,'file_dir');
        
        for file = 1:length(file_dir)
            file_dirname=file_dir(file).name;
            
            load([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_load_EEG.mat']);
            % Leadfields for EEG
            hdr                  = ft_read_header([ptdata file_dirname filesep fif]);
            hdr.elec             = ft_convert_units(hdr.elec,'m');
            
            cfg                  = [];
            cfg.elec             = hdr.elec;  % electrode distances
            cfg.headmodel        = headmodel;   % volume conduction headmodel
            cfg.sourcemodel      = sourcemodel;  % normalized grid positions
            cfg.channel          = channels; % {'EEG', '-EEG001', '-EEG039'} to exclude specific channels
            lf                   = ft_prepare_leadfield(cfg); % voor FEM duurt +- 10 min per EEG elektrode!
            
            if ~exist([ptsave 'EEG'],'dir'),    mkdir([ptsave 'EEG']); end
            save([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_EEG_lf.mat'],'lf','hdr');
            ft_notice(['Saved ' num2str(ptnr) '_' file_dirname '_EEG_lf.mat'])
        end %for-loop
end %switch
end %function