#include "C:/Program Files/MATLAB/R2022b/extern/include/mex.h"
#include "C:/Program Files/MATLAB/R2022b/toolbox/parallel/gpu/extern/include/gpu/mxGPUArray.h"
#include <chrono>

#define timer std::chrono::high_resolution_clock
#define timertime std::chrono::high_resolution_clock::time_point
#define timecast std::chrono::duration_cast<std::chrono::microseconds>
#define timesecs std::chrono::microseconds

//a convenient structure
typedef struct sizes {
            size_t i;
            size_t j;
            size_t k;
            size_t imax;
            size_t jmax;
            size_t kmax;
            size_t xysize;
            size_t M_numel;
} sizes;

//kernel Creates a beamformed image array on the GPU.
__global__ void DAS_Index_GPU(const unsigned int* indmat, const double* rfptr, double* reconptr, struct sizes sz) {    
    // define device variables
    int x = threadIdx.x + blockDim.x * blockIdx.x;
    int y = threadIdx.y + blockDim.y * blockIdx.y;
    int z = threadIdx.z + blockDim.z * blockIdx.z;

    //memory index
    if(z < sz.kmax && y < sz.jmax && x < sz.imax) {
        int moderate_index = x + y * sz.imax;
        int final_index = *(indmat + moderate_index + z * sz.xysize);
        *(reconptr + moderate_index) += *(rfptr + final_index);
    }
}

//wrapper into MATLAB
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {

    mxInitGPU();
    
    const char*         const errId = "parallel:gpu:gpudasindex:InvalidInput"; //error message
    //input variables
    const mxGPUArray*   M;
    const mxGPUArray*   rfdata;
    //derived variables
    const mwSize*       dims_3;
    
    //output variables
    mxGPUArray*         img_2d;
    mxGPUArray*         img_3d;
    double*             img3_dvc;
    double*             img2_dvc;

    //Input Error handling
    if (nrhs!=5) {
        mexErrMsgIdAndTxt(errId, "Expected 5 inputs: M, rfdata, thread/block x, thread/block y, thread/block z");
    } 
    if (nlhs!=1 && nlhs!=0) {
        mexErrMsgIdAndTxt(errId, "Invalid number of output arguments, only 1 allowed.");
    }
    if (!mxIsGPUArray(prhs[0])) {
        mexErrMsgIdAndTxt(errId, "Index Matrix M must be a GPU array.");
    } 
    if (!mxIsGPUArray(prhs[1])) {
        mexErrMsgIdAndTxt(errId, "rfdata must be a GPU array.");
    } 
    if (!mxIsDouble(prhs[2]) || !mxIsDouble(prhs[3]) || !mxIsDouble(prhs[4])) {
        mexErrMsgIdAndTxt(errId, "Block dimensions must be of datatype 'double'");
    }

    // Load mx gpu array objects
    M       = mxGPUCreateFromMxArray(prhs[0]); 
    rfdata  = mxGPUCreateFromMxArray(prhs[1]);
    dims_3  = mxGPUGetDimensions(M);

    const mwSize xysz[2] = {dims_3[0], dims_3[1]};

    sizes sz1 = {
    //define block and thread sizes
    (unsigned long long)*(double*)mxGetData(prhs[2]),
    (unsigned long long)*(double*)mxGetData(prhs[3]),
    (unsigned long long)*(double*)mxGetData(prhs[4]),
    
    //Get the number of x/y/z threads
    dims_3[1],
    dims_3[0],
    dims_3[2],
    dims_3[0] * dims_3[1],
    dims_3[2] * dims_3[0] * dims_3[1]
    };

    //round up to the nearest integer of the dimension length divided by the thread   dimension
    int blockx          = sz1.imax/sz1.i + (sz1.imax % sz1.i != 0);
    int blocky          = sz1.jmax/sz1.j + (sz1.jmax % sz1.j != 0);
    int blockz          = sz1.kmax/sz1.k + (sz1.kmax % sz1.k != 0);

    //grid and block 3D arrays
    dim3                grid(sz1.i, sz1.j, sz1.k);
    dim3                block(blockx, blocky, blockz);
    size_t total_threads = sz1.i * sz1.j * sz1.k;

    const mwSize* mnum   = &sz1.M_numel;
    // const mwSize* nnum   = &sz1.xysize;

    //Verify that inputs are correct classes before extracting the pointer.
    if (mxGPUGetClassID(M) != mxUINT32_CLASS) {
        mexErrMsgIdAndTxt(errId, "Index Matrix M must have class 'uint32'");
    }
    if (mxGPUGetClassID(rfdata) != mxDOUBLE_CLASS) {
        mexErrMsgIdAndTxt(errId, "rfdata must have class 'double'");
    } 
    if (total_threads > 1024 || total_threads <= 1) {
        mexErrMsgIdAndTxt(errId, "Block dimensions product must be between 1 and 1024");
    }

    // Extract a pointer to the input data on the device.
    const unsigned int* M_dvc = (const unsigned int*) (mxGPUGetDataReadOnly(M));
    const double* rfdata_dvc  = (const double*)       (mxGPUGetDataReadOnly(rfdata));

    // Create a GPUArray to hold the result and get its underlying pointer.
    img_2d = mxGPUCreateGPUArray(2, xysz, mxDOUBLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
    img2_dvc = (double*)(mxGPUGetData(img_2d));

    timertime start8 = timer::now();
    // Call the kernel
    DAS_Index_GPU<<<block, grid>>>(M_dvc, rfdata_dvc, img2_dvc, sz1);
    cudaDeviceSynchronize();

    timertime stop8 = timer::now();
    timesecs indexgpu = timecast(stop8 - start8);
    printf("Kernel Index: %d\n",indexgpu);
    
    //Get the result as a gpuArray
    plhs[0] = mxGPUCreateMxArrayOnGPU(img_2d); //takes about 38 microsecs

    //cleanup
    mxGPUDestroyGPUArray(M);
    mxGPUDestroyGPUArray(rfdata);
    mxGPUDestroyGPUArray(img_3d);
    mxGPUDestroyGPUArray(img_2d);
    //cleanup takes about 8 microsecs
}