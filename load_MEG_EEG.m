function [file_dirname,fif,channels]=load_MEG_EEG(ptnr,ptdata,ptsave,modality)
%% Determine the files for the patient
file_dir = dir([ptdata 'file*']);

for file =1:length(file_dir)
    file_dirname = file_dir(file).name;
    fif = dir([ptdata file_dirname filesep '*Hz.fif']);
    fif = fif.name;
    
    switch modality
        
        % Load the MEG bad channels and save the file name
        case 'MEG'
            
            chanfiles = dir([ptdata file_dirname filesep 'pt_*']);
            MEGchan = textread([ptdata file_dirname filesep chanfiles(1).name],'%s','delimiter',' ');
            for i=1:length(MEGchan), if length(MEGchan{i}) == 3, MEGchan{i} = strcat('0',MEGchan{i}); end; end %fix if MEG chan is only 3 numbers
            MEGchan = strcat('-MEG',MEGchan);
            channels = [{'MEG'}, MEGchan'];
            
            if ~exist([ptsave 'MEG'],'dir'),     mkdir([ptsave 'MEG']); end
            save([ptsave 'MEG' filesep num2str(ptnr) '_' file_dirname '_load_MEG.mat'],'file_dir','file_dirname','fif','channels');
            
        % Load the EEG bad channels and save the file name
        case 'EEG'
            
            chanfiles = dir([ptdata  file_dirname filesep '*EEG*']); %find file with EEG bad channels
            EEGchan = textread([ptdata file_dirname filesep chanfiles(1).name],'%s','delimiter',' ');
            EEGchan = strcat('-EEG0',EEGchan);
            channels = [{'EEG'}, EEGchan'];
            
            if ~exist([ptsave 'EEG'],'dir'),     mkdir([ptsave 'EEG']); end
            save([ptsave 'EEG' filesep num2str(ptnr) '_' file_dirname '_load_EEG.mat'],'file_dir','file_dirname','fif','channels');
            
    end %Switch
end %For-loop
end %Function