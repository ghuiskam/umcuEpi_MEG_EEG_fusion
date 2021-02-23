function leadfield_fusion(ptnr,ptdata,ptsave)
if ~exist('sourcemodel','var'),      load([ptsave num2str(ptnr) '_BEM_headmodel_sourcemodel.mat'],'headmodel','sourcemodel'); end

% Load EEG and MEG leadfields
fif_dir = dir([ptsave 'MEG' filesep '*_load_MEG.mat']);
fif_dir = fif_dir(1).name;
load(fif_dir,'file_dir');

for file = 1:length(file_dir)
file_dirname=file_dir(file).name;
load([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_load_MEG.mat'],'channels');
load([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_MEG_noise.mat'],'noise')
load([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_MEG_lf.mat'],'hdr');

hdr.grad=ft_convert_units(hdr.grad, 'm');
hdr.elec=ft_convert_units(hdr.elec, 'm');
channels_meg=channels;
noise_meg=noise;

load([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_load_EEG.mat'],'channels');
load([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_EEG_noise.mat'],'noise')

channels_eeg=channels;
noise_eeg=noise;

combined_channels={'*EG*' channels_meg{2:end} channels_eeg{2:end}};
clear channels noise

%% Load data
fif = dir([ptdata file_dirname filesep '*cxsss.fif']);
fif=fif.name;
% Data for the unfiltered signal
cfg                         = [];
cfg.dataset                 = [ptdata file_dirname filesep fif];
cfg.trialdef.triallength    = Inf; %duration in seconds (can be Inf)
cfg.trialdef.ntrials        = 1; %number of trials
cfg = ft_definetrial(cfg);

% Load MEG+EEG data
cfg.channel = combined_channels;
cfg.reref = 'no'; % rereference signals to common average of all selected channels
cfg.continuous = 'yes';
data = ft_preprocessing(cfg); % load data
data.grad = ft_convert_units(data.grad, 'm');
data.hdr.grad = ft_convert_units(data.hdr.grad, 'm');
data.elec = ft_convert_units(data.elec,'m');
data.hdr.elec = ft_convert_units(data.hdr.elec,'m');
   
[~,megidx]=intersect(data.label,ft_channelselection('MEG',data.label));
[~,megmagidx]=intersect(data.label,ft_channelselection('MEGMAG',data.label));
[~,meggradidx]=intersect(data.label,ft_channelselection('MEGGRAD',data.label));
[~,eegidx]=intersect(data.label,ft_channelselection('EEG',data.label));

fif_filt = dir([ptdata file_dirname filesep '*Hz.fif']);
fif_filt=fif_filt.name;
cfg                         = [];
cfg.dataset                 = [ptdata file_dirname filesep fif_filt];
cfg.trialdef.triallength    = Inf; %duration in seconds (can be Inf)
cfg.trialdef.ntrials        = 1; %number of trials
cfg = ft_definetrial(cfg);
cfg.channel = combined_channels;
cfg.reref = 'no'; % rereference signals to common average of all selected channels
cfg.continuous = 'yes';
data_filt = ft_preprocessing(cfg); % load data
data_filt.grad = ft_convert_units(data_filt.grad, 'm');
data_filt.hdr.grad = ft_convert_units(data_filt.hdr.grad, 'm');
data_filt.elec = ft_convert_units(data_filt.elec,'m');
data_filt.hdr.elec = ft_convert_units(data_filt.hdr.elec,'m');


%% SNR transformation
noise_megmag=noise_meg(:,megmagidx,:);
noise_meggrad=noise_meg(:,meggradidx,:);

noise_megmag2=rms(noise_megmag,3);
noise_megmag2=std(noise_megmag2);
noise_meggrad2=rms(noise_meggrad,3);
noise_meggrad2=std(noise_meggrad2);
noise_eeg2=rms(noise_eeg,3);
noise_eeg2=std(noise_eeg2);
noise=[noise_megmag2' ; noise_meggrad2' ; noise_eeg2'];
noise=1./noise;

figure;
plot(noise_megmag2)
hold on
plot(noise_meggrad2)
title('Noise for MEG sensors')
% plot(noise_eeg2)
figure;
plot(noise)
title('Noise for MEG and EEG channels')

%% Implement Noise
data.trial{1}=data.trial{1}.*noise;
data_filt.trial{1}=data_filt.trial{1}.*noise;

%% Fusion
combined_labels=ft_channelselection(combined_channels,data);
combined_vol = {headmodel, headmodel};
combined_sens = {hdr.grad, hdr.elec};
combined_channels={ft_channelselection(channels_meg,data),ft_channelselection(channels_eeg,data)};

lf = cell(1,numel(combined_sens));
for i=1:length(combined_sens)
    cfg                  = [];
    cfg.grad             = combined_sens{i};
    cfg.headmodel        = combined_vol{i};   % volume conduction headmodel
    cfg.sourcemodel      = sourcemodel;
    cfg.channel          = combined_channels{i}; % {'EEG', '-EEG001', '-EEG039'} to exclude specific channels
    lf{i}                = ft_prepare_leadfield(cfg); % voor FEM duurt +- 10 min per EEG elektrode!
    leadfield{i}=lf{i}.leadfield;
    label{i}=lf{i}.label;
end

for j=1:size(leadfield{1},1)
leadfield2{j}=cat(1,leadfield{1}(j),leadfield{2}(j));
leadfield2{j}=cat(1,leadfield2{j}{:});
end

for i=1:size(leadfield{1},1)
    for j=1:size(noise,1)
        leadfield2{i}(j,1) = leadfield2{i}(j,1) * noise(j); % the leadfield for the x-direction
        leadfield2{i}(j,2) = leadfield2{i}(j,2) * noise(j); % the leadfield for the y-direction
        leadfield2{i}(j,3) = leadfield2{i}(j,3) * noise(j); % the leadfield for the z-direction
    end
end

lf = lf{1};
lf.leadfield = leadfield2';
lf.label = cat(1, label{:});
lf.cfg.channel=combined_labels;

%% Timelock
cfg                  = [];
cfg.covariance       = 'yes'; %compute covariance matrix
cfg.covariancewindow = 'all';
cfg.vartrllength     = 0; % do not accept variable trial lengths.
cfg.removemean       = 'no'; %default 'yes'
timelock             = ft_timelockanalysis(cfg, data_filt);

%timelock now contains the filtered data in avg, but we want to perform beamformer on the unfiltered data so:
timelock.avg=data.trial{1};
timelock.cov(megmagidx,meggradidx)  = 0;
timelock.cov(megmagidx,eegidx)      = 0;
timelock.cov(meggradidx,megmagidx)  = 0;
timelock.cov(meggradidx,eegidx)     = 0;
timelock.cov(eegidx,megmagidx)      = 0;
timelock.cov(eegidx,meggradidx)     = 0;

figure; plot(timelock.time, timelock.avg)
title('Timelock')


%% Beamforming
cfg=[];
cfg.method = 'sam';
% cfg.senstype = 'MEG';
cfg.headmodel = headmodel; %volume conduction model
cfg.sam.lambda = '5%'; %regularisation parameter, 0 or 'xx%'
cfg.sam.meansphereorigin = 1; %unused but value is necessary to not crash the script
cfg.sam.fixedori = 'robert'; %method to find smallest eigenvalue
cfg.sourcemodel = lf; %leadfield, which has the grid information
[source,dipout] = ft_sourceanalysis_bk(cfg, timelock); % output in dipout.mom

load([ptsave  num2str(ptnr) '_elecnames.mat'],'elec_names');
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
filename=[ptsave 'Fusion' filesep num2str(ptnr) '_' file_dirname '_Fusion_beamformer.mat'];
save(filename,'data_out','VE_chn','-v7.3');
disp(['Saved file: ' filename]);
clearvars -except ptdata ptsave ptnr modality headmodel sourcemodel fif_dir file_dir
end
end