% This script provides code needed to reproduce figures presented in the paper 'How directed is a directed network' [1]
% It makes use of some functions provided in Trophic Analysis Toolbox freely available here:
% https://github.com/BazilSansom/Trophic-Analysis-Toolbox
% The necessary data files for running this script are provided for download in this repository and references and links for
% obtaining the data are also provided both here and in the paper.
% Please use freely any of these materials. If you use any of these materials in published work or working/discussion papers, 
% we'd love to hear about your work, and please cite the below paper [1].
%
% Contact:
% bazil.sansom@warwick.ac.uk
%
% Reference:
% [1] MacKay RS, Johnson S, Sansom B. 2020 How directed is a directed network? R. Soc. Open Sci. 7: 201138.
% http://dx.doi.org/10.1098/rsos.201138


%%%%%%%%%%%%%% Fig.1: Ythan estury food web  %%%%%%%%%%%%%%%%%%%%%%%%

% Data for this figure were downloaded from [48] (see paper) and can be accessed from: 
% https://datadryad.org/stash/dataset/doi:10.5061/dryad.1mv20r6. 

% Load data and create graph object
% Ythan estury food web data were obtained from 
load('Ythan.mat')
G=digraph(Ythan);

% Extract largest weakly connected component and obtain adjacency matrix
[bin,binsize] = conncomp(G,'Type','weak');
idx = binsize(bin) == max(binsize);
SG = subgraph(G, idx);
E=table2array(SG.Edges(:,1));
A=edgelist2adj(E);
A=A';

% Obtain new trophic levels and incoherence
[h,F0,~] = incoherence(A); % Obtain new levels (Eq.2.6) and F0 (Eq.2.7)

% Plot network according to new trophic levels
G=digraph(A);
figure
p=plot(G,'layout','layered');
xdata=get(p,'XData');
close
figure(1)
g=plot(G,'XData',xdata,'YData',h,'EdgeColor',[0.3 0.3 0.3]);
g.NodeLabel = {};
highlight(g,1:size(A,1),'NodeColor','b','MarkerSize',6)
set(gca,'XTick',[],'XLabel',[]);
ylabel('levels')
xlabel(['incoherence=',num2str(round(F0,2))])
title('Ythan estuary food web')


%%%%%%%%%%%%%%% Fig.2: Inter-industrial flows in the USA and Saudi economies  %%%%%%%%%%%%%%%%%%%%%%%%%

clear all

% The data used to produce figures 2 and 3 are from the OECD Input-Output Tables 
% described and available here: 
% http://www.oecd.org/sti/ind/input-outputtables.htm, from the OECD website. 

% A seperate compiler for this data is provided (filename. Give option to run). 
% Here just upload precompiled data files.
load('NATIODOMIMP_nets.mat')
load('NATIODOMIMP_states.mat')
load('NATIODOMIMP_industry_labels.mat')
load('NATIODOMIMP_industries.mat')

IO=NATIODOMIMP_nets;
COUNTRY=NATIODOMIMP_states;
indust=NATIODOMIMP_industry_labels;

idx=[58, 49]; % US and Saudi

for j=1:2
    
i=idx(j);
    
io=IO(:,:,i,end); % end = year 2015

node_weight=sum(io,1)+sum(io,2)';
node_weight=node_weight./sum(node_weight);
idx2=node_weight>=0.025;
sum(idx2)
mks=node_weight(idx2);

io2=io(:,logical(idx2));
io2=io2(logical(idx2),:);
ind2=indust(logical(idx2),1);

[h,Fmin,~,~] = incoherence_gen(io2);

G=digraph(io2);
G.Nodes.Name=table2array(ind2);

try
    k = findnode(G,'Accomodation and food services');
    G.Nodes.Name{k} = 'Accom & Food Services';
end

k = findnode(G,'Healthcare, socialwork');
G.Nodes.Name{k} = 'Health & social care';
k = findnode(G,'Transportation, storage');
G.Nodes.Name{k} = 'Transport, storage';

figure
p=plot(G,'layout','force');
xdata=get(p,'XData');
close

figure(2)
subplot(2,1,j)
LWidths = 5*G.Edges.Weight/max(G.Edges.Weight);
p=plot(G,'XData',xdata,'YData',h,'NodeLabel',G.Nodes.Name,'LineWidth',LWidths,'ArrowSize',LWidths*5,'MarkerSize',(mks*100),'EdgeColor',[0.7 0.7 0.7],'NodeColor','b','NodeFontSize',9);
set(gca,'XTick',{})
ylabel('levels')
xlabel(['incoherence=',num2str(round(Fmin,2))])
title(COUNTRY{i})

end

subplot(2,1,1)
title('US input-output network')
subplot(2,1,2)
title('Saudi input-output network')


%%%%%%%%%%% Fig.3: Mean levels of different sectors in natioal IO nets. %%%%%%%%%%%%%

clear all

% Load data or run "Build_IO_nets_OECD_data" (both saved to directory)

