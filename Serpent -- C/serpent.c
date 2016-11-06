//
//  serpent.c
//  Serpent
//

#include "serpent.h"
#include "s-boxes.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>

// IMPORTANT: ONLY CONVERTS A BIG ENDIAN HEX STRING
void hexConvert(const char *s, unsigned char* b) {
    const char* a = "0123456789abcdef";
    // find
    for(int i = 0; i < 32; i+=2) {
        unsigned char e = 0;
        for(int j = 0; j < 16; ++j) {
            if(s[i] == a[j]){
                e |= j << 4;
                break;
            }
        }
        for(int j = 0; j < 16; ++j) {
            if(s[i+1] == a[j]){
                e |= j << 0;
                break;
            }
        }
        b[15-(i/2)] = e;
    }
}

void printHex(const unsigned char *s, int bytelength, const char * message) {
    const char* a = "0123456789abcdef";
    printf("%s\n", message);
    printf("(little endian)\n");
    for(int i = 0; i < bytelength; ++i){
        printf("%c", a[(s[i] >> 0) & 0xF]);
        printf("%c", a[(s[i] >> 4) & 0xF]);
    }
    printf("\n(big endian)\n");
    for(int i = bytelength-1; i >= 0; --i){
        printf("%c", a[(s[i] >> 4) & 0xF]);
        printf("%c", a[(s[i] >> 0) & 0xF]);
    }
    printf("\n");
}

uint32_t rotl (WORD x, int p) {
    return ((x << p) | (x >> (BITS_PER_WORD-p))) & 0xffffffff;
}

void InitialPermutation(const uint *input, uint *result) {
    // load first and last bits
    result[0] |= ((input[0] >> 0 ) & 0x1) << 0 ;
    result[3] |= ((input[3] >> 31) & 0x1) << 31;
    // transform bits
    // THIS SHOULD BE CORRECT
    for(int i = 1; i < 127; ++i) {
        uint replacer = ((i*32)%127);
        uint currentBlockPosition = i/32;
        uint currentBlockReplacer = replacer/32;
        result[currentBlockPosition] |= ((input[currentBlockReplacer] >> (replacer%32)) & 1) << (i % 32);
    }
}

// IMPORTED FUNCTION
void setBit(uint *x, int p, BIT v) {
    /* Set the bit at position 'p' of little-endian word array 'x' to 'v'. */
    
    if (v) {
        x[p/BITS_PER_WORD] |= ((WORD) 0x1 << p%BITS_PER_WORD);
    } else {
        x[p/BITS_PER_WORD] &= ~((WORD) 0x1 << p%BITS_PER_WORD);
    }
}
// IMPORTED FUNCTION
BIT getBit(WORD x[], int p) {
    /* Return the value of the bit at position 'p' in little-endian word
     array 'x'. */
    
    return (BIT) ((x[p/BITS_PER_WORD]
                   & ((WORD) 0x1 << p%BITS_PER_WORD)) >> p%BITS_PER_WORD);
}

