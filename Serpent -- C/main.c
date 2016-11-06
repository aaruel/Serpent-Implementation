//
//  main.c
//  Serpent
//

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
    const char * test_string = "0123456789abcdeffedcba9876543210" ;
    // key in this implementation must be 128bits
    const char * key_string  = "00112233445566778899aabbccddeeff" ;
    /*                          ^ = msb                        ^ = lsb */
    unsigned char * encrypted_string  = malloc(16/*bytes*/);
    
    // print original string
//    print_bits(test_string, "Plaintext");
//    print_bits(key_string, "Key");
    
    unsigned char * test_string_hex = malloc(16);
    hexConvert(test_string, test_string_hex);
    unsigned char * key_string_hex  = malloc(16);
    hexConvert(key_string, key_string_hex);
    
    serpent_encrypt(test_string_hex, key_string_hex, encrypted_string, 16);
    printHex(encrypted_string, 16, "Cyphertext:");
    free(encrypted_string);
    free(test_string_hex);
    free(key_string_hex);
    return 0;
}