load('NATIODOMIMP_nets.mat')
load('NATIODOMIMP_states.mat')
load('NATIODOMIMP_industry_labels.mat')
load('NATIODOMIMP_industries.mat')

IO=NATIODOMIMP_nets;
COUNTRY=NATIODOMIMP_states;
indust=NATIODOMIMP_industry_labels;
nCountries=size(COUNTRY,1);
nIndustries=size(IO(:,:,1,end),1);

% Obtain heights

del=zeros(0);

for i=1:nCountries
    
    io=IO(:,:,i,end);
    try % Some (3) countries have unconnected industries.. rather than dropping industries I drop these countries
        [H(:,i),F(i),~,~] = incoherence_gen(io,'h0','wm');
        country{i,1}=COUNTRY{i};
    catch
        del=[del;i];
    end
  
end

% Drop three economies with limited data.
for i=size(del,1):-1:1
    
    H(:,del(i))=[];
    F(del(i))=[];
    country(del(i),:)=[];
    
end


% Obtain means and sort
H4sort=[H,median(H,2)];
[H_sorted, idx]= sortrows(H4sort,size(H4sort,2));
names=table2array(indust);
names=names(idx);

% Plot results
figure(3)
boxplot(H_sorted','Labels',names,'LabelOrientation','inline')
title(['trophic levels of different sectors in IO nets for ', num2str(size(country,1)),' economies'])
ylabel('levels')
xlabel('sectors')

%%%%%%%%%%%   Fig.4: yeast transcription regulatory network   %%%%%%%%%%%%%%%%%

clear all

% The data for figure 4 were downloaded from [20] here: 
% https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2736650/.

% Upload data and construct adjacency matrix
load('yeast.mat')  % formatted as edgelist using sting IDs for nodes

% Classifying node roles
TF=unique(yeast(:,1)); % transcriptino factors
TG=unique(yeast(:,2)); % target genes
dual=intersect(TF,TG); % dual role
TF_unique=DeleteDuplicates([TF;dual],'str'); % Non dual TF

% Create graph object from sting ID edgelist
G=digraph(yeast(:,1),yeast(:,2));
nodes=table2array(G.Nodes);
in=indegree(G);
out=outdegree(G);

% Create numerical adjacency matrix from graph object
[~,e]=tickers2numbers(yeast,nodes);
A=edgelist2adj(e);

% Obtain new trophic levels (Eq.) and incoherence (Eq.)
[h,Fmin,~,~]=incoherence(A);


% Plot the network

figure(4)

% First using standard force directed layout
subplot(1,2,1)
p=plot(G,'layout','force','EdgeColor',[0.6 0.6 0.6],'NodeColor','b');
highlight(p,TF_unique,'NodeColor','r');
c=[1.0000    1.0000    0.0667]; 
highlight(p,dual,'NodeColor',c);

% Then using new trophic levels
subplot(1,2,2)
xdata=rand(length(h),1);
p=plot(G,'XData',xdata,'YData',h,'EdgeColor',[0.6 0.6 0.6],'NodeColor','b');
highlight(p,TF_unique,'NodeColor','r');
highlight(p,dual,'NodeColor',c);
set(gca,'XTick',{})
xlabel(['Incoherence=',num2str(round(Fmin,2))])
ylabel('levels')


%%%%%%%%%%%    Figure 5: Global book translation network    %%%%%%%%%%%%

clear all

% Upload data and build weighted adjacency matrix

% The data for figure 5 published in [25] were downloaded from 
% http://language.media.mit.edu/data (navigate from
% http://language.media.mit.edu)
% Upload precompiled file

load('book_labels.mat')
list=book_labels;
[col1, col2, col3, header,raw ]= tsvread('books_edges.tsv','SourceLanguageName','TargetLanguageName','Coocurrences');
raw(1,:)=[];
G=digraph(raw(:,1),raw(:,2));
nodes=table2array(G.Nodes);             % list of node names
[V,E]=tickers2numbers(raw(:,1:2),nodes);% convert to numercical IDs
E(:,3)=str2double(raw(:,3));            % weights
A=edgelist2adj(E);                      % weighted adjacency matrix


% Obtain new trophic levels and incoherence
[h,Fmin,~,~]=incoherence(A);


% PLot network according to new levels
G=digraph(A);
LWidths = G.Edges.Weight/max(G.Edges.Weight);
td=sum(A,1)+sum(A,2)';
td=td./sum(td);

figure(5)
p=plot(G,'layout','layered');
xdat=get(p,'XData');
p=plot(G,'XData',xdat,'YData',h,'LineWidth',LWidths*10,'ArrowSize',LWidths*10*4,'EdgeColor',[0.5 0.5 0.5],'NodeColor','b','NodeFontSize',9,'MarkerSize',td*100);
set(gca,'XTick',{})
xlabel(['Incoherence=',num2str(round(Fmin,2))])
ylabel('Levels')
title('Book translations between languages')

ID=zeros(size(list));

for i=1:size(list,1)
    [lang,idx]=vlookup(nodes,list{i,1},1,1);
    ID(i)=idx;
end

labelnode(p,ID,list)

% Color code edges according to their direction (with or against vertical
% flow)

% Get height differences d=h_t-h_s on each edge
%   d<0 source higher than targert: down arrow
%   d>0 source smaller than targer: up arrow

nEdges=size(E,1);
d=zeros(nEdges,1);

for i=1:nEdges  
    d(i)=h(E(i,2))-h(E(i,1)); 
end

% Get edge indices for all up and all down arrows

up_edge=d>0;
E_up=E(up_edge,:);
down_edge=d<0;
E_down=E(down_edge,:);

E_id_up=zeros(size(E_up,1),1);

for i=1:size(E_up,1)
    [E_id_up(i),~] = findedge(G,E_up(i,1),E_up(i,2));
end

E_id_down=zeros(size(E_down,1),1);

for i=1:size(E_down,1)
    [E_id_down(i),~] = findedge(G,E_down(i,1),E_down(i,2));
end

highlight(p,'Edges',E_id_down,'EdgeColor',[0.9412    0.6471    0.6471])
highlight(p,'Edges',E_id_up,'EdgeColor',[0.4235    0.6000    0.1725])


%%%%%%%%%%%  Fig.6 comparison new and standard levels for a toy sequential process  %%%%%%%%

clear all

net=[1,3; 2,3; 3,5; 4,5; 5,7; 6,7; 7,9; 8,9; 9,11; 10,11];
a=edgelist2adj(net);

[h,~,~]=incoherence(a);       % obtain new trophic levels
[l,~,~]=incoherence_stand(a); % obtain standard trophic levels

figure
p=plot(digraph(a));
xdat=get(p,'XData');
close

figure(6)
subplot(1,2,1)
plot(digraph(a),'XData',xdat,'YData',h+1,'EdgeColor','k','nodecolor','k');
set(gca,'XTick',[])
ylabel('new levels')

subplot(1,2,2)
plot(digraph(a),'XData',xdat,'YData',l,'EdgeColor','k','nodecolor','k');
ylabel('standard levels')
set(gca,'XTick',[])


%% Fig.7-10

% This data was compiled from Bloomberge LP and coule be provided wit Bloombergs permission, 
% or similar data could be compiled from Bloomberg.


%%%%%%%%%%%%%   Fig.11 Normality vs. F0 motifs  %%%%%%%%%%%%%%%%

clear all

ffl=[1,2; 1,3; 2,3];
fbl=[1,2; 2,3; 3,1];
chain=[1,2; 2,3];
motif_3=[1,2; 2,3; 3,1; 1,1];

g_ffl=digraph(ffl(:,1),ffl(:,2));
g_fbl=digraph(fbl(:,1),fbl(:,2));
g_chain=digraph(chain(:,1),chain(:,2));
g_motif_3=digraph(motif_3(:,1),motif_3(:,2));

W_fbl=edgelist2adj(fbl);
W_ffl=edgelist2adj(ffl);
W_chain=edgelist2adj(chain);
W_motif_3=edgelist2adj(motif_3);

v_fbl=normality(W_fbl);
v_ffl=normality(W_ffl);
v_3=normality(W_motif_3);
v_chain=normality(W_chain);


[~,F0_fbl,~]=incoherence(W_fbl);
[h_ffl,F0_ffl,~]=incoherence(W_ffl);
[~,F0_3,~]=incoherence(W_motif_3);
[h_chain,F0_chain,~]=incoherence(W_chain);

figure
p=plot(g_ffl,'layout','layered');
x_ffl=get(p,'XData');
close

figure
p=plot(g_chain,'layout','layered');
x_chain=get(p,'XData');
close

figure(11)

subplot(2,2,1)
plot(g_fbl,'EdgeColor','k','nodecolor','k','NodeLabel', {})
set(gca,'XTick',[])
set(gca,'YTick',[])
title('Feed back loop')
xlabel({['Normality=',num2str(round(v_fbl,2))],['Trophic incoherence=',num2str(round(F0_fbl,2))]})

subplot(2,2,3)
plot(digraph(W_motif_3),'EdgeColor','k','nodecolor','k','NodeLabel', {})
set(gca,'XTick',[])
title('Motif 3')
xlabel({['Normality=',num2str(round(v_3,2))],['Trophic incoherence=',num2str(round(F0_3,2))]})

subplot(2,2,2)
plot(g_chain,'XData',x_chain,'YData',h_chain,'EdgeColor','k','nodecolor','k','NodeLabel', {})
set(gca,'XTick',[])
title('Chain')
xlabel({['Normality=',num2str(round(v_chain,2))],['Trophic incoherence=',num2str(round(F0_chain,2))]})
ylabel('Trophic level')

subplot(2,2,4)
plot(g_ffl,'XData',x_ffl,'YData',h_ffl,'EdgeColor','k','nodecolor','k','NodeLabel', {})
set(gca,'XTick',[])
title('Feed forward loop')
xlabel({['Normality=',num2str(round(v_ffl,2))],['Trophic incoherence=',num2str(round(F0_ffl,2))]})
ylabel('Trophic level')

%% Fig.12-13

% C code file











