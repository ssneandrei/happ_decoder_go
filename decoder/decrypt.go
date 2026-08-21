package decoder

import (
	"crypto/cipher"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"strings"

	"golang.org/x/crypto/chacha20poly1305"
)

// RSA Private Key, используемый в Happ
var happPrivateKeyPEM = []byte(`-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0Z3V... (здесь используется RSA ключ Happ) ...
-----END RSA PRIVATE KEY-----`)

// DecryptHappURL расшифровывает ссылку формата happ://crypt*
func DecryptHappURL(happURL string) (string, error) {
	if !strings.HasPrefix(happURL, "happ://") {
		return "", errors.New("неверный формат: ссылка должна начинаться с happ://")
	}

	cleanURL := strings.TrimPrefix(happURL, "happ://")
	parts := strings.SplitN(cleanURL, "/", 2)
	if len(parts) < 2 {
		return "", errors.New("неверная структура happ ссылки")
	}

	mode := parts[0]
	payloadBase64 := parts[1]

	data, err := base64.StdEncoding.DecodeString(payloadBase64)
	if err != nil {
		return "", errors.New("ошибка декодирования base64: " + err.Error())
	}

	switch mode {
	case "crypt", "crypt2", "crypt3", "crypt4":
		return decryptRSA(data)
	case "crypt5":
		return decryptCrypt5(data)
	default:
		return "", errors.New("неподдерживаемый режим шифрования: " + mode)
	}
}

func decryptRSA(data []byte) (string, error) {
	block, _ := pem.Decode(happPrivateKeyPEM)
	if block == nil {
		return "", errors.New("ошибка разбора PEM блока ключа")
	}

	privKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return "", errors.New("ошибка разбора RSA ключа: " + err.Error())
	}

	decrypted, err := rsa.DecryptPKCS1v15(rand.Reader, privKey, data)
	if err != nil {
		return "", errors.New("ошибка RSA расшифровки: " + err.Error())
	}

	return string(decrypted), nil
}

func decryptCrypt5(data []byte) (string, error) {
	if len(data) < 256 {
		return "", errors.New("длина payload слишком мала для crypt5")
	}

	rsaBlock := data[:256]
	encryptedBody := data[256:]

	block, _ := pem.Decode(happPrivateKeyPEM)
	if block == nil {
		return "", errors.New("ошибка разбора PEM блока ключа")
	}

	privKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return "", err
	}

	// Расшифровываем 32-байтный сессионный ключ ChaCha20 через RSA
	chachaKey, err := rsa.DecryptPKCS1v15(rand.Reader, privKey, rsaBlock)
	if err != nil {
		return "", errors.New("ошибка расшифровки ключа crypt5: " + err.Error())
	}

	aead, err := chacha20poly1305.NewX(chachaKey)
	if err != nil {
		return "", errors.New("ошибка инициализации ChaCha20Poly1305: " + err.Error())
	}

	if len(encryptedBody) < aead.NonceSize() {
		return "", errors.New("недостаточная длина ciphertext для Nonce")
	}

	nonce := encryptedBody[:aead.NonceSize()]
	ciphertext := encryptedBody[aead.NonceSize():]

	plaintext, err := aead.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", errors.New("ошибка ChaCha20-Poly1305 расшифровки: " + err.Error())
	}

	return string(plaintext), nil
}
