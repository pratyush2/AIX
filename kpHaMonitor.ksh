#!/usr/bin/ksh

#
# function definitions
#

function CLstat {
    #
    # using clstat -ao
    #
    if [[ ! -x $clstat ]]
    then
        # $clstat is not executable
        return 1
    fi

    # does $clstat support the -o option?
    out=$($clstat -c $clusterID -ao 2>&1)
    aoRC=$?
    if [[ $aoRC != "0" ]]
    then
        return 1
    fi

    unset recordType data1 data2 data3 data4 data5

    $clstat -c $clusterID -ao | sed -e 's/^[[:space:]]*//; /^$/d; /^---/d' | while read recordType data1 data2 data3 data4 data5
    do
        case $recordType in
             Node:      )
                      # Node record
                      # save the current node name for use with later records
                      currNodeNumber=$(getNodeNumber $data1)
                      # store the current node state
                      nodeState[$currNodeNumber]=$data3
                          ;;
             State:     )
                          # is this a cluster State record?
                      if [[ -n $data3 ]]
                      then
                          # yes it is

#                          # check for specific clstat problems originating on ktazd1913
#                          # is the cluster state DOWN and is the number of nodes 0?
#                          if [[ $data1 = "DOWN" && $data3 = "0" ]]
#                          then
#                              # yes, so exit out of CLstat
#                              return 1
#                          fi

                          clusterState=$data1
                      fi
                      ;;
             SubState:  )
                      # save the substate of the cluster
                      clSubState=$data1
                      ;;
        esac

        # reset variables
        unset recordType data1 data2 data3 data4 data5

    done

    # check for a valid cluster state
    if [[ -z $clusterState || -z $clSubState ]]
    then
        # we did not get the cluster state or substate, which suggests we did not get anything
        return 1
    else
         return 0
    fi
}


function CLstatInt {
    #
    # using clstat -a
    #

    if [[ ! -x $clstat ]]
    then
        # $clstat is not executable - I hope cldump is!!  :-0
        return 1
    fi

    unset recordType data1 data2 data3 data4 data5

    echo q | $clstat -c $clusterID -a 2>&1 | sed -e 's/[[:cntrl:]]/\
/g;s/\[[0-9]\{1,2\}[CD]/ /g; s/\[[0-9]\{1,2\};[0-9]\{1,2\}H/ /g; s/^[[:space:]]*//g' | while read recordType data1 data2 data3 data4 data5
    do
        case $recordType in
             Cluster:   )
                       currentType="CLUSTER"
                       # is this the second time around for the data?
                       if [[ -n $clusterState ]]
                       then
                           # if we have a cluster state, then yes, we are at the start of the duplicate data
                           return 0
                       fi
                      ;;
             Node:      )
                      # Node record
                      # save the current node name for use with later records
                      currNodeNumber=$(getNodeNumber $data1)
                      # set flag to indicate we are reading node info
                      currentType="NODE"
                        ;;
             Interface: )
                      # interface record
                      # save the current interface name for use with later records
                      curInterface=$data1
                      # set flag to indicate we are reading interface info
                      currentType="INTERFACE"
                        ;;
             State:     )
                        case $currentType in
                            CLUSTER   )
                                #cluster State record
                                clusterState=$data1
                            ;;
                            NODE      )
                                # store the current node state
                                nodeState[$currNodeNumber]=$data1
                            ;;
                        esac
                        ;;
             SubState:  )
                       # save the substate of the cluster
                       clSubState=$data1
                        ;;
             Resource   )
                       # set flag to indicate we are reading Resource Group info
                       currentType="Resource"
                        ;;
#             Nodes:      )
#                      # Node count record
#                      # we check this looking for problems with clstat originating on ktazd1913
#                      # is the cluster state DOWN and is the number of nodes 0?
#                      if [[ $data1 = "0" && $clusterState = "DOWN" ]]
#                      then
#                         # yes, so exit out of CLstat
#                          return 1
#                      fi
#                      ;;
        esac

        # reset variables
        unset recordType data1 data2 data3 data4 data5

    done

    # check for a valid cluster state
    if [[ -z $clusterState || -z $clSubState ]]
    then
        # we did not get the cluster state or substate, which suggests we did not get anything
        return 1
    else
        return 0
    fi
}

