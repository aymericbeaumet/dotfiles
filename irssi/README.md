### How to connect a server using SASL

These PERL dependencies are mandatory to use SASL:

    for i in 'Crypt::OpenSSL::Bignum' 'Crypt::DH' 'Crypt::Blowfish' 'Math::BigInt' ; do sudo perl -MCPAN -e shell <<< "install $i" ; done

Use SASL:

> /sasl set server nick password DH-BLOWFISH
> /sasl save
> /save
