#!/bin/sh
#
# Workshop script to invoke the query profile
# Parameters are <msisdn>

PWD=$(dirname $0)				      # Get the Path of the script

AP_ID=mid://dev.swisscom.ch   # AP ID
AP_PWD=disabled					      # AP Password must be present but is not validated
CERT_FILE=$PWD/mycert.crt			# The certificate that is allowed to access the service
CERT_KEY=$PWD/mycert.key			# The related key of the certificate
CERT_CA=$PWD/mobileid-ca-ssl.crt  # Bag file with the server/client issuing and root certifiates

SEND_TO=$1				          	# Destination number
TIMEOUT_CON=10			        	# Timeout of the connection to the server

# Define instant and transaction id
RANDOM=$$                     # Seeds the random number generator from PID of script
AP_INSTANT=$(date +%Y-%m-%dT%H:%M:%S%:z)	
AP_TRANSID=AP.TEST.$((RANDOM%89999+10000)).$((RANDOM%8999+1000))

# SOAP Request goes here
SOAP_REQ=$(mktemp /tmp/_tmp.XXXXXX)		

cat > $SOAP_REQ <<End
<soapenv:Envelope
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope"
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:mss="http://uri.etsi.org/TS102204/v1.1.2#">
  <soapenv:Body>
    <MSS_ProfileQuery>
      <mss:MSS_ProfileReq MajorVersion="1" MinorVersion="1" >
        <mss:AP_Info AP_PWD="$AP_PWD" AP_TransID="$AP_TRANSID" Instant="$AP_INSTANT" AP_ID="$AP_ID"/>
        <mss:MSSP_Info>
          <mss:MSSP_ID>
            <mss:URI>http://mid.swisscom.ch/</mss:URI>
          </mss:MSSP_ID>
        </mss:MSSP_Info>
        <mss:MobileUser>
          <mss:MSISDN>$SEND_TO</mss:MSISDN>
        </mss:MobileUser>
      </mss:MSS_ProfileReq>
    </MSS_ProfileQuery>
  </soapenv:Body>
</soapenv:Envelope>
End

# Call the service
curl --data "@${SOAP_REQ}" --header "Content-Type: text/xml; charset=utf-8" \
     --cert $CERT_FILE --cacert $CERT_CA --key $CERT_KEY \
     --output $SOAP_REQ.res --trace-ascii $SOAP_REQ.log \
     --silent --connect-timeout $TIMEOUT_CON \
     https://mobileid.swisscom.com/soap/services/MSS_ProfilePort

# Traces
[ -f "$SOAP_REQ" ] && echo "\n>>> $SOAP_REQ <<<" && cat $SOAP_REQ | xmllint --format -
[ -f "$SOAP_REQ.log" ] && echo "\n>>> $SOAP_REQ.log <<<" && cat $SOAP_REQ.log | grep '==\|error'
[ -f "$SOAP_REQ.res" ] && echo "\n>>> $SOAP_REQ.res <<<" && cat $SOAP_REQ.res | xmllint --format -

# Cleanups
[ -f "$SOAP_REQ" ] && rm $SOAP_REQ
[ -f "$SOAP_REQ.log" ] && rm $SOAP_REQ.log
[ -f "$SOAP_REQ.res" ] && rm $SOAP_REQ.res

#==========================================================