function CLdump {
    #
    # using cldump
    #

    if [[ ! -x $cldump ]]
    then
        # $cldump is not executable
        return 1
    fi

    unset recordType data1 data2 data3 data4 data5

    $cldump | sed -e 's/^[   ]*//; /^$/d;/^---/d' | while read recordType data1 data2 data3 data4 data5
    do

        # store ticket number keyed by name in appropriate array
        case $recordType in
            Cluster   )
                     # cluster record
                     case $data1 in
                         State:    ) clusterState=$data2 ;;
                         Substate: ) clSubState=$data2   ;;
                     esac
                     ;;
            Node      )
                     # Node record
                     if [[ $data1 = "Name:" ]]
                     then
                         # this is a node name and state record
                         # save the current node name for use with later records
                          currNodeNumber=$(getNodeNumber $data2)
                         # store the current node state
                         nodeState[$currNodeNumber]=$data4
                     fi
                     ;;
        esac

        # reset variables
        unset recordType data1 data2 data3 data4 data5

    done
    # check for a valid cluster name
    if [[ -z $clusterState || -z $clSubState ]]
    then
        # we did not get the cluster state or substate, which suggests we did not get anything
        return 1
    else
        return 0
    fi
}

function Failure {

    print -u2 "All methods FAILED to collect info."
}


function getNodeNumber {

    # search nodeNames array for matching $1 (node name) and return the index of it
    # this is how we implement an associative array for ksh ( for those old AIX 4 boxes without ksh93) ARGH!!!
    let index=0
    while (( index < ${#nodeNames[*]} ))
    do
        # look for node name
        if [[ ${nodeNames[$index]} = $1 ]]
        then
            # we found the matching node name
            print $index
            break
        fi

        let index=$index+1
    done

    return
}

function getInterfaceNumber {

    # search interfaceNames array for matching $1 (interface name) and return the index of it
    # this is how we implement an associative array for ksh ( for those old AIX 4 boxes without ksh93) ARGH!!!
    let index=0
    while (( index < ${#interfaceNames[*]} ))
    do
        # look for node name
        if [[ ${interfaceNames[$index]} = $1 ]]
        then
            # we found the matching node name
            print $index
            break
        fi

        let index=$index+1
    done

    return
}

function printData {

    # print out cluster information
    print "CLUSTER_ID:$clusterID"
    print "CLUSTER_NAME:$clusterName"
    print "CLUSTER_STATE:$clusterState"
    print "CLUSTER_SUBSTATE:$clSubState"
    print "VERSION:$version"
    print "NUMBER_OF_NODES:${#nodeNames[*]}"

    let node=0
    let interfaceCount=1

    # add interface information for each node
    let node=0
    while (( $node < ${#nodeNames[*]} ))
    do
        if [[ -z ${nodeState[$node]} ]]
        then
            nodeState[$node]="UNKNOWN"
        fi

        print "NODE$(($node+1)):${nodeNames[$node]}:${nodeState[$node]}"
        for curInterface in ${interfaceList[$node]}
        do
            # lookup interface number for curInterface
            interfaceNumber=$(getInterfaceNumber $curInterface)
            print "INTERFACE$interfaceCount:${nodeNames[$node]}:$curInterface:${interfaceAddress[$interfaceNumber]}"
            let interfaceCount=$interfaceCount+1
        done

        let node=$node+1
    done

    # print out cluster verification information
    if [[ -z $clVer_hms ]]
    then
        print "CLVERIFICATION_DATE: UNKNOWN"
    else
        print "CLVERIFICATION_DATE:$clVer_hms:$localTimeZone:$clVer_month/$clVer_day/$clVer_year"
    fi

    print "CLVERIFICATION_STATUS:$clVerStatus"
    print "CLVERIFICATION_NODE:$firstNodeName"
    print "CLVERIFICATION_ERRORS:$clVerErrors"

    return
}

function isLeap {

    if ((  $1 % 4  != 0 ))
    then
        #print -u2 not evenly divisible by 4 - not a Leap Year
        return 1
    elif ((  $1 % 400  == 0 ))
    then
        #print -u2 evenly divisible by 400 - Leap Year
        return 0
    elif ((  $1 % 100  == 0 ))
    then
        #print -u2 evenly divisible by 100 - not a Leap Year
        return 1
    else
        #print -u2 leap year!
        return 0
    fi
}

function getEpochSeconds {

    i_hms=$1
    i_month=$2
    i_day=$3
    i_year=$4
    i_timezone=$5

    #calculate the seconds since the Unix epoch for the date/time passed in

    # initialize array of the number of days in each month
    set -A DaysInMonth 0 31 28 31 30 31 30 31 31 30 31 30 31


    # Convert i_month to number
    case $i_month in
        Jan ) i_month=1  ;;
        Feb ) i_month=2  ;;
        Mar ) i_month=3  ;;
        Apr ) i_month=4  ;;
        May ) i_month=5  ;;
        Jun ) i_month=6  ;;
        Jul ) i_month=7  ;;
        Aug ) i_month=8  ;;
        Sep ) i_month=9  ;;
        Oct ) i_month=10 ;;
        Nov ) i_month=11 ;;
        Dec ) i_month=12 ;;
    esac

    # add a day to february if $i_year is a leap year
    if isLeap $i_year
    then
        DaysInMonth[2]=29
    fi

    # split out time components from $i_hms
    hour=$(echo $i_hms | cut -d: -f1)
    min=$(echo $i_hms  | cut -d: -f2)
    sec=$(echo $i_hms  | cut -d: -f3)

    # count leap years before current year
    let count=1972
    let numLeaps=0

    while (( $count < $i_year ))
    do
        if isLeap $count
        then
            let numLeaps=$numLeaps+1
        fi

        let count=$count+4

    done

    # days since the epoch, not counting earlier months this year
    let daycount='(i_year - 1970) * 365 + numLeaps + i_day - 1'

    # Step through earlier months of $i_year and add the days
    let m=$i_month-1
    while (( $m >= 1 ))
    do
        let daycount=$daycount+${DaysInMonth[$m]}
        let m=$m-1
    done

    # Now the seconds
    let epoch='( (daycount * 24 + hour) * 60 + min) * 60 + sec'

    # Add the local time zone offset from GMT that applies

    case $i_timezone in
        GMT ) let epoch='epoch + 0';;
        EDT ) let epoch='epoch + 14400';;
        EST ) let epoch='epoch + 18000';;
        CDT ) let epoch='epoch + 18000';;
        CST ) let epoch='epoch + 21600';;
        MDT ) let epoch='epoch + 21600';;
        MST ) let epoch='epoch + 25200';;
        PDT ) let epoch='epoch + 25200';;
        PST ) let epoch='epoch + 28800';;
        HST ) let epoch='epoch + 36000';;
    esac

    print $epoch
}

