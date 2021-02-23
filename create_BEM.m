function [headmodel,sourcemodel]=create_BEM(ptnr,ptdata,ptsave)

%Only once per patient: create BEM model and sourcemodel
load([ptsave 'MRI.mat'],'MRI'); % matfile containing the realigned anatomical scan
c1file = dir([ptsave filesep 'c1*.nii']);
iso_coreg = c1file.name(3:end);
pts = dir([ptsave '*.pts']); % find file with VE locations
pts = pts.name;

%% Create headmodel BEM
% Segment brain from MRI
segment = ft_read_mri([ptsave 'c1' iso_coreg]);
seg.gray = segment.anatomy;
segment = ft_read_mri([ptsave 'c2' iso_coreg]);
seg.white = segment.anatomy;
segment = ft_read_mri([ptsave 'c3' iso_coreg]);
seg.csf = segment.anatomy;
segment = ft_read_mri([ptsave 'c4' iso_coreg]);
seg.skull = segment.anatomy;
segment = ft_read_mri([ptsave 'c5' iso_coreg]);
seg.scalp = segment.anatomy;
seg.coordsys = MRI.coordsys;
seg.unit = MRI.unit;
seg.dim = MRI.dim;
seg.transform = MRI.transform;
seg.anatomy = MRI.anatomy;
%
cfg                = [];
cfg.output         = {'brain' 'skull' 'scalp'};
segmentedmri = ft_volumesegment(cfg, seg);

%create mesh
cfg                 = [];
cfg.spmversion      = 'spm12';
cfg.method          = 'projectmesh';
cfg.tissue          = {'brain','skull','scalp'};
cfg.numvertices     = [3000 2000 1000];
mesh = ft_prepare_mesh(cfg,segmentedmri);

% Check headmodel
figure;
ft_plot_mesh(mesh(1),'facealpha',0.4)
hold on;
ft_plot_mesh(mesh(2),'facealpha',0.4)
ft_plot_mesh(mesh(3),'facealpha',0.4)

% compute the subject's headmodel/volume conductor model using openMEEG
cfg                = [];
cfg.method         = 'openmeeg';
cfg.spmversion     = 'spm12';
cfg.tissue         = {'brain' 'skull' 'scalp'};
cfg.numvertices    = [3000 1500 800];
headmodel          = ft_prepare_headmodel(cfg, mesh);

% Check headmodel
figure;
ft_plot_mesh(headmodel.bnd(3)); %brain
figure;
ft_plot_mesh(headmodel.bnd(2)); %skull
figure;
ft_plot_mesh(headmodel.bnd(1)); %scalp

figure
ft_plot_mesh(headmodel.bnd(1), 'facecolor',[0.2 0.2 0.2], 'facealpha', 0.3, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
hold on;
ft_plot_mesh(headmodel.bnd(2),'edgecolor','none','facealpha',0.4);
hold on;
ft_plot_mesh(headmodel.bnd(3),'edgecolor','none','facecolor',[0.4 0.6 0.4]);

headmodel = ft_convert_units(headmodel,'m');

cfg                 = [];
cfg.method          = 'basedonpos';
cfg.spmversion      = 'spm12';
cfg.sourcemodel.pos = load([ptsave pts]);  % normalized grid positions
cfg.sourcemodel.pos = cfg.sourcemodel.pos; %./10; %make unit = cm
cfg.headmodel       = headmodel;
cfg.inwardshift     = 1;
cfg.moveinward      = 2; %check if all grid points are inside the brain, if not, move them.
sourcemodel = ft_prepare_sourcemodel(cfg);
sourcemodel = ft_convert_units(sourcemodel,'m');

% only for plot:
load([ptsave  num2str(ptnr) '_elecnames.mat']);
figure;
ft_plot_mesh(headmodel.bnd(3),'edgecolor','none','facealpha',0.4); %alpha 0.4 
hold on
% ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:),'vertexcolor','r');
% ft_plot_mesh(sourcemodelold.pos,'vertexcolor','r');
% hold on
% figure;
ft_plot_mesh(sourcemodel.pos,'vertexcolor','r');
text(sourcemodel.pos(:,1),sourcemodel.pos(:,2),sourcemodel.pos(:,3),elec_names,'Color','b','VerticalAlignment','bottom','HorizontalAlignment','right')
% end

figure;
ft_plot_mesh(headmodel.bnd(3)); hold on; alpha 0.4;% , 'edgecolor', 'none'); 
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:),'vertexcolor','r');

save([ptsave num2str(ptnr) '_BEM_headmodel_sourcemodel.mat'],'headmodel','sourcemodel','-v7.3');
end