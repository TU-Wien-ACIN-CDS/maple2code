from casadi import *
import numpy

def y_out(x, par): 
 # Optimized and generated from Maple
    fcn_out = 0
    fcn_out = par['c_T'] @ x + par['a']
    return fcn_out