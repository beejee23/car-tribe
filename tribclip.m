function [objout] = tribclip(objin,startindex,endindex)
% Segment a portion of a tribology data file by giveing the start and end
% index of the input data tribology file
    objout = trib;
    objout.filename = objin.filename;
    objout.th = objin.th;
    objout.r = objin.r;
    objout.nfeq = objin.nfeq;
    objout.deq = objin.deq;
    timesub = objin.t(startindex:endindex);
    objout.t = timesub;
    objout.s = objin.s(startindex:endindex);
    objout.nf = objin.nf(startindex:endindex);
    objout.ff = objin.ff(startindex:endindex);
    objout.d = objin.d(startindex:endindex);
    objout.speedseg = objin.speedseg;
    if objout.speedseg == 0
        objout.fc = zeros(size(objout.t));
    else
        objout.fc = objin.fc(startindex:endindex);
    end
    objout.loadseg = objin.loadseg-startindex + 1;
    objout.sstart = objin.sstart-startindex + 1;
    objout.send = objin.send-startindex + 1;
    objout.calcparams;
end