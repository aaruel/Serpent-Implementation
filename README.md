##Serpent Encryption Process

-- KEY GENERATION

1. Load 128bit key and 128bit plaintext
1. Extend key to 256bits by appending after the MSB a '1' then '0' to the end
1. Split key into 8 32bit segments
1. Load key segments into first 8 places of 140 place (each 32bits) array
1. Iterate over the rest of the 140 place array

```
for i in 8 to 140 {
    prekeys[i] = (prekeys[i-8] ^ prekeys[i-5] ^ prekeys[i-3] ^ prekeys[i-1] ^ phi ^ (i-8)) <<< 11;
}
```

1. Generate subkeys from S-boxes
	- Explanation of sbox output
		- select current S-box row with ((32+3-i) mod 32)
		- Form a 4 bit value that selects value in row by concatenating bits in prekeys following
			```prekey[8+0(4*i)]bit(j) & prekey[8+1(4*i)]bit(j) & prekey[8+2(4*i)]bit(j) & prekey[8+3(4*i)]bit(j)```
		- OR S-box output into empty array by bits using equation
			```k[l+4*i] |= ((sboxOut >> l)&1)<<j;```

1. Load above S-box array into subkeys (33x4 2d array)

-- PLAINTEXT TRANSFORMS

- Only in standard version
    1. Description of initial permutation function
    	- Load first and last bits of input into empty bit array
    	- Iterate over rest of empty array and set bits from input at position ((i*32) mod 127)

    1. Run plaintext through initial permutation function
    1. Run each subkey through initial permutation function

1. Start 32 rounds
1. XOR plaintext permutation and current subkey permutation each round
- Standard Version
    1. Form 32bit value using the 8 4bit values to return S-box value and append
    1. First 31 rounds
    	- access Linear Transformation table with iterators to return bit position from above 32 bit value to load into plaintext permutation
- Bitslice Version
    1. Take one bit from each XOR'd 32bit value starting from position 0 (totaling 4bits) and use that as input to return a value from S-box i%8
    1. The 4bit value returned from the S-Box is distributed to the 32bit values the same way it was extracted
    1. Run the resulting 4 32bit values through the linear transformation equation referenced in the documentation
1. Last round
	- XOR above 32 bit value and 33rd subkey permutations into result

- Only in standard version
    1. Final permutation
    	- Exactly the same as initial permutation except using the bit selector ((i*4)%127)

1. End encryption

##Serpent Decryption Process

- Logically work backwards from encryption
- Use inverse tables such as Inverse Linear Transformation Table and Inverse S-boxes
- Note: In the bitslice, the LT equation uses shift left logical which should also be used in decryption
    - The rotations are still the opposite, the shift is not
