
#include <stdio.h>
#include <cuda.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
//use high as x value low as y for clustering
typedef struct day{
	int month;
	int date;
	int year;
	double high;
	double low;
	int cluster;
}day;

typedef struct center{
	double x;
	double y;
}center;


__global__ void setCenters(day* data, center* centers, int k, int numDays) {
	__shared__ int nums[3];

	int * avgx =nums;
	int * avgy =&nums[1];
	int * n=&nums[2];
	*avgx=0;
	*avgy=0;
	*n=0;
	int i =0;
	int index;	
	while((index=threadIdx.x + blockDim.x*i) < numDays){
		if(data[index].cluster==blockIdx.x){
			atomicAdd(n, 1);
			atomicAdd(avgx, (int)data[index].high);
			atomicAdd(avgy, (int)data[index].low);
			
		}
		
		i++;
	}
	__syncthreads();
	if(threadIdx.x ==0){
		centers[blockIdx.x].x=(double)(*avgx)/(double)(*n);
		centers[blockIdx.x].y=(double)(*avgy)/(double)(*n);
	}
	
}

__global__ void cluster(day* data, center* centers, int k, int numDays, int * s){
	int numT=gridDim.x*blockDim.x;
	int i=0;
	int index;
	int cluster;
	*s=0;
	while((index=threadIdx.x +blockIdx.x * blockDim.x+ numT*i) < numDays){
		double min=1000;
		for( int j=0; j< k; j++){
			double x=data[index].high-centers[j].x;
			x=x*x;
			double y=data[index].low-centers[j].y;
			y=y*y;
			double dist=sqrt(x+y);
			if(dist< min){
				min=dist;
				cluster=j;
				
			}		
		}
		if(data[index].cluster!=cluster){
			atomicAdd(s, 1);
			data[index].cluster=cluster;
		}
		i++;
	} 
}
__global__ void processData(day* data, int * month_data, int k, int numDays){
	int i=0;
	int month_index = blockIdx.x * 12 + threadIdx.x; //index for month_data
	int data_index;//index for data
	int month = threadIdx.x + 1;//month to look for
	int cluster = blockIdx.x;//cluster to look for
	
	while((data_index = threadIdx.y + blockDim.y * i++) < numDays){
	
		if((data[data_index].cluster == cluster) && (data[data_index].month == month) ){
			atomicAdd(&month_data[month_index], 1);
		}
		
	}
}
int main(int  argc, char *argv[]) {
    printf("begin checks\n");
    if(argc < 3){ //checcks for proper number of Args
			printf("Missing Arguments");
			return 1;
    }
    int k=atoi(argv[1]);
    if(k <1){ //checks that k value is greater than 1
			printf("invalid number of Clusters");
			return 1;
    }
    FILE *fp;
    fp=fopen(argv[2], "r");
    if(fp==NULL){ //chechs that the file opened properly
			perror("Failed to open file:");
			return 1;
    }
    day * data;
    data=(day*)malloc(sizeof(struct day));
    while((fgetc(fp))!='\n'){}//getting rid of the title line of the file
    
    int numDays=0;
    int high=-1;
    int low;
    int date;
    int month;
    int year;
    char  station[15];
    while(fscanf(fp,"%[^,],%d/%d/%d,%d,%d",station,&month, &date, &year, &high, &low)==6){//populates data from file
			numDays++;
			data=(day*)realloc(data, sizeof(struct day) * numDays);
			data[numDays-1].date=date;
			data[numDays-1].high=high;
			data[numDays-1].low=low;
			data[numDays-1].month=month;
			data[numDays-1].year=year;
			data[numDays-1].cluster=-1;
		}
		
		fclose(fp);//close file
		
    //declares data for device
    day * d_data;
    cudaMalloc((void **)&d_data, sizeof(struct day)*numDays);
    cudaMemcpy(d_data, data, sizeof(struct day)*numDays, cudaMemcpyHostToDevice);
    
    //create centers 
    center * centers;
    centers=(center*)malloc(sizeof(struct center)* k);
    for(int i=0; i<k; i++){//initilize centers to random data points
			centers[i].x=data[numDays/(i+2)].high;
			centers[i].y=data[numDays/(i+2)].low;

    } 
    
    //create centers for device
    center * d_centers;
    cudaMalloc((void **)&d_centers, sizeof(struct center) *k);
    cudaMemcpy(d_centers, centers, sizeof(struct center) *k, cudaMemcpyHostToDevice);
    
    int temp = 1093; //random number non zero number
    int * s=&temp;

    int * d_s;//variable to count how many data points change clusters between iterations
    cudaMalloc((void **)&d_s, sizeof(int));
    
    
    while(*s>0 ){
	  	*s=0;//reset s value
			int numB=numDays/512;

			cluster<<<numB, 512>>>(d_data, d_centers, k, numDays, d_s);//cluster data
		
			cudaMemcpy(s, d_s, sizeof(int), cudaMemcpyDeviceToHost);//retrieve d_S value from device
			
			if(*s>0){//compute new centers if any clusters changed
				int numT=((numDays/k)/32)*32; //assigns highest 
				numT>512 ? numT=512 : numT=numT;//checks that numt doesn't exceed 512
				
				setCenters<<<k, numT>>>(d_data, d_centers, k, numDays);
			
				/*cudaMemcpy(centers, d_centers, sizeof(struct center)*k, cudaMemcpyDeviceToHost);
				for( int h=0; h<k; h++){
					printf("x=%f y=%f\n", centers[h].x, centers[h].y);	
				}*/
			}	
		}
		//copy data back to device for printing
    cudaMemcpy(data, d_data, sizeof(struct day)*numDays, cudaMemcpyDeviceToHost);
		//open file for output
		fp=fopen("output.csv", "w");
		
		//print data to output in csv format
		for(int i=0; i<k; i++){
			fprintf(fp, "Cluster %d,Center,x=%f, y=%f\nDate,High,Low\n", i+1, centers[i].x, centers[i].y);
			for(int j=0; j<numDays; j++){
				if(i==data[j].cluster){
					fprintf(fp, "%d/%d/%d,%f,%f,%d\n", data[j].month, data[j].date, data[j].year, data[j].high,data[j].low, data[j].cluster);
				}
			}
			fprintf(fp,"\n\n");
    }
		//pointer to single dimensional array that is to 
		//hold summary of many days of each month are in each
		int * month_data;
		month_data=(int*)malloc(k*12*sizeof(int));
		int * d_month_data;//device copy
		cudaMalloc((void **)&d_month_data, k*12*sizeof(int) );
		
		dim3 threads(12, 32);
		processData<<<k, threads>>>(d_data, d_month_data, k, numDays );
		cudaMemcpy(month_data, d_month_data, k * 12 *sizeof(int), cudaMemcpyDeviceToHost);
		fprintf(fp, "Cluster,JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC\n");
		printf("%6s%5s%5s%5s%5s%5s%5s%5s%5s%5s%5s%5s%5s\n","Cluster","JAN", "FEB", "MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC");
		for( int i = 0; i< k; i++){
			fprintf(fp, "%d", i+1);
			printf("%6d", i+1);
			for( int j = 0; j < 12; j++){
				fprintf(fp, ",%d",month_data[i * 12 + j]);
				printf("%5d",month_data[i * 12 + j]);
			}
			fprintf(fp, "\n");
			printf("\n");
		}

    // Cleanup
    cudaFree(d_centers);
    cudaFree(d_s); 
		cudaFree(d_data);
		cudaFree(d_month_data);
    free(data); 
    // free(s);
		free(centers);
		free(month_data);
    return 0;
}
