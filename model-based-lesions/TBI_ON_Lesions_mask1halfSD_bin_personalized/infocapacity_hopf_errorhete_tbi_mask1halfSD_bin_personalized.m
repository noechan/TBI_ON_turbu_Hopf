function infocapacity_hopf_errorhete_tbi(s,condition)

rng(s);
measure='err_hete'; 

load('optG_tbi_mask1halfSD_bin_allsub_cond_1.mat')
%load('optG_tbi_mask1halfSD_bin_allsub_cond_2.mat')
%load('optG_tbi_mask1halfSD_bin_allsub_cond_3.mat')

for sbj=1:12
    if condition==1
        G=optG_tbicond1_sub(1,sbj); %OptG TBI ses1
    elseif condition==2
        G=optG_tbicond2_sub(1,sbj); %OptG TBI ses2
    elseif condition==3
        G=optG_tbicond3_sub(1,sbj);%OptG TBI ses3
    end


load(sprintf('results_f_diff_fce_cond%d_ON_tbi_personalized.mat',condition));
load(sprintf('empirical_spacorr_rest_cond_%d_ON_tbi_personalized.mat',condition));
load SClongrange.mat;
load schaefer_MK.mat;
load('lesion_mask_1andhalfSD_sub_N12.mat')

NPARCELLS=1000;
NR=400;
NRini=20;
NRfin=380;
NSUBSIM=100;


lambda=round(lambda,1);

rr=zeros(NPARCELLS,NPARCELLS);
for i=1:NPARCELLS
    for j=1:NPARCELLS
        rr(i,j)=norm(SchaeferCOG(i,:)-SchaeferCOG(j,:));
    end
end
range=max(max(rr));
delta=range/NR;

for i=1:NR
    xrange(i)=delta/2+delta*(i-1);
end

Isubdiag = find(tril(ones(NPARCELLS),-1));

C=zeros(NPARCELLS,NPARCELLS);

LAMBDA=[0.27 0.24 0.21 0.18 0.15 0.12 0.09 0.06 0.03 0.01];

NLAMBDA=length(LAMBDA);
C1=zeros(NLAMBDA,NPARCELLS,NPARCELLS);
[aux indsca]=min(abs(LAMBDA-lambda));
ilam=1;
for lambda2=LAMBDA
    for i=1:NPARCELLS
        for j=1:NPARCELLS
            C1(ilam,i,j)=exp(-lambda2*rr(i,j));
        end
    end
    ilam=ilam+1;
end

%%%
% Parameters of the data
TR=2;  % Repetition Time (seconds)

% Bandpass filter settings
fnq=1/(2*TR);                 % Nyquist frequency
flp = 0.008;                    % lowpass frequency of filter (Hz)
fhi = 0.08;                    % highpass
Wn=[flp/fnq fhi/fnq];         % butterworth bandpass non-dimensional frequency
k=2;                          % 2nd order butterworth filter
[bfilt,afilt]=butter(k,Wn);   % construct the filter
Isubdiag = find(tril(ones(NPARCELLS),-1));

