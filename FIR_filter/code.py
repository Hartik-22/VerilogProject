import numpy as np
import matplotlib.pyplot as plt

#fixed-point FIR filter implementation(Python reference model)
def fir_fixed_point(test_seq,filter_coeff,N1,N2,N3):
    #test_seq : input sequence (list of integers)
    #filter_coeff : filter coefficients (list of binary strings)
    TAPS = len(filter_coeff)
    y = []
    for i in range(len(test_seq)):
        acc = 0.0
        for j in range(TAPS):
            if i - j >= 0:
                acc +=(int(filter_coeff[j],2)*test_seq[i-j]);
        y.append(acc/(2**(N1-1)));
    return y

#function to convert binary string to decimal integer
def todecimal(x,bits):
    #x : binary string
    #bits : number of bits
    assert len(x) <= bits # ensure the length of binary string does not exceed bits
    n = int(x,2) # convert binary string to integer
    s = 1 <<(bits-1) 
    magnitude = n & (s -1)
    sign = n & s
    return magnitude if sign == 0 else magnitude - s

#number of coefficients
TAPS = 8
N1 = 8 #TAPS to 8 bit signed value
N2 = 16 #filter input to 16 bit signed value
N3 = 32 #output width
PIPELINE_STAGES = 4
real_coeff = (1/TAPS) #simple averaging filter

#bit representation of coefficients
#scaling the coefficient to fixed-point representation 
#scaling factor is 2^(N1-1) for signed values
# multiplying by 2^(N1-1) and converting to binary string
coeff_bit = np.binary_repr(int(real_coeff * (2**(N1-1))),N1)
print("Coefficient bit representation:", coeff_bit)
coeff_decimal = todecimal(coeff_bit,N1)
print("Coefficient decimal value:", coeff_decimal)

#generate a time sequence
timeVector = np.linspace(0,2*np.pi,100) #time vector
#generate input signal: sum of sine and cosine waves with noise
input_seq = np.sin(2*timeVector) + np.cos(3*timeVector) + 0.3*np.random.randn(len(timeVector))

# plt.plot(output)
# plt.show()

#convert to integer
scaled_input_seq = [];
for number in input_seq:
    scaled_input_seq.append(np.binary_repr(int(number * (2**(N1-1))),N2)) #scaling and converting to binary string

#save the sequence to a file
with open("input.data.txt","w") as file:
    for number in scaled_input_seq:
        file.write(number + "\n")

#read the scaled filter coefficients from the file
filter_coeff = []
with open("FIR_filter/coeff.data.txt") as file:
    for line in file:
        filter_coeff.append((line.rstrip('\n')))
# print("Filter Coefficients (binary):", filter_coeff)


#get the filter output from verilog simulation
rtl_output_bin = []

with open("FIR_filter/project_1/project_1.sim/sim_1/behav/xsim/save.data.txt") as file:
    for line in file:
        rtl_output_bin.append(line.rstrip('\n'))

rtl_output_dec = [] #convert binary output to decimal
for number in rtl_output_bin:
    rtl_output_dec.append(todecimal(number,N3)/(2**(N1-1))) #scaling back to original range

plt.plot(input_seq,color='blue',linewidth = 3,label='Original Signal')
plt.plot(rtl_output_dec,color='red',linewidth = 3,label='Filtered Signal')
plt.legend()
plt.savefig('FIR_filter_output.png',dpi = 600)
plt.show()

y_ref = (fir_fixed_point(input_seq,filter_coeff,N1,N2,N3)) #reference FIR filter output
PIPELINE_STAGES = 4
LATENCY = (TAPS-1)  + PIPELINE_STAGES

# discard invalid samples
y_valid = y_ref[TAPS-1: TAPS-1+ len(rtl_output_dec)] #aligning lengths


plt.plot(y_valid, label="Python FIR", linewidth=3)
plt.plot(rtl_output_dec, '--', label="Verilog FIR", linewidth=2)
plt.legend()
plt.title("FIR Filter Output Comparison")
plt.savefig('FIR_filter_verification.png',dpi = 600)
plt.grid()
plt.show()

# Quantization error
y_valid_arr = np.array(y_valid)
rtl_arr     = np.array(rtl_output_dec[:len(y_valid)])
error = y_valid_arr - rtl_arr
plt.figure()
plt.plot(error)
plt.title("Quantization Error")
plt.xlabel("Sample Index")
plt.ylabel("Error")
plt.grid()
plt.show()

# Calculate SNR and error metrics
signal_power = np.mean(y_valid_arr**2)
error_power  = np.mean(error**2)
SNR = 10 * np.log10(signal_power / error_power)
print("Signal Power :", signal_power)
print("Error Power  :", error_power)
print("SNR (dB)     :", SNR)
print("Max Abs Error :", np.max(np.abs(error)))
print("Mean Abs Error:", np.mean(np.abs(error)))
relative_error = np.abs(error) / (np.abs(y_valid) + 1e-12)
print("Mean Relative Error:", np.mean(relative_error))
