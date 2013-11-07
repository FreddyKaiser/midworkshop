#!/bin/sh
#
# Workshop script to invoke a normal receipt
# <MSISDN> <MSSP_TransID> <Message>

PWD=$(dirname $0)				# Get the Path of the script

# Swisscom Mobile ID credentials
AP_ID=mid://dev.swisscom.ch                     # AP ID
AP_PWD=disabled					# AP Password must be present but is not validated
CERT_FILE=$PWD/mycert.crt			# The certificate that is allowed to access the service
CERT_KEY=$PWD/mycert.key			# The related key of the certificate

# Swisscom SDCS elements
CERT_CA=$PWD/swisscom-ca.crt                    # Bag file with the server/client issuing and root certifiates

# Create temporary SOAP request
RANDOM=$$					# Seeds the random number generator from PID of script
AP_INSTANT=$(date +%Y-%m-%dT%H:%M:%S%:z)	# Define instant and transaction id
AP_TRANSID=AP.TEST.$((RANDOM%89999+10000)).$((RANDOM%8999+1000))
MSSP_TRANSID=$2					# Transaction ID of request
SOAP_REQ=$(mktemp /tmp/_tmp.XXXXXX)		# SOAP Request goes here
SEND_TO=$1					# To who
TIMEOUT_REQ=5					# Timeout of the request itself
TIMEOUT_CON=10					# Timeout of the connection to the server
MSG_TXT=$3                                      # Define the message

cat > $SOAP_REQ <<End
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
    xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" 
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <MSS_Receipt>
      <mss:MSS_ReceiptReq MinorVersion="1" MajorVersion="1" MSSP_TransID="$MSSP_TRANSID" xmlns:mss="http://uri.etsi.org/TS102204/v1.1.2#" TimeOut="$TIMEOUT_REQ" xmlns:fi="http://mss.ficom.fi/TS102204/v1.0.0#">
        <mss:AP_Info AP_PWD="$AP_PWD" AP_TransID="$AP_TRANSID" Instant="$AP_INSTANT" AP_ID="$AP_ID" />
        <mss:MSSP_Info>
          <mss:MSSP_ID>
            <mss:URI>http://mid.swisscom.ch/</mss:URI>
          </mss:MSSP_ID>
        </mss:MSSP_Info>
        <mss:MobileUser>
          <mss:MSISDN>$SEND_TO</mss:MSISDN>
        </mss:MobileUser>
        <mss:Message MimeType="text/plain" Encoding="UTF-8">$MSG_TXT</mss:Message>
      </mss:MSS_ReceiptReq>
    </MSS_Receipt>
  </soapenv:Body>
</soapenv:Envelope>
End

# Call the service
SOAP_ACTION=#MSS_Receipt
curl --data "@${SOAP_REQ}" --header "Content-Type: text/xml; charset=utf-8" --header "SOAPAction: \"$SOAP_ACTION\"" \
     --cert $CERT_FILE --cacert $CERT_CA --key $CERT_KEY \
     --output $SOAP_REQ.res \
     --silent --connect-timeout $TIMEOUT_CON \
     https://soap.mobileid.swisscom.com/soap/services/MSS_ReceiptPort

# Traces
[ -f "$SOAP_REQ" ] && echo "\n>>> $SOAP_REQ <<<" && cat $SOAP_REQ | xmlindent
[ -f "$SOAP_REQ.res" ] && echo "\n>>> $SOAP_REQ.res <<<" && cat $SOAP_REQ.res | xmlindent

# Cleanups
[ -f "$SOAP_REQ" ] && rm $SOAP_REQ
[ -f "$SOAP_REQ.res" ] && rm $SOAP_REQ.res

#==========================================================
