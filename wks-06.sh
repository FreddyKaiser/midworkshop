#!/bin/sh
#
# Workshop script to decode the mss:MSS_Signature and display the MID user certificate
# <mss:Base64Signature>

PWD=$(dirname $0)				# Get the Path of the script

SOAP_REQ=$(mktemp /tmp/_tmp.XXXXXX)		# SOAP Request goes here
SIGNATURE=$1                                    # Param 1 contains the mss:Base64Signature
if [ "$SIGNATURE" = "" ]; then			# Nothing passed, set default one
        SIGNATURE=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
fi
echo $SIGNATURE > $SOAP_REQ.sig                 # Write signature into temporary file

# Swisscom SDCS elements
CERT_CA=$PWD/swisscom-ca.crt                    # Bag file with the server/client issuing and root certifiates
OCSP_CERT=$PWD/swisscom-ocsp.crt		# OCSP information of the signers certificate
OCSP_URL=http://ocsp.swissdigicert.ch/sdcs-rubin2

# Decode the signature and extract the certificate
base64 --decode  $SOAP_REQ.sig > $SOAP_REQ.sig.decoded
openssl pkcs7 -inform der -in $SOAP_REQ.sig.decoded -out $SOAP_REQ.sig.cert -print_certs

# Display the subject of the signer certificate
echo "\n>>> Signer certificate details <<<"
openssl x509 -text -in $SOAP_REQ.sig.cert

# Cleanups
echo "\n"
[ -f "$SOAP_REQ" ] && rm $SOAP_REQ
[ -f "$SOAP_REQ.sig" ] && rm $SOAP_REQ.sig
[ -f "$SOAP_REQ.sig.decoded" ] && rm $SOAP_REQ.sig.decoded
[ -f "$SOAP_REQ.sig.cert" ] && rm $SOAP_REQ.sig.cert

#==========================================================
