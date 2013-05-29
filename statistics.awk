BEGIN{
	min = 1000;
	max = 0;
    c = 0;
    var2 = 0;
}
/^[0-9]/{
	for(i=0;++i<=NF;){
		min=($i>min)?min:$i;		# Current minimum
		max=($i>max)?$i:max;		# Current maximum
		sum += $i;			# Running sum of values
		sum2 += $i * $i;			# Running sum of squares
		a[c]=$i;
		c++
	}
}

END{
	#printf("min: %s, max: %s\n",min,max);
	#printf("sum: %s\n",sum);
	var=((sum*sum) - sum2)/(c);
	mean = sum/c;
	for(i=0;i<c;i++){
		var2+=(mean-a[i])^2;
        #printf("%s:%s:%s:%s\n",a[i],a[i]^2,mean-a[i],var2);
	}
	var2=var2/c;
	#printf("mean: %s\n", mean);
	#printf("variance: %s\n",var);
	#printf("variance2: %s\n",var2/c);
	#printf("standard deviation: %s\n", sqrt(var));
	if(top == "yes")
		printf("TEST\tMIN\tMAX\tMEAN\tVAR\tS.DEV\n");
	printf("%s\t%s\t%s\t%.2f\t%.2f\t%.2f\n",name,min,max,mean,var2,sqrt(var2));
}
