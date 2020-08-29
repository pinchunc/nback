% ------------------------------------------
%    fractalmaker.m
%      by Shinya Yamamoto
%      last modified on 08/30/11 at AIST
% ------------------------------------------
% size and quality modifications by Ali  12/08/2011
%------------------------------------------------------------
clc; clear all; close all;


fractal_foldername='fractal_series';
disp('=======================================================')
disp('                 Fractal Maker                         ')
disp('=======================================================')
disp(' ')
[s, mess, messid] = mkdir(fractal_foldername);
rand('twister',sum(100*clock))


for series=[1:10]

    dirname=['.\',fractal_foldername,'\series' num2str(series)];
    [s, mess, messid] = mkdir(dirname);


    for stno=[0:999]
        if stno<10
            stimnum=['00' num2str(stno)];
        elseif stno<100
            stimnum=['0' num2str(stno)];
        else
            stimnum=num2str(stno);
        end


        kuikomisize=2;
        dekoboko=0.8;
        for typenum=[1:10]
            ok='n';
            while ok=='n'
                numofsuperimp=4;
                fill([15,-15,-15,15],[15,15,-15,-15],[0,0,0])
                hold on
                datamat=[];
                for sup=[1:numofsuperimp]
                    numofedge= 4+round(rand*6);
                    edgesize=numofsuperimp-sup+rand;
                    numofrecursion= 2+round(rand*3);
                    fracx=edgesize*cos(2*pi*[1:numofedge]/numofedge);
                    fracy=edgesize*sin(2*pi*[1:numofedge]/numofedge);
                    GAmat=[];
                    for k=[1:1:numofrecursion]
                        mx=(fracx([2:end 1])+fracx)/2;
                        my=(fracy([2:end 1])+fracy)/2;
                        dx= fracx([2:end 1])-fracx;
                        dy= fracy([2:end 1])-fracy;
                        theta=atan(dy./dx);
                        theta(find(dx<0))=theta(find(dx<0))+pi;
                        GA=kuikomisize*(rand-dekoboko);
                        fracx2=mx+GA*sin(theta);
                        fracy2=my-GA*cos(theta);
                        fracx=[fracx;fracx2];
                        fracx=fracx(:);
                        fracx=fracx';
                        fracy=[fracy;fracy2];
                        fracy=fracy(:);
                        fracy=fracy';
                        GAmat=[GAmat;GA];
                    end
                    col=rand(1,3);
                    fill(fracx([1:end 1]),fracy([1:end 1]),col)
                    hold on
                    plot(fracx([1:end 1]),fracy([1:end 1]),'Color',col)
                    axis square
                    axis([-numofsuperimp-1 numofsuperimp+1 -numofsuperimp-1 numofsuperimp+1])
                    datamat(sup).numofedge=numofedge;
                    datamat(sup).edgesize=edgesize;
                    datamat(sup).numofrecursion=numofrecursion;
                    datamat(sup).col=col;
                    datamat(sup).GA=GAmat;
                end
                axis([-5,5 -5,5])
                axis off
                %ok=input('ok? (y or n)','s');
                ok='y';
            end
            filename=['i' num2str(typenum) stimnum '.jpeg'];

            [s2, mess2, messid2] = mkdir([dirname,'\images']);
            set(gcf,'Position',[1003 802 500 500],'paperposition',[0 0 8 8]);set(gca,'PlotBoxAspectRatioMode','auto'); set(gca,'Position',[0 0 1 1]);
            print('-djpeg100','-r300',[dirname,'\images\',filename])

            filename2=['data' num2str(typenum) stimnum];

            [s3, mess3, messid3] = mkdir([dirname,'\data']);

            eval(['save ' [dirname,'\data\',filename2] ' datamat stimnum typenum numofsuperimp']);
            close all
            disp(['series' num2str(series) ', set:' stimnum ', obj:' num2str(typenum)])
        end
        disp('-------------------------')
    end
end
