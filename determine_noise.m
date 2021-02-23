function determine_noise(ptnr,ptdata,ptsave,modality)
filename = [ptdata 'SEF' filesep 'filename.fif'];

fif_dir = dir([ptsave 'MEG' filesep '*_load_MEG.mat']);
fif_dir = fif_dir(1).name;
load(fif_dir,'file_dir');

for file = 1:length(file_dir)
    file_dirname=file_dir(file).name;
    
    % segmenting data into trial pieces
    cfg = [];
    cfg.dataset                 = filename;
    cfg.trialfun                = 'ft_trialfun_general';
    cfg.trialdef.eventtype      = 'Trigger';
    cfg.trialdef.prestim        = 0;
    cfg.trialdef.poststim       = 0.1;
    cfg = ft_definetrial(cfg);
    
    %% MEG
    load([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_load_MEG.mat'],'channels');
    
    cfg.channel                 = channels;
    cfg.demean                  = 'no';     % apply baselinecorrection
    data = ft_preprocessing(cfg);
    data.grad = ft_convert_units(data.grad, 'm');
    data.hdr.grad = ft_convert_units(data.hdr.grad, 'm');
    
    cfg.covariance              = 'no';
    cfg.keeptrials              = 'yes';
    cfg.removemean              = 'no';
    timelock = ft_timelockanalysis(cfg,data);
    cfg_timelock = cfg;
    trial=timelock.trial;
    
    cfg.covariance              = 'yes';
    cfg.keeptrials              = 'no';
    cfg.removemean              = 'yes';
    timelock = ft_timelockanalysis(cfg,data);
    timelock.trial=trial;
    time=timelock.time;
    
    noise=zeros(size(timelock.trial));
    noise=noise(:,:,26:250);
    for i=1:size(timelock.trial,1)
        n=squeeze(timelock.trial(i,:,26:250))-timelock.avg(26:250);
        noise(i,:,:)=n;
    end
    
    save([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_MEG_noise.mat'],'noise')
    
    %% EEG
    load([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_load_EEG.mat'],'channels');
    cfg.channel                 = channels; %'eeg';
    cfg.demean                  = 'yes';     % apply baselinecorrection
    data = ft_preprocessing(cfg);
    data.elec = ft_convert_units(data.elec,'m');
    data.hdr.elec = ft_convert_units(data.hdr.elec,'m');
    
    cfg.covariance              = 'no';
    cfg.keeptrials              = 'yes';
    cfg.removemean              = 'no';
    timelock = ft_timelockanalysis_bk(cfg,data);
    cfg_timelock = cfg;
    trial=timelock.trial;
    
%     cfg.covariance              = 'yes';
    cfg.keeptrials              = 'no';
%     cfg.removemean              = 'yes';
    timelock = ft_timelockanalysis_bk(cfg,data);
    timelock.trial=trial;
    time=timelock.time;
    
    noise=zeros(size(timelock.trial));
    noise=noise(:,:,26:250);
    for i=1:size(timelock.trial,1)
        n=squeeze(timelock.trial(i,:,26:250))-timelock.avg(26:250);
        noise(i,:,:)=n;
    end
    
    save([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_EEG_noise.mat'],'noise')
end
end