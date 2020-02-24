%% PDB model of tetragonal lysozyme, with gaussian solvent "atoms"

%% download the file from the protein data bank

pdbFileName = '6o2h.pdb';
mtzFileName = '6o2h.mtz';

% uncomment below to get from the PDB:
%websave(fullfile('model',pdbFileName),['https://files.rcsb.org/download/' pdbFileName]);
%websave(fullfile('model',mtzFileName),['https://edmaps.rcsb.org/coefficients/' mtzFileName]);

% or, use a local copy:
%copyfile('~/CloudStation/Documents/projects/lysozyme/refinement/triclinic/lys_tricl_4_refmac12_addH.pdb',...
%    fullfile('model',pdbFileName));
%copyfile('~/CloudStation/Documents/projects/lysozyme/refinement/triclinic/june2017_nitrate_ubatch4_aimless_truncate1.mtz',...
%    fullfile('model',mtzFileName));
%% import the coordinates
[Atoms,Basis,SpaceGroup] = pdbImport(fullfile('model',pdbFileName),'A'); % chain A is protein, the rest are het

isIon = ismember(Atoms.element,{'Cl'});

%% Find the solvent mask

% this is a re-implementation of the method in REFMAC5, followed by a
% blobbification of the mask

opts = {'dgrid',0.3,'vdwProb',1.2,'ionProb',0.8,'rShrink',0.8};

Sol = solventMaskBlobs(Atoms,isIon,Basis,SpaceGroup,opts{:});

Atoms = [Atoms Sol]; % there is one blob for each atom

clear opts Sol
%% load mtz file and add fcalc

% fcalc using splat method similar to SFALL

opts = {'dgrid',0.3};

mtzTruncate = addFcalc2mtz(fullfile('model',mtzFileName),Atoms,Basis,SpaceGroup,opts{:});

clear opts mtzFileName

%%
% least-squares fit the solvent parameters

% minimize (Fobs - ktot*abs(Fcalc + ksol*exp(-Bsol*s^2/4).*y))./sigma
fmodel = @(ks,Bs,t) t.Fcalc + ks*exp(-Bs*(t.sx.*t.sx + t.sy.*t.sy + t.sz.*t.sz)/4).*t.Fsolv;
residfun = @(k1,ks,Bs,t) (t.Fobs - k1.*abs(fmodel(ks,Bs,t)))./t.sigma;

Ufn = @(U11,U22,U33,U12,U13,U23) [U11 U12 U13; U12 U22 U23; U13 U23 U33];
Afn = @(K,U11,U22,U33,U12,U13,U23,t) ...
    K*exp(-2*pi^2*dot([t.sx,t.sy,t.sz]*Ufn(U11,U22,U33,U12,U13,U23),[t.sx,t.sy,t.sz],2));

ffun = @(K,U11,U22,U33,U12,U13,U23,ks,Bs,t) residfun(Afn(K,U11,U22,U33,U12,U13,U23,t),ks,Bs,t);

opts = optimoptions('lsqnonlin','MaxFunctionEvaluations',5000);
%opts = optimoptions('lsqnonlin','Display','iter','MaxFunctionEvaluations',5000);

solvFit = lsqnonlin(@(v) ffun(v(1),v(2),v(3),v(4),v(5),v(6),v(7),v(8),v(9),mtzTruncate),[1,0,0,0,0,0,0,-0.334,50],[],[],opts);

ktot = solvFit(1) % 0.9062
ksol = solvFit(8) % -0.4941
Bsol = solvFit(9) % 69.8998

Ufit = Ufn(solvFit(2),solvFit(3),solvFit(4),solvFit(5),solvFit(6),solvFit(7))
%   -0.0006   -0.0022    0.0008
%   -0.0022    0.0091   -0.0013
%    0.0008   -0.0013   -0.0218

%%
% add scale factors
for j=1:size(Atoms,1)
    Atoms.fatom(j) = Atoms.fatom(j).addU(Ufit);
    Atoms.fsol(j) = latt.GaussianDensitySum(Atoms.fsol(j).a*ksol,Atoms.fsol(j).V);
    Atoms.fsol(j) = Atoms.fsol(j).addU(Ufit + eye(3)*Bsol/(8*pi^2));
end

%assert(all(arrayfun(@(g) det(inv(g.U)),Atoms.fatom)>=0)); % check that U is invertible
%%
isPosDef = arrayfun(@(g) det(inv(g.U)),Atoms.fatom)>=0;

if ~all(isPosDef)
    ixbad = find(~isPosDef);
    warning('%d ADPs are no longer positive definite. they will be corrected',numel(ixbad));
    for j=1:numel(ixbad)
        thisf = Atoms.fatom(ixbad(j));
        [v,d] = eig(thisf.U);
        d(d<0)=10*eps;
        Atoms.fatom(ixbad(j)) = latt.GaussianAtom(thisf.a,thisf.b, v*d*v');
        % this is not the closest positive semi definite matrix, but it's not a terrible approximation
    end
end

%% Calculate pdb model grouped by residue

% Load the coordinates and the solvent model (one pseudo-atom for each real
% one). The solvent model parameters were fit to the Bragg data.

% sort the coordinates into groups

% first, put everything order
numRes = max(Atoms.resNum); %129

ind = accumarray(Atoms.resNum,1:size(Atoms,1),[numRes,1],@(v) {v});
atomOrder = cell2mat(ind);

Atoms = Atoms(atomOrder,:);

% now, assign coordinates to group operator so I can calculate projections
ind = accumarray(Atoms.resNum,1:size(Atoms,1),[numRes,1],@(v) {v});
assert(issorted(cell2mat(ind))); % just in case

G = nm.Group.empty();
for n=1:numel(ind)
    G(n) = nm.Group(Atoms.x(ind{n}),Atoms.y(ind{n}),Atoms.z(ind{n}),1);
end

P = G.tl2uxyz;
P0 = nm.Group(Atoms.x,Atoms.y,Atoms.z,1).tl2uxyz;
%nAtoms = numel(x);

%% Calculate pdb model grouped by domain

% Load the coordinates and the solvent model (one pseudo-atom for each real
% one). The solvent model parameters were fit to the Bragg data.

% sort the coordinates into groups

isalpha = false(129,1);
isalpha(5:36) = true;
isalpha(98:129) = true;

isbeta = false(129,1);
isbeta(40:94) = true;
ishinge = ~isalpha & ~isbeta;

Atoms.domain(isalpha(Atoms.resNum)) = 1;
Atoms.domain(isbeta(Atoms.resNum)) = 2;
Atoms.domain(ishinge(Atoms.resNum)) = 3;

% assign coordinates to group operator so I can calculate projections
ind = accumarray(Atoms.domain,1:size(Atoms,1),[3,1],@(v) {v});

%assert(issorted(cell2mat(ind))); % just in case

G = nm.Group.empty();
for n=1:numel(ind)
    G(n) = nm.Group(Atoms.x(ind{n}),Atoms.y(ind{n}),Atoms.z(ind{n}),1);
end

Pd = G.tl2uxyz;

% put atoms back in the correct order
atomOrder = cell2mat(ind);
Pd = mat2cell(Pd,3*ones(size(Pd,1)/3,1),size(Pd,2));
[~,ix] = sort(atomOrder,'ascend');
Pd = cell2mat(Pd(ix));
%nAtoms = numel(x);
%%

clear ind n G atomOrder
%%
save model/atomic_model.mat Atoms Basis SpaceGroup P P0 Pd ktot ksol Bsol Ufit
