FS0:
cls
if exist run then
  rm run
  sct\SCT -s uboot.seq
else
  sct\SCT -c
endif
sct\SCT -g result.csv
echo Test results are in Report\result.csv
echo DONE - SCT COMPLETED
reset -s
