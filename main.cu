
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
}day;



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
    if(argc < 3){
	printf("Missing Arguments");
	return 1;
    }
    printf("check2\n");
    int k=atoi(argv[1]);
    if(k <1){
	printf("invalid number of Centers");
	return 1;
    }
    printf("check3\n");
    FILE *fp;
    fp=fopen(argv[2], "r");
    if(fp==NULL){
	perror("Failed to open file:");
	return 1;
    }
    printf("checks done\n");
    day * data;
    char c=' ';
    data=(day*)malloc(sizeof(struct day));
    printf("starting line skip\n");
    while((c=fgetc(fp))!='\n'){//getting rid of the title line of the file
	//printf("%c", c);

    }
    printf("line skipped\n");
    int numDays=0;
    int high=-1;
    int low;
    int date;
    int month;
    int year;
    char  station[15];
    while(fscanf(fp,"%[^,],%d/%d/%d,%d,%d",station,&month, &date, &year, &high, &low)==6){
	numDays++;
	data=(day*)realloc(data, sizeof(struct day) * numDays);
	data[numDays-1].date=date;
	data[numDays-1].high=high;
	data[numDays-1].low=low;
	data[numDays-1].month=month;
	data[numDays-1].year=year;
	printf("%d\n", numDays);
    }
    printf("%e\n", data[0].high);
    printf("%e\n", data[numDays-1].high);
    printf("%d\n", numDays);

    
 //   cudaMalloc((void **)&d_a, size);
    
   // cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);

    
       
 // cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);
    

    // Cleanup
     
   // cudaFree(d_a);
    free(data); 
    return 0;
}
