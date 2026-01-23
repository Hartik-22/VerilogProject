import numpy as np
import matplotlib.pyplot as plt

'''
    x : binary string
    bits : number of bits

'''

def todecimal(x,bits):
    assert len(x) <= bits # ensure the length of binary string does not exceed bits
    n = int(x,2) # convert binary string to integer
    s = 1 <<(bits-1) 
    magnitude = n & (s -1)
    sign = n & s
    return magnitude if sign == 0 else magnitude - s

#number of coefficients
tap = 8
N1 = 8 #tap to 8 bit signed value
N2 = 16 #filter input to 16 bit signed value
N3 = 32 #output width

real_coeff = (1/tap)

#bit representation of coefficients
coeff_bit = np.binary_repr(int(real_coeff * (2**(N1-1))),N1)

print("Coefficient bit representation:", coeff_bit)
coeff_decimal = todecimal(coeff_bit,N1)
print("Coefficient decimal value:", coeff_decimal)

#generate a test sequence
timeVector = np.linspace(0,2*np.pi,100)

output = np.sin(2*timeVector) + np.cos(3*timeVector) + 0.3*np.random.randn(len(timeVector))

plt.plot(output)
plt.show()

#convert to integer
list1 = [];
for number in output:
    list1.append(np.binary_repr(int(number * (2**(N1-1))),N2))

# print("First 5 input samples in bit representation:")
# for i in range(5):
#     print(list1[i])


#save the sequence to a file
with open("input.data.txt","w") as file:
    for number in list1:
        file.write(number + "\n")

read_b = []
with open("project_1/project_1.sim/sim_1/behav/xsim/save.data") as file:
    for line in file:
        read_b.append(line.rstrip('\n'))

read_d = []
for number in read_b:
    read_d.append(todecimal(number,N3)/(2**(N1-1)))

plt.plot(output,color='blue',linewidth = 3,label='Original Signal')
plt.plot(read_d,color='red',linewidth = 3,label='Filtered Signal')
plt.legend()
plt.savefig('FIR_filter_output.png',dpi = 600)
plt.show()

error = output[7:] - read_d
plt.plot(error)
plt.title("Quantization Error")
plt.show()

print("Max error:", np.max(np.abs(error)))
print("Mean error:", np.mean(np.abs(error)))
print("Min error:", np.min(np.abs(error)))