package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"github.com/enceve/crypto/pad"
	"golang.org/x/crypto/pbkdf2"
)

// https://asecuritysite.com/golang/go_symmetric
func main() {

	msg := "hello"
	passwd := "qwerty"
	mode := "gcm"
	size := 16 // AES密钥长度只能是16、24、32字节，用以选择AES-128、AES-192、AES-256。16 * 8 = 128bits

	argCount := len(os.Args[1:])
	if argCount > 0 {
		msg = os.Args[1]
	}
	if argCount > 1 {
		passwd = os.Args[2]
	}
	if argCount > 2 {
		mode = os.Args[3]
	}
	if argCount > 3 {
		size, _ = strconv.Atoi(os.Args[4])
	}

	pwsalt := getSalt(12) // 96 bits for nonce/IV

	key := pbkdf2.Key([]byte(passwd), pwsalt, 10000, size, sha256.New)

	block, _ := aes.NewCipher(key)

	var salt []byte
	var plain []byte
	var ciphertext []byte

	plaintext := []byte(msg)

	if mode == "gcm" {
		// AEAD
		salt = getSalt(12)
		aesgcm, _ := cipher.NewGCM(block)
		ciphertext = aesgcm.Seal(nil, salt, plaintext, nil)
		plain, _ = aesgcm.Open(nil, salt, ciphertext, nil)
	} else if mode == "cbc" {
		// Block cipher
		plain = make([]byte, (len(plaintext)/16+1)*aes.BlockSize)
		ciphertext = make([]byte, (len(plaintext)/16+1)*aes.BlockSize)
		salt = getSalt(16)
		pkcs7 := pad.NewPKCS7(aes.BlockSize)
		pad1 := pkcs7.Pad(plaintext)
		blk := cipher.NewCBCEncrypter(block, salt)
		blk.CryptBlocks(ciphertext, pad1)
		blk = cipher.NewCBCDecrypter(block, salt)
		blk.CryptBlocks(plain, ciphertext)
		plain, _ = pkcs7.Unpad(plain)

	} else if mode == "cfb" {
		// Stream cipher
		salt = getSalt(aes.BlockSize)
		plain = make([]byte, len(plaintext))
		ciphertext = make([]byte, len(plaintext))

		stream := cipher.NewCFBEncrypter(block, salt)
		stream.XORKeyStream(ciphertext, plaintext)
		stream = cipher.NewCFBDecrypter(block, salt)
		stream.XORKeyStream(plain, ciphertext)
	}

	fmt.Printf("Mode:\t\t%s\n", strings.ToUpper(mode))
	fmt.Printf("Key size:\t%d bits\n", size*8)
	fmt.Printf("Message:\t%s\n", msg)

	fmt.Printf("Password:\t%s\n", passwd)
	fmt.Printf("Password Salt:\t%x\n", pwsalt)
	fmt.Printf("\nKey:\t\t%x\n", key)
	fmt.Printf("\nCipher:\t\t%x\n", ciphertext)

	fmt.Printf("Salt:\t\t%x\n", salt)
	fmt.Printf("\nDecrypted:\t%s\n", plain)
}

func getSalt(n int) []byte {
	nonce := make([]byte, n)
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		panic(err.Error())
	}
	return (nonce)

}
