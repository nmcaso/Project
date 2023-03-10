#include "mex.h"
#include <stdio.h>

struct DataSizes {
    size_t m_rows;                              // number of rows
    size_t m_cols;                              // number of columns
    size_t m_depth;                             // number of sensor elements
    size_t m_numel;                             // number of elements in index matrix
    size_t image_elements;                      // image elements
    size_t rf_rows;                             // rfdata number of rows
    size_t rf_cols;                             // rfdata number of columns
};

// DAS Function
void dasindex(unsigned int *M, double *rf, double* img_out, struct DataSizes sz)
{
    
    //memory indexing
    for (int ii = 0; ii < sz.m_depth; ++ii) {
        for(int jj = 0; jj < sz.image_elements; ++jj) {
            *(img_out + jj) += *(rf + *(M + jj + sz.image_elements * ii));
        }
    }

    //divide!
    for(int kk = 0; kk < sz.image_elements; ++kk) {
        *(img_out + kk) /= sz.m_depth;
    }
}

// Gatewy /MATLAB Wrapper function:
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Groom Inputs ------------------------------------------------------------
    if(nrhs!=2) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","Two inputs index matrix and rfdata required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nlhs","Too many output arguments.");
    }
    // make sure the first input argument is an array of unsigned int 32.
    if( mxIsComplex(prhs[0]) ||
        // !mxIsDouble(prhs[0]) ||
        // !mxIsUint64(prhs[0]) ||
        // !mxIsSingle(prhs[0]) || 
        !mxIsUint32(prhs[0]) ) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Unsupported index matrix datatype. Function currently supports: UInt32");
    }
    // ensure the second input argument is type double
    if( !mxIsDouble(prhs[1]) ||
        //!mxIsSingle(prhs[1]) || 
        mxIsComplex(prhs[1])) {
        ("MyToolbox:arrayProduct:notDouble","Input rfdata must be of datatype double or single (not complex)");
    }    

    // preallocate and setup variables ------------------------------------------------
    // mxClassID mcategory = mxGetClassID(prhs[0]);
    // mxClassID rcategory = mxGetClassID(prhs[1]);
    
    //to-do: support multiple classes of data.
    // switch (mcategory) {
    //     case mxUINT32_CLASS:
    //         unsigned int * M;
    //         M = (unsigned int*) mxGetPr(prhs[0]);
    //         break;
    //     case mxUINT64_CLASS:
    //         unsigned long int * M;
    //         M = (unsigned long int*) mxGetPr(prhs[0]);
    //         break;
    //     case mxSINGLE_CLASS:
    //         float * M;
    //         M = (float*) mxGetPr(prhs[0]);
    //         break;
    //     case mxDOUBLE_CLASS:
    //         double* M;
    //         M = (double*) mxGetPr(prhs[0]);
    //         break;
    //     default: break;
    // }

    // switch (rcategory) {
    //     case mx_SINGLE_CLASS:
    //         float * rfdata;
    //         rfdata = (float*) mxGetPr(prhs[1]);
    //         break;
    //     case mx_DOUBLE_CLASS:
    //         double * rfdata;
    //         rfdata = (double*) mxGetPr(prhs[1]);
    //         break;
    //     default: break;
    // }

    double * img;                               // beamformed image pointer
    unsigned int * M;                           // Index Matrix pointer
    double * rfdata;                            // rfdata matrix pointer
    const mwSize * dims;                        // M dimensions

    M = (unsigned int*) mxGetPr(prhs[0]);       //import Index Matrix
    rfdata = (double *) mxGetPr(prhs[1]);       //import rfdata
    dims = mxGetDimensions(prhs[0]);            // get the dimensions of the index matrix
    
    struct DataSizes var_sz = {
        dims[0],
        dims[1],
        dims[2],
        dims[0] * dims[1] * dims[2],
        dims[0] * dims[1],
        mxGetM(prhs[1]),
        mxGetN(prhs[1])
    };
    
    // create the output image matrix
    plhs[0] = mxCreateDoubleMatrix(var_sz.m_rows, var_sz.m_cols, mxREAL);
    img = (double*) mxGetPr(plhs[0]);

    // Run the DAS function
    // To-do: add support for alternate data types
    dasindex(M, rfdata, img, var_sz);

}
