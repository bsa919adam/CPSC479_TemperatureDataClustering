
#include <stdio.h>
#include <cuda.h>
#include <string.h>
#include <stdlib.h>

typedef struct day{
	int month;
	int date;
	int year;
	double high;
	double low;
	int cluster=-1;
	int previous=-1;
}day;

typedef struct center{
	int x;
	int y;
}center;


__global__ void setCenters(int* a) {
	
	int N=0;
	for( int i=0; i< N; i++){
		a[blockIdx.x * N + threadIdx.x] += a[blockIdx.x * N + i] * a[i * N + threadIdx.x];
	}
	
}

__global__ void kluster(day* data, day* centers, day ** clusters){


}

int main(int  argc, char *argv[]) {
    printf("begin checks\n");
    if(argc < 3){ //checcks for proper number of Args
		printf("Missing Arguments");
		return 1;
    }
    int k=atoi(argv[1]);
    if(k <1){ //checks that k value is greater than 1
		printf("invalid number of Centers");
		return 1;
    }
    FILE *fp;
    fp=fopen(argv[2], "r");
    if(fp==NULL){ //chechs that the file opened properly
		perror("Failed to open file:");
		return 1;
    }
    day * data;
    char c=' ';
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
    }
    day * d_data;
    //declares data for device
    cudaMalloc((void **)&d_data, sizeof(struct day)*numDays);
    cudaMemcpy(d_data, data, sizeof(struct day)*numDays);
  
    

    
       
 // cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);
    

    // Cleanup
     
    cudaFree(d_data);
    free(data); 
    return 0;
}
