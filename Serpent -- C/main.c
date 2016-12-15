//
//  main.c
//  Serpent
//
//  This implementation shows two different methods of serpent
//      1. Regular mode  
//      2. Bitslice mode
//  Both models have the same key generation method, except
//      - Regular mode includes an initial and final permutation for plaintext
//      - Regular mode has a key permutation step
//      - Regular mode uses the SBox slightly different in the linear transformation
//      - Bitslice mode for LT uses an equation, regular mode uses the linear transformation tables

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "serpent.h"

// 1*n bytes input
void print_bits(const char* b, const char* message) {
    int j = 0, i = 0;
    printf("%lubit block :: %s\n", strlen(b)*8, message);
    for(; i < strlen(b); ++i) {
        for(; j < 8/*bits*/; ++j){
            // dereference current 8 bit block
            // shift by bit in reverse order
            // AND lsb
            // print
            printf("%i", ((*(b+i))>>(7-j))&1);
        }
        // displays each 32 bits
        printf(" ");
        if(!((i+1)%4))printf("\n");
        j = 0;
    }
}

int main(int argc, const char * argv[]) {
    // HEX INPUT
    // (8 bits * 4) * 4 = 128 bits
    const char * test_string = "00000000000000000000000000000000" ;
    // key in this implementation must be 128bits
    const char * key_string  = "00000000000000000000000000000000" ;
    /*                          ^ = msb                        ^ = lsb */
    unsigned char * encrypted_string  = malloc(16/*bytes*/);
    unsigned char * decrypted_string  = malloc(16/*bytes*/);
    
    // print original string
//    print_bits(test_string, "Plaintext");
//    print_bits(key_string, "Key");
    
    unsigned char * test_string_hex = malloc(16);
    hexConvert(test_string, test_string_hex);
    unsigned char * key_string_hex  = malloc(16);
    hexConvert(key_string, key_string_hex);
    
    serpent_encrypt_bitslice(test_string_hex, key_string_hex, encrypted_string, 16);
    printHex(encrypted_string, 16, "Encrypted Cipher:");
    printf("\n");
    serpent_decrypt_bitslice(encrypted_string, key_string_hex, decrypted_string, 16);
    printHex(decrypted_string, 16, "Decrypted Cipher:");
    
    free(encrypted_string);
    free(decrypted_string);
    free(test_string_hex);
    free(key_string_hex);
    return 0;
}
