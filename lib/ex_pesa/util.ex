defmodule ExPesa.Util do
  @moduledoc false

  @doc false
  @spec get_url(String.t(), String.t()) :: String.t()
  def get_url(live_url, sandbox_url) do
    cond do
      Mix.env() == :prod -> live_url
      Application.get_env(:ex_pesa, :force_live_url) == "YES" -> live_url
      true -> sandbox_url
    end
  end

  @doc """
  Security Credentials read more https://developer.safaricom.co.ke/docs#security-credentials
  M-Pesa Core authenticates a transaction by decrypting the security credentials. Security credentials are generated by encrypting the base64 encoded initiator password with M-Pesa’s public key, a X509 certificate.

    The algorithm for generating security credentials is as follows:
    Write the unencrypted password into a byte array.
    Encrypt the array with the M-Pesa public key certificate. Use the RSA algorithm, and use PKCS #1.5 padding (not OAEP), and add the result to the encrypted stream.
    Convert the resulting encrypted byte array into a string using base64 encoding. The resulting base64 encoded string is the security credential.

    Impementation Examples
      PHP
      <?php
        $publicKey = "PATH_TO_CERTICATE_FILE";
        $plaintext = "YOUR_PASSWORD";

        openssl_public_encrypt($plaintext, $encrypted, $publicKey, OPENSSL_PKCS1_PADDING);

        echo base64_encode($encrypted);
        ?>

      Node Js
        module.exports = (certPath, shortCodeSecurityCredential) => {
        const bufferToEncrypt = Buffer.from(shortCodeSecurityCredential)
        const data = fs.readFileSync(path.resolve(certPath))
        const privateKey = String(data)
        const encrypted = crypto.publicEncrypt({
          key: privateKey,
          padding: crypto.constants.RSA_PKCS1_PADDING
        }, bufferToEncrypt)
        const securityCredential = encrypted.toString('base64')
        return securityCredential
    }

    JAVA

    // Function to encrypt the initiator credentials
    public static String encryptInitiatorPassword(String securityCertificate, String password) {
        String encryptedPassword = "YOUR_INITIATOR_PASSWORD";
        try {
            Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider());
            byte[] input = password.getBytes();

            Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding", "BC");
            FileInputStream fin = new FileInputStream(new File(securityCertificate));
            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            X509Certificate certificate = (X509Certificate) cf.generateCertificate(fin);
            PublicKey pk = certificate.getPublicKey();
            cipher.init(Cipher.ENCRYPT_MODE, pk);

            byte[] cipherText = cipher.doFinal(input);

            // Convert the resulting encrypted byte array into a string using base64 encoding
            encryptedPassword = Base64.encode(cipherText);
        }
      }

    Python

    from M2Crypto import RSA, X509
    from base64 import b64encode

    INITIATOR_PASS  = "YOUR_PASSWORD"
    CERTIFICATE_FILE = "PATH_TO_CERTIFICATE_FILE"

    def encryptInitiatorPassword():
        cert_file = open(CERTIFICATE_FILE, 'r')
        cert_data = cert_file.read() #read certificate file
        cert_file.close()

        cert = X509.load_cert_string(cert_data)
        #pub_key = X509.load_cert_string(cert_data)
        pub_key = cert.get_pubkey()
        rsa_key = pub_key.get_rsa()
        cipher = rsa_key.public_encrypt(INITIATOR_PASS, RSA.pkcs1_padding)
        return b64encode(cipher)

    print encryptInitiatorPassword()

  ## Example
      iex> certfile = "-----BEGIN CERTIFICATE-----\nMIIGKzCCBROgAwIBAgIQDL7NH8cxSdUpl0ihH0A1wTANBgkqhkiG9w0BAQsFADBN\nMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5E\naWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMTgwODI3MDAwMDAwWhcN\nMTkwNDA0MTIwMDAwWjBuMQswCQYDVQQGEwJLRTEQMA4GA1UEBxMHTmFpcm9iaTEW\nMBQGA1UEChMNU2FmYXJpY29tIFBMQzETMBEGA1UECxMKRGlnaXRhbCBJVDEgMB4G\nA1UEAxMXc2FuZGJveC5zYWZhcmljb20uY28ua2UwggEiMA0GCSqGSIb3DQEBAQUA\nA4IBDwAwggEKAoIBAQC78yeC/wLoZY6TJeqc4g/9eAKIpeCwEsjX09pD8ZxAGXqT\nOi7ssdIGJBPmJZNeEVyf8ocFhisCuLngJ9Z5e/AvH52PhrEFmVu2D03zSf4C+rhZ\nndEKP6G79pUAb/bemOliU9zM8xYYkpCRzPWUzk6zSDarg0ZDLw5FrtZj/VJ9YEDL\nWGgAfwExEgSN3wjyUlJ2UwI3wqQXLka0VNFWoZxUH5j436gbSWRIL6NJUmrq8V8S\naTEPz3eJHj3NOToDu245c7VKdF/KExyZjRjD2p5I+Aip80TXzKlZj6DjMb3DlfXF\nHsnu0+1uJE701mvKX7BiscxKr8tCRphL63as4dqvAgMBAAGjggLkMIIC4DAfBgNV\nHSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4EFgQUzZmY7ZORLw9w\nqRbAQN5m9lJ28qMwIgYDVR0RBBswGYIXc2FuZGJveC5zYWZhcmljb20uY28ua2Uw\nDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBr\nBgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc3NjYS1z\naGEyLWc2LmNybDAvoC2gK4YpaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NzY2Et\nc2hhMi1nNi5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAQEwKjAoBggrBgEFBQcC\nARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBAgIwfAYIKwYB\nBQUHAQEEcDBuMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w\nRgYIKwYBBQUHMAKGOmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy\ndFNIQTJTZWN1cmVTZXJ2ZXJDQS5jcnQwCQYDVR0TBAIwADCCAQUGCisGAQQB1nkC\nBAIEgfYEgfMA8QB2AKS5CZC0GFgUh7sTosxncAo8NZgE+RvfuON3zQ7IDdwQAAAB\nZXs1FvEAAAQDAEcwRQIgBzVMkm7SNprjJ1GBqiXIc9rNzY+y7gt6s/O02oMkyFoC\nIQDBuThGlpmUKpeZoHhK6HGwB4jDMIecmKaOcMS18R2jxwB3AId1v+dZfPiMQ5lf\nvfNu/1aNR1Y2/0q1YMG06v9eoIMPAAABZXs1F8IAAAQDAEgwRgIhAIRq2XFiC+RS\nuDCYq8ICJg0QafSV+e9BLpJnElEdaSjiAiEAyiiW4vxwv4cWcAXE6FAipctyUBs6\nbE5QyaCnmNpoDiQwDQYJKoZIhvcNAQELBQADggEBAB0YoWve9Sxhb0PBS3Hc46Rf\na7H1jhHuwE+UyscSQsdJdk8uPAgDuKRZMvJPGEaCkNHm36NfcaXXFjPOl7LI1d1a\n9zqSP0xeZBI6cF0x96WuQGrI9/WR2tfxjmaUSp8a/aJ6n+tZA28eJZNPrIaMm+6j\ngh7AkKnqcf+g8F/MvCCVdNAiVMdz6UpCscf6BRPHNZ5ifvChGh7aUKjrVLLuF4Ls\nHE05qm6HNyV5eTa6wvcbc4ewguN1UDZvPWetSyfBk10Wbpor4znQ4TJ3Y9uCvsJH\n41ldblDvZZ2z4kB2UYQ7iBkPlJSxSOaFgW/GGDXq49sz/995xzhVITHxh2SdLkI=\n-----END CERTIFICATE-----\n"
      iex> password = "Safaricom133"
      iex> ExPesa.Util.generate_security_credential(%{CertFile: certfile, Password: password})
  """

  def generate_security_credential(%{CertFile: certfile, Password: password})
      when certfile != nil and password != nil do
    cert_text =
      certfile |> String.trim() |> String.split(~r{\n  *}, trim: true) |> Enum.join("\n")

    # 1) Decode the certificate.
    [pem_entry] = :public_key.pem_decode(cert_text)
    cert_decoded = :public_key.pem_entry_decode(pem_entry)

    # 2) Extract public key.
    list = Tuple.to_list(elem(cert_decoded, 1))
    plk = List.keyfind(list, :SubjectPublicKeyInfo, 0) |> elem(2)

    public_key = :public_key.der_decode(:RSAPublicKey, plk)

    # 3) Encrypt the plain password text
    ciphertext =
      :public_key.encrypt_public(password, public_key, [{:rsa_pad, :rsa_pkcs1_padding}])

    # 4) Base64 encode and return the result
    :base64.encode(ciphertext)
  end

  def generate_security_credential(%{}) do
    nil
  end

  def get_security_credential_for(key) do
    case Application.get_env(:ex_pesa, :mpesa)[key][:security_credential] do
      nil ->
        cert = Application.get_env(:ex_pesa, :mpesa)[:cert]
        password = Application.get_env(:ex_pesa, :mpesa)[key][:password]
        generate_security_credential(%{CertFile: cert, Password: password})

      credential ->
        credential
    end
  end
end