function ftpSend {

    fileToSend=$1
    destinationName=$2

    ftp -n $ftpServer <<FTP_SCRIPT_END
user $ftpUser $ftpPass
cd $ftpDest
put $fileToSend $destinationName
site chmod 644 $destinationName
quit
FTP_SCRIPT_END

    return
}

function updateScript {

    # function to update this script
    fileToSync=$1

    # did an update occur?
    let update=0 # this means no

    if [[ -n $(echo $fileToSync | sed -e '/^\//d') ]]
    then
        # fileToSync does not have an absolute path

        # strip out "./" from the beginning, if it exists
        scriptName=$(echo $fileToSync | sed -e 's/^\.\///')

        # use current directory as scriptLocation
        scriptLocation=$PWD

    else

        # strip out path, leaving script name
        scriptName=${fileToSync##/*/}

        # strip out script name, leaving path
        scriptLocation=${fileToSync%%$scriptName}
    fi

    ftp -n $ftpServer <<FTP_MODTIME_END | read fileName modDate modTime modTimezone junk
user $ftpUser $ftpPass
cd $ftpDest
modtime $scriptName
quit
FTP_MODTIME_END

    month=$(echo $modDate | cut -d"/" -f1)
    day=$(echo $modDate   | cut -d"/" -f2)
    year=$(echo $modDate  | cut -d"/" -f3)

    let remoteTimeStamp=$(getEpochSeconds $modTime $month $day $year $modTimezone)

    # get modification time of filename in $1
    istat $fileToSync | grep "modified:" | read junk junk junk month day hms year year2

    # did the istat command return 8 values?
    if [[ -n $year2 ]]
    then
        # yes, because istat is broken for at least AIX5.3 ML3!  ARGH!!
        year=$year2
    fi

    let localTimeStamp=$(getEpochSeconds $hms $month $day $year $localTimeZone)

    if (( remoteTimeStamp > localTimeStamp ))
    then
        # set flag to indicate an update occurred
        update=1

        # remote file is newer than local copy
        print -u2 "getting updated copy of $fileToSync"
        ftp -n $ftpServer 2>&1 >/dev/null <<FTP_UPDATE_END
user $ftpUser $ftpPass
verbose
cd $ftpDest
lcd $scriptLocation
get $scriptName $fileToSync
quit
FTP_UPDATE_END

    fi

    return $update
}


#
# main
#

# add cluster utilities to PATH, just in case
#export PATH=$PATH:/usr/es/sbin/cluster:/usr/es/sbin/cluster/utilities:/usr/sbin/cluster:/usr/sbin/cluster/utilities

# clear verbose flag to minimize output
unset VERBOSE_LOGGING

# maximum time between status file updates in hours
let statusFileUpdateInterval=1

# set minimum time to sleep between status updates in minutes
let minSleepTime=5

# set maximum variation in time to sleep between status updates, in seconds
# this is used to vary the reporting time to prevent flooding the server
let maxVariationTime=30

# ftp information
export ftpServer=aaccoakdev.har.ca.kp.org
export ftpDest=/temp/hacmp_monitor/monitor
export ftpUser=incoming
export ftpPass=kaiser

#export BASE=/misc/hacmp_monitor
export BASE=/var/adm/cfg

# temp file location and name
#export dataFileBASE=/var/adm/cfg/hacmp/monitor
#export tmpFile=$dataFileBASE/failoverTmp.$$
export tmpFile=$BASE/haStatusTmp.$$

# location of file which contains failover Data
#export failoverDataFile=$dataFileBASE/failoverData
export haStatusFile=$BASE/haStatus

let haStatusFileTime=0
export haStatusFileTime

# is the terminal type defined?
if [[ -z $TERM ]]
then
    # no, so define one for clstat to use
    export TERM="vt100"
fi

#
# start of HA monitoring loop
#
while :
do

    # find various cluster utilities
    export clconfig=$(lslpp -f cluster*server.diag | grep clconfig$ | sed -e 's/^[[:space:]]*//g')
    export clshowres=$(lslpp -f cluster*server.utils | grep clshowres$ | sed -e 's/^[[:space:]]*//g')
    export clstat=$(lslpp -f cluster*client.rte | grep /clstat$ | grep -vE "samples|cgi" | sed -e 's/^[[:space:]]*//g')
    export cldump=$(lslpp -f cluster*server.utils | grep cldump$ | sed -e 's/^[[:space:]]*//g')
    export get_local_nodename=$(lslpp -f cluster*server.utils | grep get_local_nodename$ | sed -e 's/^[[:space:]]*//g')
    export clgetactivenodes=$(lslpp -f cluster*server.utils | grep clgetactivenodes$ | sed -e 's/^[[:space:]]*//g')
    # these commands are actually cllscf which only provides their output when called by that name
    # the command to be run is a hard link to cllscf which explains the "cut" after grep
    # way to go IBM!!
    export cllsclstr=$(lslpp -f cluster*server.utils | grep cllsclstr | cut -f1 -d"-" | sed -e 's/^[[:space:]]*//g')
    export clhandle=$(lslpp -f cluster*server.utils | grep clhandle | cut -f1 -d"-" | sed -e 's/^[[:space:]]*//g')
    export cllsif=$(lslpp -f cluster*server.utils | grep cllsif | cut -f1 -d"-" | sed -e 's/^[[:space:]]*//g')

    # determine primary node as we only want one node in the cluster to report in

    # get local node name
    export myNodeName=$($get_local_nodename)

    # reset and export array of node names
    unset nodeNames
    set -A nodeNames
    export nodeNames

    unset clusterState clSubState
    export clusterState clSubState

    # get list of node names from hacmp and keep the first one in the list
    export activeNodes=$($clgetactivenodes -n $myNodeName )
    export allNodes=$($clshowres | grep "^Node Name" | awk '{print $3}' | sort | uniq )
    export firstNodeName=$(echo "$allNodes" | head -1 )

    # is the first node?
    if [[ $myNodeName != $firstNodeName ]]
    then
        # nope!
        export firstNode="FALSE"

    else
        # yes
        export firstNode="TRUE"
    fi

    # is this node in the list of active nodes?
    if [[ -n $firstNodeName && -n $activeNodes && -n $(echo "$activeNodes" | grep $myNodeName) ]]
    then
        # yes
        nodeIsActive="TRUE"
    else
        # no
        nodeIsActive="FALSE"
    fi

    # is this the first node and is it running HA?
    if [[ $firstNode = "TRUE" && -n $(echo "$activeNodes" | grep $firstNodeName) ]]
    then
        # yes
        # set sendHaData to send HA status data from this node
        sendHaData="TRUE"

    # is this not the first node and is it running HA?
    elif [[ $firstNode = "FALSE" && -z $(echo "$activeNodes" | grep $firstNodeName) && -n $(echo "$activeNodes" | grep $myNodeName)  ]]
    then
        # this is not the first node but it is running HA
        # set sendHaData to send HA status data from this node
        sendHaData="TRUE"
    else
        # set sendHaData to NOT send HA status data from this node
        sendHaData="FALSE"
    fi

    # get local timezone
    export localTimeZone=$(date +%Z)

    unset nodeState interfaceList interfaceAddress interfaceNames
    set -A nodeState
    set -A interfaceList
    set -A interfaceAddress
    set -A interfaceNames

    # create haStatusFile if it does not already exist
    if [[ ! -a $haStatusFile ]]
    then
        touch $haStatusFile
    fi

    unset month day hms year year2

    # get the current modification time, in epoch seconds
    istat $haStatusFile | grep "modified:" | read junk junk junk month day hms year year2

        # did the istat command return 8 values?
        if [[ -n $year2 ]]
        then
            # yes, because istat is broken for at least AIX5.3 ML3!  ARGH!!
            year=$year2
        fi

    haStatusFileTime=$(getEpochSeconds $hms $month $day $year $localTimeZone)

    unset month day hms tz year

    # the time stamp is in epoch seconds!
    date | read junk month day hms tz year
    timeStamp=$(getEpochSeconds $hms $month $day $year $tz)

    # use cllsclstr to get cluster ID and NAME
    $cllsclstr -c | grep -vE "^#" | awk -F: '{print $1 " " $2}' | read clusterID clusterName

    export clusterID clusterName

    # is this the first node in the cluster list?
    # the cluster verification log only exists on the first node
    if [[ $firstNode = "TRUE" ]]
    then

        #
        # Check clverify.log for errors
        #

        clVerDir=/var/hacmp/clverify

        # does $clVerDir/clverify.log exist and is it newer than $clVerDir/kpclverify.log
        if [[ -r $clVerDir/clverify.log && $clVerDir/clverify.log -nt $clVerDir/kpclverify.log ]]
        then
            # yes, so use it as the cluster verification log for this cluster
            clVerLogNew=$clVerDir/clverify.log

        # does the $clVerDir/kpclverify.log file exist
        elif [[ -r $clVerDir/kpclverify.log ]]
        then
            # yes, so use it as the cluster verification log for this cluster
            clVerLogNew=$clVerDir/kpclverify.log
        else
            # no cluster verification log exists
            print -u2 "No verification file found. exiting"
            exit 1
        fi

        # export cluster verification variables for printing
        unset  clVer_month clVer_day clVer_hms clVer_year clVerStatus clVerErrors clVerTimeStamp year2
        export clVer_month clVer_day clVer_hms clVer_year clVerStatus clVerErrors clVerTimeStamp

        # read $clVerLogNew to get count of errors from last cluster verification status
        clVerErrors=$(grep ERROR $clVerLogNew | wc -l | sed -e 's/^[[:space:]]*//g')

        #get the date/time of $clVerLogNew
        istat $clVerLogNew | grep "modified:" | read junk junk junk clVer_month clVer_day clVer_hms clVer_year year2

        # did the istat command return 8 values?
        if [[ -n $year2 ]]
        then
            # yes, because istat is broken for at least AIX5.3 ML3!  ARGH!!
            clVer_year=$year2
        fi

        #  calculate timestamp in epoch seconds
        clVerTimeStamp=$(getEpochSeconds $clVer_hms $clVer_month $clVer_day $clVer_year $localTimeZone)

        # Convert clVer_month to number
        case $clVer_month in
            Jan ) clVer_month=1  ;;
            Feb ) clVer_month=2  ;;
            Mar ) clVer_month=3  ;;
            Apr ) clVer_month=4  ;;
            May ) clVer_month=5  ;;
            Jun ) clVer_month=6  ;;
            Jul ) clVer_month=7  ;;
            Aug ) clVer_month=8  ;;
            Sep ) clVer_month=9  ;;
            Oct ) clVer_month=10 ;;
            Nov ) clVer_month=11 ;;
            Dec ) clVer_month=12 ;;
        esac

        # check on the age of the $clVerLogNew file
        if (( timeStamp - clVerTimeStamp > 24 * 60 * 60 ))
        then
            # it is more than 24 hours old
            clVerStatus="Overdue"
        else
            # it is less than 24 hours old
            clVerStatus="Good"
        fi

        #
        # Checking clverify.log for changes
        #

        # the archived copy of the log
        clVerLogOld=/var/adm/cfg/clverify.log

        # has the cluster verification file changed?
        if [[ ! -a $clVerLogOld || -n $( diff $clVerLogNew $clVerLogOld ) ]]
        then
            # yes, the log file has changed so copy it to the archive location
            cp -p $clVerLogNew $clVerLogOld

            # create the destination file name by stripping off the path information
            # and prepending the cluster ID
            destinationName=$clusterID.${clVerLogOld##/*/}

            # send the file to the status server
            ftpSend $clVerLogOld $destinationName
        fi
    fi

    if [[ $sendHaData = "TRUE" ]]
    then

        # get hacmp version
        lslpp -lcq -Or cluster*server.rte 2>/dev/null | cut -d: -f3,7 | sed -e 's/:/\|/' | read version

        export version

        if [[ -z "$version" ]]
        then
            version="Not Found"
        fi

        # use clhandle to get node names
        $clhandle -ac | awk -F: '{print $2}' | while read curNodeName
        do

            currNodeNumber=${#nodeNames[*]}
            nodeNames[$currNodeNumber]=$curNodeName

        done

        unset lastNode

        # use cllsif to get list of interfaces for cluster
        $cllsif -c | grep -vE "^#" |  while read inputLine
        do

            # break out individual fields
            interfaceName=$(echo $inputLine | cut -d: -f 1)
            interfaceType=$(echo $inputLine | cut -d: -f 5)
            node=$(echo $inputLine          | cut -d: -f 6)
            ipAddress=$(echo $inputLine     | cut -d: -f 7)

            if [[ $interfaceType != "serial" ]]
            then

                if [[ -z $node ]]
                then
                    node=$lastNode
                fi

                #if [[ ${interfaceList#$interfaceName} = $interfaceList ]]
                if [[ $(echo $interfaceList | sed -e "s/ $interfaceName //") = $(echo $interfaceList) ]]
                then
                    # interfaceName is not in interfaceList

                    # get index of node name
                    nodeNumber=$(getNodeNumber $node)

                    # add interface to list of interfaces
                    interfaceList[$nodeNumber]="${interfaceList[$nodeNumber]}$interfaceName "

                    interfaceNumber=${#interfaceNames[*]}
                    interfaceNames[$interfaceNumber]=$interfaceName
                    interfaceAddress[$interfaceNumber]=$ipAddress

                    lastNode=$node
                fi
            fi

            unset interfaceName interfaceType node ipAddress
        done

        # get cluster status data
        CLstat || CLstatInt || CLdump || Failure

        # are we runing on the "second" node?
        if [[ $firstNode = "FALSE" ]]
        then
            # cluster verification data will be missing
            clVerErrors="NA"
            clVerStatus="UNKNOWN"
        fi

        # print cluster status data
        printData > $tmpFile

        # create the destination file name by stripping off the path information
        # and prepending the cluster ID
        destinationName=$clusterID.${haStatusFile##/*/}

        # has clstatus changed since the last run?
        if [[ -z $( diff $haStatusFile $tmpFile ) ]]
        then

            # no
            # should we update the file to keep it "fresh"?
            if (( $((timeStamp - haStatusFileTime)) > $(( 0 * 60 * 60 )) )) # convert $statusFileUpdateInterval to seconds
#            if (( $((timeStamp - haStatusFileTime)) > $(( $statusFileUpdateInterval * 60 * 60 )) )) # convert $statusFileUpdateInterval to seconds
            then
                # update the status file
                mv $tmpFile $haStatusFile

                # send the file to the status server
                ftpSend $haStatusFile $destinationName
            fi
        else

            # yes it has, so update the status file
            mv $tmpFile $haStatusFile

            # send the file to the status server
            ftpSend $haStatusFile $destinationName
        fi
    fi

    #
    # update this script if necessary
    #

    # do we need to update this script?
    if ! updateScript $0
    then
        # yes we did, so exit and let init restart the new version
        break
    fi

    # calculate a time to sleep before the next update
    # minSleepTime is in minutes
    # maxVariationTime is in seconds
    let sleepTime='minSleepTime * 60 + (RANDOM * maxVariationTime)/32767'
    sleep $sleepTime

    #
# end of HA monitoring loop
#

done


exit
