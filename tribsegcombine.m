function [combinedsegs] = tribsegcombine(segcells,startindex,endindex)

    idx = [startindex:endindex];
    n = numel(idx);
    
    % Initialize Class
    combinedsegs = trib;
    
    for i = 1:n
        if i == 1
            t = [segcells{idx(i)}.t - segcells{idx(i)}.t(1)];
            s = [segcells{idx(i)}.s];
            nf = [segcells{idx(i)}.nf];
            ff = [segcells{idx(i)}.ff];
            fc = [segcells{idx(i)}.fc];
            d = [segcells{idx(i)}.d];
            st = [segcells{idx(i)}.st];
            speedseg = segcells{idx(i)}.speedseg;
            loadseg = segcells{idx(i)}.loadseg;
            sstart = segcells{idx(i)}.sstart;
            send = segcells{idx(i)}.send;
            th = segcells{idx(i)}.th;
            r = segcells{idx(i)}.r;
            nfeq = segcells{idx(i)}.nfeq;
            deq = segcells{idx(i)}.deq;
        else
            idxoffset = segcells{idx(i)}.sstart-numel(t) - 1;
            t = [t; segcells{idx(i)}.t - segcells{idx(i)}.t(1) + max(t) + nanmean(diff(segcells{idx(i)}.t))];
            s = [s; segcells{idx(i)}.s];
            nf = [nf; segcells{idx(i)}.nf];
            ff = [ff; segcells{idx(i)}.ff];
            fc = [fc; segcells{idx(i)}.fc];
            d = [d; segcells{idx(i)}.d];
            st = [st; segcells{idx(i)}.st];
            speedseg = [speedseg; segcells{idx(i)}.speedseg];
            loadseg = [loadseg; segcells{idx(i)}.loadseg];
            sstart = [sstart; segcells{idx(i)}.sstart - idxoffset];
            send = [send; segcells{idx(i)}.send - idxoffset];
        end
    end
    
    % Assign data to trib class
    combinedsegs.t = t;
    combinedsegs.s = s;
    combinedsegs.nf = nf;
    combinedsegs.ff = ff;
    combinedsegs.fc = fc;
    combinedsegs.d = d;
    combinedsegs.st = st;
    combinedsegs.speedseg = speedseg;
    combinedsegs.loadseg = loadseg;
    combinedsegs.sstart = sstart;
    combinedsegs.send = send;
    combinedsegs.th = th;
    combinedsegs.r = r;
    combinedsegs.nfeq = nfeq;
    combinedsegs.deq = deq;
    combinedsegs.calcparams;
    
    
end