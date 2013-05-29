#get-mean-min-max.awk
#You must define COL with option -v of awk
{
total+=$COL;
count+=1
}

END {
#print total/counot
avg=total/count
if(avg==0)
	print 0
else
	printf("%.2f\n",total/count);
}
