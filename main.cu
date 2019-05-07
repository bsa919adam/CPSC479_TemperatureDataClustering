
#include <stdio.h>
#include <cuda.h>
#include <time.h>

#define N 32
__global__ void square(int* a) {
	
	
	for( int i=0; i< N; i++){
		a[blockIdx.x * N + threadIdx.x] += a[blockIdx.x * N + i] * a[i * N + threadIdx.x];
	}
	
}

void random_ints(int* arr, int row, int colum) {
    for (int a = 0; a < row; a++) {
	for( int b=0; b<colum; b++){
        	arr[a * N + b] = rand() % 100 + 1;
	}
    }
}

int main(void) {
    int *a;        // host copy of a
    int *d_a;    // device copy of a
    int size = N * N * sizeof(int);
    srand(time(NULL));
    printf("line 29 size=%d\n",size);
    // Alloc space for host copy of a and setup input values
    a = (int *)malloc(size); 
    random_ints(a, N, N);

    // Alloc space for device copies of a, b, c
    cudaMalloc((void **)&d_a, size);
    // Copy inputs to device
    cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);

    // Launch add() kernel on GPU with N blocks
    square<<<N,N>>>(d_a);
    // Copy result back to host
    cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);
    for (int i = 0; i < N; i++) {
	for(int j = 0; j< N; j++){
        	printf("a[%d][%d] = %d\n", i,j, a[i*N+j]);
	}
    }

    // Cleanup
    free(a); 
    cudaFree(d_a); 
    return 0;
    }
