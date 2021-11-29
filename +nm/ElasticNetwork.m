classdef ElasticNetwork < util.propertyValueConstructor
    %ElasticNetwork vibrational dynamics using Born/Von-Karman method
    
    properties
        Cell  % model of the unit cell (nm.Cell type)
        Edges % Table of cell edges, as produced by Cell.contactSearch()
    end
    properties(Constant)
        G_n = latt.PeriodicGrid([3,3,3],[-1,-1,-1],[3,3,3]);
    end
    
    methods
        function obj = ElasticNetwork(varargin)
            %ElasticNetwork 
            obj@util.propertyValueConstructor(varargin{:});
        end
        
        % TODO: functions to parameterize the Hessian
        
        function V = Hessian(obj,springType,k)
            switch lower(springType)
                case {'gauss','gaussian'}
                    V = obj.Hessian_Gauss(k);
                case {'par','parallel'}
                    V = obj.Hessian_parallel(k);
                case {'hybrid'}
                    assert(size(k,2)==2)
                    V = obj.Hessian_hybrid(k(:,1),k(:,2));
                otherwise
                    error('springType not recognized');
            end
        end
        
        function V = Hessian_hybrid(obj,kperp,kpar)
            assert(nargin==3 & ~isempty(kperp) & all(size(kperp)==size(kpar)));
            if numel(kperp)==1
                kperp = repmat(kperp,size(obj.Edges,1),1);
                kpar = repmat(kpar,size(obj.Edges,1),1);
            end
            E_full = obj.E_full();
            E_par = obj.E_parallel(E_full);
            kmat_par = diag(sparse(kpar - kperp));
            kmat_full = diag(sparse(kron(kperp(:)',[1,1,1])));
            V = cell(size(E));
            for n = 1:numel(E)
                V{n} = E_full{2,2,2}'*kmat_full*E_full{n} + E_par{2,2,2}'*kmat_par*E_par{n};
            end
        end
        
        function V = Hessian_parallel(obj,k)
            if nargin < 2 || isempty(k)
                k = 1;
            end
            if numel(k)==1
                k = repmat(k,size(obj.Edges,1),1);
            end
            E = obj.E_parallel();
            V = cell(size(E));
            kmat = diag(sparse(k));
            for n = 1:numel(E)
                V{n} = E{2,2,2}'*kmat*E{n};
            end
        end
        
        function V = Hessian_Gauss(obj,k)
            if nargin < 2 || isempty(k)
                k = 1;
            end
            if numel(k)==1
                k = repmat(k,size(obj.Edges,1),1);
            end
            E = obj.E_full();
            V = cell(size(E));
            kmat = diag(sparse(kron(k(:)',[1,1,1])));
            for n = 1:numel(E)
                V{n} = E{2,2,2}'*kmat*E{n};
            end
        end
        
        function E = E_full(obj)
            P = obj.Cell.tl2uxyz();
            edgeMat = obj.edgeMatrix();
            
            E = cell(obj.G_n.N);
            for n = 1:numel(E)
                E{n} = kron(edgeMat{n},speye(3,3))*P;
            end
        end
        
        function E = E_parallel(obj,E)
            if nargin < 2 % optionally pass E to avoid re-calculating it
                E = obj.E_Gauss();
            end
            v12 = obj.bondVectors();
            
            [r,c] = ndgrid(1:size(v12,1),1:3);
            c2 = c + (r-1)*3;
            u = sparse(r(:),c2(:),v12(:));
            
            for n = 1:numel(E)
                E{n} = u*E{n};
            end
        end
        
        function v12 = bondVectors(obj)
            % calculate unit vectors along each bond
            [r1,r2] = obj.nodes();
            v12 = r2-r1;
            d12 = sqrt(sum(v12.*v12,2));
            v12 = v12.*repmat(1./d12,1,3);
            assert(size(v12,2)==3);
        end
        
        function [r1,r2] = nodes(obj)
            Ops = obj.Cell.UnitCellOperators;
            B = symm.AffineTransformation(obj.Cell.Basis.orthogonalizationMatrix,[0;0;0]);
            
            r = [obj.Cell.AsymmetricUnit.r];
             
            r = inv(B)*r; % convert to fractional coordinates
            
            [n1,n2,n3] = obj.G_n.grid();
            n123 = [n1(:),n2(:),n3(:)];
            SuperCellOps = arrayfun(...
                @(a1,a2,a3) symm.SymmetryOperator(eye(3),[a1;a2;a3]),...
                n123(:,1),n123(:,2),n123(:,3));
            [~,cellindex] = ismember(obj.Edges.c2,n123,'rows');

            numEdges = size(obj.Edges,1);
                       
            Op1 = Ops(obj.Edges.o1);
            Op2 = Ops(obj.Edges.o2);
            S2 = SuperCellOps(cellindex);
            r1 = r(:,obj.Edges.a1);
            r2 = r(:,obj.Edges.a2);
            
            for j=1:numEdges
                r1(:,j) = Op1(j)*r1(:,j);
                r2(:,j) = S2(j)*Op2(j)*r2(:,j);
            end
            
            r1 = B*r1; % convert back to cartesian coordinates
            r2 = B*r2; 
            
            r1 = r1';
            r2 = r2';
            
        end
        
        function edgeMat = edgeMatrix(obj)
            [n1,n2,n3] = obj.G_n.grid();
            n123 = [n1(:),n2(:),n3(:)];
            [~,cellindex] = ismember(obj.Edges.c2,n123,'rows');

            numOps = numel(obj.Cell.UnitCellOperators);
            numAtoms = numel([obj.Cell.AsymmetricUnit.x]);
            numEdges = size(obj.Edges,1);

            % Order: all atoms of ASU1, then all atoms of ASU2, etc
            ao1 = sub2ind([numAtoms,numOps],obj.Edges.a1, obj.Edges.o1);
            ao2 = sub2ind([numAtoms,numOps],obj.Edges.a2, obj.Edges.o2);

            % group indices by cell index
            ao2Cell = cell(obj.G_n.N);
            edgeID = cell(obj.G_n.N);
            for n=1:prod(obj.G_n.N)
                isCell = cellindex==n;
                ao2Cell{n} = ao2(isCell);
                edgeID{n} = find(isCell);
            end

            % define a function to calculate the edge matrix, for edges
            % connecting nodes i and j
            edgeMatFun = @(e,j) sparse(e,j(:)',ones(1,numel(j)),... % values
                numEdges,numOps*numAtoms);
            
            edgeMat = cellfun(@(e,j) -1*edgeMatFun(e,j),edgeID,ao2Cell,'Uni',0);
            edgeMat{2,2,2} = edgeMat{2,2,2} + edgeMatFun(1:numEdges,ao1);
        end
    end
end