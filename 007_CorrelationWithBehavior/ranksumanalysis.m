% group A are people who made spatial errors.
groupA = [-1.361343
0.76106918
0.052343976
0.82022327
-0.53227168
0.57443422
0.60192442
0.46944901
-0.2045013
1.2338711
-0.19894299
-0.45878977
0.008323619
-0.65103513];

groupAlesion = [129994
3871
16970
13354
1270
23800
23595
124642
14672
15268
9046
102665
47252
80075];

% group B are people who did not make spatial errors.
groupB = [1.4117526
-0.45064747
1.4000604
1.1067605
0.77832764
1.9700941
0.2645953
1.0701181
0.4913528];

groupBlesion = [35443
83984
14179
666
51594
38635
23965
16135
166684];

AllData = [groupA;groupB];

[P,H,STATS] = ranksum(groupB,groupA,'alpha',.05,'tail','both');

x = groupB; y = groupA;
diffs = x - y';
hl = median(diffs(:));

nboot = 10000;
bootstat = zeros(nboot,1);

for b = 1:nboot
    xb = x(randi(numel(x), numel(x), 1));
    yb = y(randi(numel(y), numel(y), 1));
    bootstat(b) = median(xb - yb','all');
end

ci = prctile(bootstat, [2.5 97.5]);


for iteri = 1:10000

    scramdata = AllData(randperm(size(AllData,1)));
    tmpgroupA = scramdata(1:size(groupA,1));
    tmpgroupB = scramdata(size(groupA,1)+1:size(groupA,1)+size(groupB,1));
    
    [~,~,TMPSTATS] = ranksum(tmpgroupB,tmpgroupA,'alpha',.05,'tail','both');

    scramstats(iteri,1) = TMPSTATS.zval;

    %xb = x(randi(numel(x), numel(x), 1));
    %yb = y(randi(numel(y), numel(y), 1));
    bootstat(iteri,1) = median(tmpgroupB - tmpgroupA','all');
    clear TMPSTATS tmpgroupB tmpgroupA scramdata

end

ci = prctile(bootstat, [2.5 97.5]);

(STATS.zval - mean(scramstats)) / std(scramstats);


%% lesion analysis
[P,H,STATS] = ranksum(groupBlesion,groupAlesion,'alpha',.05,'tail','both');

x = groupBlesion; y = groupAlesion;
diffs = x - y';
hl = median(diffs(:));

nboot = 10000;
bootstat = zeros(nboot,1);

for b = 1:nboot
    xb = x(randi(numel(x), numel(x), 1));
    yb = y(randi(numel(y), numel(y), 1));
    bootstat(b) = median(xb - yb','all');
end

ci = prctile(bootstat, [2.5 97.5]);


for iteri = 1:10000

    scramdata = AllData(randperm(size(AllData,1)));
    tmpgroupA = scramdata(1:size(groupAlesion,1));
    tmpgroupB = scramdata(size(groupAlesion,1)+1:size(groupAlesion,1)+size(groupBlesion,1));
    
    [~,~,TMPSTATS] = ranksum(tmpgroupB,tmpgroupA,'alpha',.05,'tail','both');

    scramstats(iteri,1) = TMPSTATS.zval;

    clear TMPSTATS tmpgroupB tmpgroupA scramdata

end

(STATS.zval - mean(scramstats)) / std(scramstats);