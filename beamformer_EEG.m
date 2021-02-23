function beamformer_EEG(ptnr,ptdata,ptsave,modality)

if ~exist('sourcemodel','var'),      load([ptsave num2str(ptnr) '_BEM_headmodel_sourcemodel.mat']); end

fif_dir = dir([ptsave 'EEG' filesep '*_load_EEG.mat']);
fif_dir = fif_dir(1).name;
load(fif_dir,'file_dir');

for file = 1:length(file_dir)
    file_dirname=file_dir(file).name;
    
    load([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_load_EEG.mat']); % end
    load([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_EEG_lf.mat']); % end
    
    fif_filt = dir([ptdata file_dirname filesep '*Hz.fif']);
    fif_filt=fif_filt.name;
    fif_unfilt = dir([ptdata file_dirname filesep '*cxsss.fif']);
    fif_unfilt=fif_unfilt.name;
    
    % Data for the filtered signal
    cfg                         = [];
    cfg.dataset                 = [ptdata file_dirname filesep fif_filt];
    cfg.trialdef.triallength    = Inf; %duration in seconds (can be Inf)
    cfg.trialdef.ntrials        = 1; %number of trials
    cfg = ft_definetrial(cfg);
    
    cfg.channel = channels; %  to exclude specific channels
    cfg.reref = 'yes'; % rereference signals to common average of all selected channels
    cfg.refchannel = 'all';
    cfg.refmethod = 'avg';
    cfg.continuous = 'yes';
    data = ft_preprocessing(cfg); % load EEG data
    data.elec = ft_convert_units(data.elec,'m'); %data.grad = ft_convert_units(data.grad, 'm');
    data.hdr.elec = ft_convert_units(data.hdr.elec,'m'); %data.grad = ft_convert_units(data.grad, 'm');
    
    % Data for the unfiltered signal
    cfg                         = [];
    cfg.dataset                 = [ptdata file_dirname filesep fif_unfilt];
    cfg.trialdef.triallength    = Inf; %duration in seconds (can be Inf)
    cfg.trialdef.ntrials        = 1; %number of trials
    cfg = ft_definetrial(cfg);
    
    cfg.channel = channels; %  to exclude specific channels
    cfg.reref = 'yes'; % rereference signals to common average of all selected channels
    cfg.refchannel = 'all';
    cfg.refmethod = 'avg';
    cfg.continuous = 'yes';
    data_unfilt = ft_preprocessing(cfg); % load data
    data_unfilt.elec = ft_convert_units(data_unfilt.elec,'m'); %data.grad = ft_convert_units(data.grad, 'm');
    data_unfilt.hdr.elec = ft_convert_units(data_unfilt.hdr.elec,'m'); %data.grad = ft_convert_units(data.grad, 'm');
    
    cfg                  = [];
    cfg.covariance       = 'yes'; %compute covariance matrix
    cfg.covariancewindow = 'all';
    cfg.vartrllength     = 0; % do not accept variable trial lengths.
    cfg.removemean       = 'no'; %default 'yes'
    timelock             = ft_timelockanalysis(cfg, data);
    
    %timelock now contains the filtered data in avg, but we want to perform beamformer on the unfiltered data so:
    timelock.avg = data_unfilt.trial{1}; %unfiltData;
    
    figure; plot(timelock.time, timelock.avg)
  
    %% Source analysis big
    cfg=[];
    cfg.method = 'sam';
    cfg.senstype = 'EEG';
    cfg.headmodel = headmodel; %volume conduction model
    cfg.sam.lambda = '5%'; %regularisation parameter, 0 or 'xx%'
    cfg.sam.meansphereorigin = 1; %unused but value is necessary to not crash the script
    cfg.sam.fixedori = 'robert'; %method to find smallest eigenvalue
    cfg.sourcemodel = lf; %leadfield, which has the grid information
    [source,dipout] = ft_sourceanalysis_bk(cfg, timelock); % output in dipout.mom
    
    % Create channelnames for dipout
    load([ptsave  num2str(ptnr) '_elecnames.mat']);
    VE_chn = cell(1,size(lf.leadfield,1));
    for x=1:size(lf.leadfield,1)
        VE_chn{x} = strcat('V',elec_names{x,1});
    end
    
    % save
    data_out = zeros(size(dipout.momnorm,2),size(timelock.avg,2));
    for p=1:size(dipout.momnorm,2)
        data_out(p,:) = dipout.momnorm{p};
    end
    
    data_out = single(data_out);
    filename=[ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_EEG_beamformer.mat'];
    save(filename,'data_out','VE_chn','-v7.3');
    disp(['Saved file: ' filename]);
end %for-loop
end %function
