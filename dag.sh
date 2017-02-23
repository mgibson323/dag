#!/bin/bash

#Domain At Glance, aka dag
#Use dig, whois, and curl to get a quick overview of a domain's information
#for the purpose of troubleshooting hosting issues with domains.


#Color Codes
GR='\033[32m' #Green
RD='\033[31m' #Red
BL='\033[34m' #Blue
CY='\033[36m' #Cyan
YL='\033[33m' #Yellow 

#Highlights w/ Bold Text
BH='\033[44;1m'     #Blue
MH='\033[45;1m'     #Magenta 
GH='\033[42;1m'     #Green 
RH='\033[41;1m'     #Red     
NC='\033[0m'        #No Color - use to clear

#Add domain and resolver
domain=$(echo "${1}") 
resolv=$(echo "${2}")


#DNS Information
#Get the record and check whois of IP to check where domain is hosting.

dns-info(){
CNAME=$(dig ${domain} +short | grep -E "[a-z]|[A-Z]")
NS=$(dig ${domain} ns +short ${resolv})
A=$(dig ${domain} +short ${resolv})
MX=$(dig ${domain} mx +short ${resolv} | awk '{print $2}')
TXT=$(dig ${domain} txt +short ${resolv})
echo -e "${BH}-------------------------DNS Information for ${domain}-------------------------${NC}"
echo
#Nameservers 
if [[ -z ${CNAME} ]]
then
    if [[ -z ${NS} ]]   #Check for NS, give error/warning if not found
    then
        echo -e "${GR}NS Records for ${domain}${NC}"
        echo -e "${RD}Could not resolve nameservers for ${domain}.\nIf you have entered a subdomain, use dig on the primary for the NS records."
    else
        echo -e "${GR}NS Records for ${domain}${NC}"
        echo
        printf "%s\n" "${NS}"
echo
    fi
else #CNAME can skew results, so let's give a proper warning here. 
    echo -e "${YL}!WARNING! CNAME DETECTED.\nFollowing DNS results not colored in yellow is likely for ${CNAME}${NC}"
    echo
    echo -e "${GR}NS Records${NC}"
    printf "%s\n" "${NS}" | grep -v "${CNAME}" 
    echo
fi
#A|CNAME Records
if [[ -z ${CNAME} ]]
then
    echo -e "${GR}A Records for ${domain}${NC}"
    echo
    for line in ${A}
    do
        aorg=$(whois ${line} | grep -Ew "OrgName:" | perl -ne 'print if $. <= 1' | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
        printf "%-30s | %-15s | %-30s" "${domain}" "${line}" "${aorg}"
        echo
    done  
echo
else
    echo -e "${GR}CNAME Record for ${domain}${NC}"
    echo -e "${YL}"
    printf "%-30s | %-15s | %-30s" "${domain}" "CNAME" "${CNAME}"
    echo -e "${NC}"
    CIP=$(dig ${CNAME} +short)
    for line in ${CIP}
    do
        cwho=$(whois ${line} | grep -Ew "OrgName:" | perl -ne 'print if $. <= 1' | cut -d ':' -f2 | sed -e 's/^[ \t]*//') 
    printf "%-30s | %-15s | %-30s" "${CNAME}" "${CIP}" "${cwho}"
    echo
    done    
echo    
fi
#MX Records
echo -e "${GR}MX Records for ${domain}${NC}"
echo
if [[ -z ${MX} ]]
then
    echo -e "${RD}No MX records found for ${domain}."
else 
    for line in ${MX}
    do
        MXIP=$(dig ${line} +short ${resolv})
        mxwho=$(whois ${MXIP} | grep -Ew "OrgName:" | perl -ne 'print if $. <= 1' | cut -d ':' -f2 | sed -e 's/^[ \t]*//')    
        printf "%-30s | %-15s | %-30s" "${line}" "${MXIP}" "${mxwho}"
        echo
    done
echo
fi
#TXT Records
if [[ -z ${TXT} ]]
then
    echo
else
    echo -e "${GR}TXT Records for ${domain}${NC}"
    printf "%s" "${TXT}"
    echo
fi
echo
}

#WHOIS Information
#Get important details of domain most relevant for troubleshooting issues.
#WHOIS is not uniform, so output may not be ideal. 

who-info(){
whois ${domain} > ~/.whowho.txt
CHK=$(whois ${domain} | grep -w 'Registrant') #Check if domain is registered
CA=$(whois ${domain} | grep -w 'Number:') #Check for .ca TLDs as it has a drastically different format
echo -e "${GH}------------------------WHOIS Information for ${domain}------------------------${NC}"
echo
if [[ -z ${CHK} ]]
then
    echo -e "${RD}Could not obtain WHOIS information for ${domain}.\nIf the domain you entered is valid, try https://whois.icann.org for more accurate results.\nPLEASE NOTE: Subdomains will not return WHOIS information.\nThis part of the script is also not a big fan of foreign and rare TLDs.${NC}"
echo
elif [[ -z ${CA} ]]
then
    echo -e "${CY}Registrar${NC}"
    echo
    grep 'Registrar:' ~/.whowho.txt | cut -d ':' -f2 | sed -e 's/^[ \t]*//'
    grep 'Reseller:'
    echo
    echo -e "${CY}Important Dates${NC}"
    echo
    grep 'Date:' ~/.whowho.txt | sed -e 's/^[ \t]*//'
    echo
    echo -e "${CY}Contact Info${NC}"
    echo
    grep -Ew 'Registrant|Admin' ~/.whowho.txt 
    echo
    echo -e "${CY}Domain Status${NC}"
    echo
    grep 'Domain Status:'~/.whowho.txt | cut -d ':' -f2 | awk '{print $1}' | sed -e 's/^[ \t]*//'
    echo
else
    REG=$(grep -A 1 Registrar ~/.whowho.txt | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
    echo "Registrar: ${REG}"
    echo
    grep -w 'date:' ~/.whowho.txt
    echo
    grep -A 9 'Registrant' ~/.whowho.txt
    echo
fi
rm ~/.whowho.txt
}

#HTTP INFO
#curl for the http response code. If redirect is detected, check http response for redirected url.

http-info(){
STATUS=$(curl -I ${domain} --silent | grep HTTP | tr -d '\r' | cut -d ' ' -f2-5)
SERVER=$(curl -I ${domain} --silent | egrep 'Server')
CODE=$(echo $STATUS | awk '{print $1}')
echo -e "${MH}---------------------------HTTP Status for ${domain}---------------------------${NC}"
echo
if [[ $CODE == 3* ]]
then
    NEW=$(curl -I ${domain} --silent | grep Location | awk '{print $2}' | tr -d '\r')
    NEWSTAT=$(curl -I $NEW --silent | grep HTTP | cut -d ' ' -f2-5)
    NEWCODE=$(echo $NEWSTAT | awk '{print $1}')
    echo -e "${YL}${STATUS} ---> ${NEW}${NC}"
    if [[ $NEWCODE == 2* ]]
    then
        echo -e "${NEW} Status  > ${GR}${NEWSTAT}${NC}"
        echo $SERVER
    else
        echo -e "${NEW} Status > ${RD}${NEWSTAT}${NC}"
        echo $SERVER
    fi
elif [[ $CODE == 2* ]]
then
    echo -e "${GR}$STATUS${NC}"
    echo $SERVER
else
    echo -e "${RD}$STATUS${NC}"
fi
}

#Output everything
dns-info
who-info
http-info
