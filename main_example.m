ptnr = 100;
modality='MEG';

ptdata = ['/folder/to/rawdata/' num2str(ptnr) filesep];
ptsave = ['/folder/to/store/data/' num2str(ptnr) filesep];
if ~exist(ptsave,'dir'),     mkdir(ptsave); end

restoredefaultpath
addpath /folder/to/fieldtrip/;
ft_defaults
addpath '/folder/to/spm'
setenv('PATH', ['/folder/to/OpenMEEG/bin:' getenv('PATH')]);
setenv('LD_LIBRARY_PATH', ['/folder/to/OpenMEEG/lib:' getenv('LD_LIBRARY_PATH')]);

%% Load MRI
MRI=load_mri(ptsave);

%% Create Headmodel and Sourcemodel
[headmodel,sourcemodel]=create_BEM(ptnr,ptdata,ptsave);

%% Create Channels and Fif-file
switch modality
    case 'Fusion'
        disp('Filenames and badchannels will be taken from MEG and EEG')
    otherwise
        [file_dirname,fif,channels]=load_MEG_EEG(ptnr,ptdata,ptsave,modality);
end

%% DetermineNoise
determine_noise(ptnr,ptdata,ptsave,modality);

%% Leadfield
switch modality
    case 'MEG'
        [lf,hdr]=leadfields(ptnr,ptdata,ptsave,modality);
    case 'EEG'
        [lf,hdr]=leadfields(ptnr,ptdata,ptsave,modality);
    case 'Fusion'
        leadfield_fusion(ptnr,ptdata,ptsave);
end

%% Beamformer
switch modality
    case 'MEG'
        beamformer_MEG(ptnr,ptdata,ptsave,modality)
    case 'EEG'
        beamformer_EEG(ptnr,ptdata,ptsave,modality)
end