#!/bin/sh
#
# Workshop script to invoke the signing service: polling
# Parameters are <MSSP_TransID>

PWD=$(dirname $0)				      # Get the Path of the script

AP_ID=mid://dev.swisscom.ch   # AP ID
AP_PWD=disabled					      # AP Password must be present but is not validated
CERT_FILE=$PWD/mycert.crt			# The certificate that is allowed to access the service
CERT_KEY=$PWD/mycert.key			# The related key of the certificate
CERT_CA=$PWD/mobileid-ca-ssl.crt  # Bag file with the server/client issuing and root certifiates

SEND_TRANSID=$1               # MSSP Transaction ID
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
    xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope"
    xmlns:mss="http://uri.etsi.org/TS102204/v1.1.2#">
  <soapenv:Body>
    <MSS_StatusQuery>
      <mss:MSS_StatusReq MinorVersion="1" MajorVersion="1" MSSP_TransID="$SEND_TRANSID">
        <mss:AP_Info AP_ID="$AP_ID" AP_TransID="$AP_TRANSID" AP_PWD="$AP_PWD" Instant="$AP_INSTANT"/>
            <mss:MSSP_Info>
               <mss:MSSP_ID>
                 <mss:URI>http://mid.swisscom.ch/</mss:URI>
               </mss:MSSP_ID>
            </mss:MSSP_Info>
         </mss:MSS_StatusReq>
      </MSS_StatusQuery>
   </soapenv:Body>
</soapenv:Envelope>
End

# Call the service
curl --data "@${SOAP_REQ}" --header "Content-Type: text/xml; charset=utf-8" \
     --cert $CERT_FILE --cacert $CERT_CA --key $CERT_KEY \
     --output $SOAP_REQ.res \
     --silent --connect-timeout $TIMEOUT_CON \
     https://mobileid.swisscom.com/soap/services/MSS_StatusQueryPort

# Traces
[ -f "$SOAP_REQ" ] && echo "\n>>> $SOAP_REQ <<<" && cat $SOAP_REQ | xmllint --format -
[ -f "$SOAP_REQ.res" ] && echo "\n>>> $SOAP_REQ.res <<<" && cat $SOAP_REQ.res | xmllint --format -

# Cleanups
[ -f "$SOAP_REQ" ] && rm $SOAP_REQ
[ -f "$SOAP_REQ.res" ] && rm $SOAP_REQ.res

#==========================================================
