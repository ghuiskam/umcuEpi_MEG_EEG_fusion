function MRI=load_mri(ptsave)
[mriname, mripathname] = uigetfile('*.fif', 'Give the .fif file of the subject''s MR');
mriFileName= [mripathname  mriname];

mriOrig         = ft_read_mri(mriFileName);
mriOrig         = ft_convert_units(mriOrig, 'mm');
mriOrig.coordsys = 'neuromag';

cfg = [];
cfg.dim         = [256 256 256]; %exaggerate with dimensions, in any case the user will be able to reduce them if needed!
mriOrig           = ft_volumereslice(cfg, mriOrig);
MRI = mriOrig;
save([ptsave, 'MRI.mat'],'MRI','mriname','mripathname');


% write MRI to .nii file
cfg.parameter = 'anatomy';
cfg.filename = [ptsave '_' mriname(1:end-4)];
cfg.filetype = 'nifti';
cfg.datatype = 'double';
cfg.coordsys = 'neuromag';
ft_volumewrite(cfg, mriOrig)
niifilename = [cfg.filename '.nii'];

%% plot one slice
cfg                 = [];
cfg.method          = 'slice';
cfg.nslices         = 1;
cfg.slicerange      = [153 153];
cfg.interactive     = 'no';
cfg.funparameter    = 'mask';
cfg.coordsys        = 'neuromag';
ft_sourceplot(cfg, mriOrig);

%% read the transformed MRI with the segmentation
% make segmentation with SPM12
matlabbatch{1}.spm.spatial.preproc.channel.vols = {[niifilename ',1']};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {'/usr/local/matlab2020a/toolbox/local/UMCU/spm12/tpm/TPM.nii,1'};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {'/usr/local/matlab2020a/toolbox/local/UMCU/spm12/tpm/TPM.nii,2'};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {'/usr/local/matlab2020a/toolbox/local/UMCU/spm12/tpm/TPM.nii,3'};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {'/usr/local/matlab2020a/toolbox/local/UMCU/spm12/tpm/TPM.nii,4'};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {'/usr/local/matlab2020a/toolbox/local/UMCU/spm12/tpm/TPM.nii,5'};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
    NaN NaN NaN];

spm_jobman('run', matlabbatch);
end