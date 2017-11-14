function [] = plotTRIBrawdata(filename,timemins,speedmms,normalforceN,frictionforceN,frictioncoefficient,deformationum)
%%
figure
timemins = timemins - timemins(1);
yyaxis left
ptd = plot(timemins,-1*deformationum,'.')
ylabel('Deformation (\mum)')
xlabel('Time (minutes)')
yyaxis right
plot(timemins,frictioncoefficient,'.')
ylabel('Friction Coefficient')
ylim([0 .5])
ti = title(filename,'Interpreter','none')

figure
timemins = timemins - timemins(1);
yyaxis left
ptd = plot(timemins,-1*deformationum,'.')
ylabel('Deformation (\mum)')
xlabel('Time (minutes)')
yyaxis right
plot(timemins,normalforceN,'.')
ylabel('Normal Force (N)')
ti = title(filename,'Interpreter','none')


end