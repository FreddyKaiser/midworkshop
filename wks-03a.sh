#!/bin/sh
#
# Workshop script to invoke the signing service: asynchron call
# <msisdn> <message> <language>

PWD=$(dirname $0)				# Get the Path of the script

# Swisscom Mobile ID credentials
AP_ID=mid://dev.swisscom.ch                     # AP ID
AP_PWD=disabled					# AP Password must be present but is not validated
CERT_FILE=$PWD/mycert.crt			# The certificate that is allowed to access the service
CERT_KEY=$PWD/mycert.key			# The related key of the certificate

# Swisscom SDCS elements
CERT_CA=$PWD/swisscom-ca.crt                    # Bag file with the server/client issuing and root certifiates

# Create temporary SOAP request
#  Asynchron with timeout
#  Signature format in PKCS7
RANDOM=$$					# Seeds the random number generator from PID of script
AP_INSTANT=$(date +%Y-%m-%dT%H:%M:%S%:z)	# Define instant and transaction id
AP_TRANSID=AP.TEST.$((RANDOM%89999+10000)).$((RANDOM%8999+1000))
SOAP_REQ=$(mktemp /tmp/_tmp.XXXXXX)		# SOAP Request goes here
SEND_TO=$1					# To who
SEND_MSG=$2					# What DataToBeSigned (DTBS)
USERLANG=$3					# User language
TIMEOUT_REQ=80					# Timeout of the request itself
TIMEOUT_CON=10					# Timeout of the connection to the server

cat > $SOAP_REQ <<End
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
    xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" 
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <MSS_Signature xmlns="">
      <mss:MSS_SignatureReq MinorVersion="1" MajorVersion="1" xmlns:mss="http://uri.etsi.org/TS102204/v1.1.2#" MessagingMode="asynchClientServer" TimeOut="$TIMEOUT_REQ" xmlns:fi="http://mss.ficom.fi/TS102204/v1.0.0#">
        <mss:AP_Info AP_PWD="$AP_PWD" AP_TransID="$AP_TRANSID" Instant="$AP_INSTANT" AP_ID="$AP_ID" />
        <mss:MSSP_Info>
          <mss:MSSP_ID>
            <mss:URI>http://mid.swisscom.ch/</mss:URI>
          </mss:MSSP_ID>
        </mss:MSSP_Info>
        <mss:MobileUser>
          <mss:MSISDN>$SEND_TO</mss:MSISDN>
        </mss:MobileUser>
        <mss:DataToBeSigned MimeType="text/plain" Encoding="UTF-8">$SEND_MSG</mss:DataToBeSigned>
        <mss:SignatureProfile>
          <mss:mssURI>http://mid.swisscom.ch/MID/v1/AuthProfile1</mss:mssURI>
        </mss:SignatureProfile>
        <mss:AdditionalServices>
          <mss:Service>
            <mss:Description>
              <mss:mssURI>http://mss.ficom.fi/TS102204/v1.0.0#userLang</mss:mssURI>
            </mss:Description>
            <fi:UserLang>$USERLANG</fi:UserLang>
          </mss:Service>
        </mss:AdditionalServices>
        <mss:MSS_Format>
          <mss:mssURI>http://uri.etsi.org/TS102204/v1.1.2#PKCS7</mss:mssURI>
        </mss:MSS_Format>
      </mss:MSS_SignatureReq>
    </MSS_Signature>
  </soapenv:Body>
</soapenv:Envelope>
End

# Call the service
curl --data "@${SOAP_REQ}" --header "Content-Type: text/xml; charset=utf-8" \
     --cert $CERT_FILE --cacert $CERT_CA --key $CERT_KEY \
     --output $SOAP_REQ.res --trace-ascii $SOAP_REQ.log \
     --silent --connect-timeout $TIMEOUT_CON \
     https://soap.mobileid.swisscom.com/soap/services/MSS_SignaturePort

# Traces
[ -f "$SOAP_REQ" ] && echo "\n>>> $SOAP_REQ <<<" && cat $SOAP_REQ | xmllint --format -
[ -f "$SOAP_REQ.res" ] && echo "\n>>> $SOAP_REQ.res <<<" && cat $SOAP_REQ.res | xmllint --format -

# Cleanups
[ -f "$SOAP_REQ" ] && rm $SOAP_REQ
[ -f "$SOAP_REQ.log" ] && rm $SOAP_REQ.log
[ -f "$SOAP_REQ.res" ] && rm $SOAP_REQ.res

#==========================================================
