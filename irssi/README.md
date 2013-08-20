### How to connect a server using SASL

Install SASL dependencies:

    for i in 'Crypt::OpenSSL::Bignum' 'Crypt::DH' 'Crypt::Blowfish' 'Math::BigInt' ; do sudo perl -MCPAN -e shell <<< "install $i" ; done

Setup SASL:

    irssi -!
    /sasl set freenode nickname password DH-BLOWFISH
    /sasl save
    /save