% Parameters HOPF
Tmax=145;
omega = repmat(2*pi*f_diff_sub(sbj,:)',1,2); omega(:,1) = -omega(:,1); % CHANGED!!! Subject-specific intrinsic frequency
dt=0.1*TR/2;
sig=0.01;
dsig = sqrt(dt)*sig;

%%

lam_mean_spatime_enstrophy=zeros(NLAMBDA,NPARCELLS,Tmax);
ensspasub=zeros(NSUBSIM,NPARCELLS);
ensspasub1=zeros(NSUBSIM,NPARCELLS);


IClong=find(Clong>0);
for i=1:NPARCELLS
    for j=1:NPARCELLS
        C(i,j)=exp(-lambda*rr(i,j));
    end
    C(i,i)=0;
end
C(IClong)=Clong(IClong);

C=C.*squeeze(lesion_mask1halfSD_sub_N12(sbj,:,:)); % CHANGED!!! subject-specific lesion mask from tbi patients

factor=max(max(C));
C=C/factor*0.2;

for sub=1:NSUBSIM
    sub    
    wC = G*C;
    sumC = repmat(sum(wC,2),1,2);
    
    %% Hopf Simulation
    a=-0.02*ones(NPARCELLS,2);
    xs=zeros(Tmax,NPARCELLS);
    %number of iterations, 100 willk�hrlich, weil reicht in diesem Fall
    z = 0.1*ones(NPARCELLS,2); % --> x = z(:,1), y = z(:,2)
    nn=0;
    % discard first 2000 time steps
    for t=0:dt:2000
        suma = wC*z - sumC.*z; % sum(Cij*xi) - sum(Cij)*xj
        zz = z(:,end:-1:1); % flipped z, because (x.*x + y.*y)
        z = z + dt*(a.*z + zz.*omega - z.*(z.*z+zz.*zz) + suma) + dsig*randn(NPARCELLS,2);
    end
    % actual modeling (x=BOLD signal (Interpretation), y some other oscillation)
    for t=0:dt:((Tmax-1)*TR)
        suma = wC*z - sumC.*z; % sum(Cij*xi) - sum(Cij)*xj
        zz = z(:,end:-1:1); % flipped z, because (x.*x + y.*y)
        z = z + dt*(a.*z + zz.*omega - z.*(z.*z+zz.*zz) + suma) + dsig*randn(NPARCELLS,2);
        if abs(mod(t,TR))<0.01
            nn=nn+1;
            xs(nn,:)=z(:,1)';
        end
    end
    ts=xs';
    
    for seed=1:NPARCELLS
        ts(seed,:)=detrend(ts(seed,:)-mean(ts(seed,:)));
        signal_filt(seed,:) =filtfilt(bfilt,afilt,ts(seed,:));
        Xanalytic = hilbert(demean(signal_filt(seed,:)));
        Phases(seed,:) = angle(Xanalytic);
    end
    
    for i=1:NPARCELLS
        %%% enstrophy
        ilam=1;
        for lam=LAMBDA
            enstrophy=nansum(repmat(squeeze(C1(ilam,i,:)),1,Tmax).*complex(cos(Phases),sin(Phases)))/sum(C1(ilam,i,:));
            lam_mean_spatime_enstrophy(ilam,i,:)=abs(enstrophy);
            ilam=ilam+1;
        end
    end
    Rspatime=squeeze(lam_mean_spatime_enstrophy(indsca,:,:));
    ensspasub(sub,:)=(nanmean(Rspatime,2))';
    
    %%% Perturbation
    
    a=-0.02+0.02*repmat(rand(NPARCELLS,1),1,2).*ones(NPARCELLS,2);
    nn=0;
    for t=0:dt:((Tmax-1)*TR)
        suma = wC*z - sumC.*z; % sum(Cij*xi) - sum(Cij)*xj
        zz = z(:,end:-1:1); % flipped z, because (x.*x + y.*y)
        z = z + dt*(a.*z + zz.*omega - z.*(z.*z+zz.*zz) + suma) + dsig*randn(NPARCELLS,2);
        if abs(mod(t,TR))<0.01
            nn=nn+1;
            xs(nn,:)=z(:,1)';
        end
    end
    ts=xs';
    Rspatime1=zeros(NPARCELLS,Tmax);
    
    for seed=1:NPARCELLS
        ts(seed,:)=detrend(ts(seed,:)-mean(ts(seed,:)));
        signal_filt(seed,:) =filtfilt(bfilt,afilt,ts(seed,:));
        Xanalytic = hilbert(demean(signal_filt(seed,:)));
        Phases(seed,:) = angle(Xanalytic);
    end
    for i=1:NPARCELLS
        %%% enstrophy
        enstrophy=nansum(repmat(squeeze(C1(indsca,i,:)),1,Tmax).*complex(cos(Phases),sin(Phases)))/sum(C1(indsca,i,:));
        Rspatime1(i,:)=abs(enstrophy);
    end
    ensspasub1(sub,:)=(nanmean(Rspatime1,2))';
end

infocapacity=nanmean(nanstd(ensspasub1-ones(NSUBSIM,1)*nanmean(ensspasub)));
susceptibility=nanmean(nanmean(ensspasub1-ones(NSUBSIM,1)*nanmean(ensspasub)));

save(sprintf('Wtrials_%03d_%d_sub_%d_%s_ON_tbi_mask1halfSD_bin.mat',s,condition,sbj,measure),'infocapacity','susceptibility');
end