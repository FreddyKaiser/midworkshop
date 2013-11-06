#!/bin/sh
#
# Workshop script to invoke the signing service: asynchron polling
# <MSSP_TransID>

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
SOAP_REQ=$(mktemp /tmp/_tmp.XXXXXX)		# SOAP Request goes here
SEND_TRANSID=$1                                 # Transaction ID
TIMEOUT_REQ=80					# Timeout of the request itself
TIMEOUT_CON=90					# Timeout of the connection to the server

cat > $SOAP_REQ <<End
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope">
  <soapenv:Body>
    <MSS_StatusQuery>
      <mss:MSS_StatusReq MinorVersion="1" MajorVersion="1" MSSP_TransID="$SEND_TRANSID" TimeOut="$TIMEOUT_REQ" xmlns:mss="http://uri.etsi.org/TS102204/v1.1.2#" xmlns:fi="http://mss.ficom.fi/TS102204/v1.0.0#">
        <mss:AP_Info AP_ID="$AP_ID" AP_TransID="$AP_TRANSID" AP_PWD="$AP_PWD" Instant="$AP_INSTANT"/>
            <mss:MSSP_Info>
               <mss:MSSP_ID>
                 <mss:URI>http://mid.swisscom.ch/</mss:URI> </mss:MSSP_ID>
            </mss:MSSP_Info>
         </mss:MSS_StatusReq>
      </MSS_StatusQuery>
   </soapenv:Body>
</soapenv:Envelope>
End

# Call the service
SOAP_ACTION=#MSS_StatusReq
curl --data "@${SOAP_REQ}" --header "Content-Type: text/xml; charset=utf-8" --header "SOAPAction: \"$SOAP_ACTION\"" \
     --cert $CERT_FILE --cacert $CERT_CA --key $CERT_KEY \
     --output $SOAP_REQ.res \
     --silent --connect-timeout $TIMEOUT_CON \
     https://soap.mobileid.swisscom.com/soap/services/MSS_StatusQueryPort

# Traces
[ -f "$SOAP_REQ" ] && echo "\n>>> $SOAP_REQ <<<" && cat $SOAP_REQ | xmlindent
[ -f "$SOAP_REQ.res" ] && echo "\n>>> $SOAP_REQ.res <<<" && cat $SOAP_REQ.res | xmlindent

# Cleanups
[ -f "$SOAP_REQ" ] && rm $SOAP_REQ
[ -f "$SOAP_REQ.res" ] && rm $SOAP_REQ.res

#==========================================================