void serpent_encrypt(const unsigned char* plaintext, const unsigned char* key, unsigned char * output, unsigned int kBytes) {
    // 33 subkeys * 32bits * 4 blocks
    uint subkeys[33][4]= {0};
    uint keysplit[8]   = {0};
    uint interkey[140] = {0};
    
    // memory precheck
    if(output == NULL) {
        fprintf(stderr, "Given output char pointer not initialized/allocated.\n");
        exit(EXIT_FAILURE);
    }

    printHex(plaintext, 16, "Plaintext:");
    
    /* BIT EXTEND KEY */
    
    // check if key needs to be padded then
    // split original key into 8 32bit prekeys
    if(kBytes < 32){
        unsigned char tempkey[32] = {0};
        // if shorter than 32 bytes, pad key with 0b1
        ulong kl = kBytes;
        for(int i = 0; i < kl; ++i) {
            tempkey[i] = key[i];
        }
        tempkey[kl] = 0b00000001;
        for(int i = 0; i < 8; ++i) {
            keysplit[i] = *(((uint*)tempkey)+i);
        }
        printHex(tempkey, 32, "Key:");
    }
    else if(kBytes == 32) {
        for(int i = 0; i < 8; ++i) {
            keysplit[i] = *(((uint*)key)+i);
        }
        printHex(key, 32, "Key:");
    }
    else {
        printf("Key Length Error\n");
        exit(EXIT_FAILURE);
    }
    
    // load keysplit into interkey
    for(int i = 0; i < 8; ++i){
        interkey[i] = keysplit[i];
    }
    
    /* GENERATE PREKEYS */
    
    for(int i = 8; i < 140; ++i) {
        interkey[i] = rotl((interkey[i-8] ^ interkey[i-5] ^ interkey[i-3] ^ interkey[i-1] ^ phi ^ (i-8)), 11);
    }
    
    /* GENERATE SUBKEYS */
    
    // reposition pointer to align with 132 word array
    uint *reposition = &interkey[8];
    
    // generate keys from s-boxes
    // holds keys
    uint k[132] = {0};
    for(int i = 0; i < 33; ++i) {
        // descending selector starting at 3
        int currentBox = (32 + 3 - i) % 32;
        char sboxOut= 0;
        for(int j = 0; j < 32; ++j) {
            sboxOut = SBox[currentBox][((reposition[0+4*i]>>j)&1) <<0 |
                                       ((reposition[1+4*i]>>j)&1) <<1 |
                                       ((reposition[2+4*i]>>j)&1) <<2 |
                                       ((reposition[3+4*i]>>j)&1) <<3 ];
            for(int l = 0; l < 4; ++l) {
                k[l+4*i] |= ((sboxOut >> l)&1)<<j;
            }
        }
    }
    
    for(int i = 0; i < 33; ++i) {
        for(int j = 0; j < 4; ++j) {
            subkeys[i][j] = k[4*i+j];
        }
    }
    
    /*  Start plaintext processing  */
    
    
    /* INITIAL PERMUTATION */
    
    // ignore bit[0] and bit[127]
    // replace bit[1..126] with bit[(i*32)%127]
    const uint *charpToInt = (const uint*)plaintext;
    uint result[4] = {0};
    InitialPermutation(charpToInt, result);
    
    // result == Bi
    
    /* LINEAR TRANSFORMATION */
    
    
    // PERMUTATE THE KEYS
    uint subkeysHat[33][4]= {0};
    for(int i = 0; i < 33; ++i) {
        InitialPermutation(subkeys[i], subkeysHat[i]);
    }
    
    // 32 rounds
    uint X[4] = {0};
    for(int i = 0; i < 32; ++i) {
        for (int j = 0; j < 4; ++j) {
            X[j] = result[j] ^ subkeysHat[i][j];
        }
        for(int j = 0; j < 4; ++j) {
            X[j] =  (SBox[i][(X[j] >> 0 ) & 0xF]) << 0 |
                    (SBox[i][(X[j] >> 4 ) & 0xF]) << 4 |
                    (SBox[i][(X[j] >> 8 ) & 0xF]) << 8 |
                    (SBox[i][(X[j] >> 12) & 0xF]) << 12|
                    (SBox[i][(X[j] >> 16) & 0xF]) << 16|
                    (SBox[i][(X[j] >> 20) & 0xF]) << 20|
                    (SBox[i][(X[j] >> 24) & 0xF]) << 24|
                    (SBox[i][(X[j] >> 28) & 0xF]) << 28;
        }
        if(i < 31){
            
            // fails no matter what - replaced by LTtable
//            X[0] = rotl(X[0], 13);
//            X[2] = rotl(X[2], 3 );
//            X[1] = X[1] ^ X[0] ^ X[2];
//            X[3] = X[3] ^ X[2] ^ (X[0] << 3);
//            X[1] = rotl(X[1], 1);
//            X[3] = rotl(X[3], 7);
//            X[0] = X[0] ^ X[1] ^ X[3];
//            X[2] = X[2] ^ X[3] ^ (X[1] << 7);
//            X[0] = rotl(X[0], 5 );
//            X[2] = rotl(X[2], 22);
            
            for(int a = 0; a < 128; ++a) {
                char b = 0;
                int  j = 0;
                while (LTTable[a][j] != MARKER) {
                    b ^= getBit(X, LTTable[a][j]);
                    ++j;
                }
                setBit(result, a, b);
            }
        }
        else{
            // In the last round, the transformation is replaced by an additional key mixing
            result[0] = X[0] ^ subkeysHat[32][0];
            result[1] = X[1] ^ subkeysHat[32][1];
            result[2] = X[2] ^ subkeysHat[32][2];
            result[3] = X[3] ^ subkeysHat[32][3];
        }
    }
    
    /* FINAL PERMUTATION */
    
    uint finalResult[4] = {0};
    // copy end bits
    finalResult[0] |= ((result[0] >> 0 ) & 0x1) << 0 ;
    finalResult[3] |= ((result[3] >> 31) & 0x1) << 31;
    // transform bits
    for(int i = 1; i < 127; ++i) {
        uint replacer = ((i*4)%127);
        uint currentBlockPosition = i/32;
        uint currentBlockReplacer = replacer/32;
        finalResult[currentBlockPosition] |= ((result[currentBlockReplacer] >> (replacer%32)) & 1) << (i % 32);
    }
    
    // copy 128 bits to output string
    memcpy(output, finalResult, 16);
}