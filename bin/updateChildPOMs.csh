#!/bin/tcsh -f

onintr CLEANUP
set UPDATESCRIPT="/tmp/updateChildPOMs.$$"
set CHECKSCRIPT="/tmp/checkChildPOMs.$$"
set TMPFILE="/tmp/gitoutput.$$"

###============================================

if ( $#argv < 1 ) then
    echo "Usage:	$0 /mnt/development/src/org.ASUX  " >>& /dev/stderr
    echo "	The only argument MUST be == org.ASUX TOPMOST-Folder  " >>& /dev/stderr
    echo '' >>& /dev/stderr
    exit 1
endif
set ORGASUXFLDR="$1"
if ( ! -e "${ORGASUXFLDR}/." ) then
	echo "\!\!\! ERROR \!\!\! The folder-path passed as cmd-line argument is INVALID \!\!\!\!\!\!\!\!\! ==>> $1"
	exit 2
endif

##------------------------------
source "${ORGASUXFLDR}/bin/ListOfAllProjects.csh-source"

if ( $?IGNOREERRORS ) echo .. hmmm .. ignoring any errors ({IGNOREERRORS} is set)

echo ''
echo 'Do Manually:>		mvn -f pom-TopLevelParent.xml clean package install:install'
echo 'Do Manually:>		mvn -f pom-MavenCentralRepo-TopLevelParent.xml clean deploy'
echo ''
echo '\!\!\! ATTENTION: Note the difference in MAVEN-targets in the above \!\!'
echo ''

set ANS='?'
while ( "$ANS" != "y" )
	echo -n "Continue? (or, press Cntl-C).. .. (y/n) :> "; set ANS=$<
end

##---------------------------------------------
###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##---------------------------------------------

### 3 FOREACH loops below: $RENAMED_PROJECTS $ASIS_PROJECTS $PROJECTS

### So.. putting common code - for the 3 foreach-loops into a temp file.
	set ESCAPEDEXPRESSION_1='$PROJECT_LIST'
	set ESCAPEDEXPRESSION_2='${FLDR}'
	# set ESCAPEDEXPRESSION_3='${isChanged}'
	# set BACKQUOTE_PART1='git diff pom.xml '
	# set BACKQUOTE_PART2='git diff pom-MavenCentralRepo.xml '
	# set BACKQUOTE_COMMON='| wc -l'

	set MYPID=`ps -p $$ -oppid=`	### On MacOS Shell, 'ps --pid' does _NOT_ work.  Instead using 'ps -p'
				### Warning.  Within TCSH, the above will kill the SHELL from which this script is run!!!
	set MYPID=$$	### On MacOS Shell, 'ps --pid' does _NOT_ work.  Instead using 'ps -p'

###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

cat >! ${CHECKSCRIPT} <<EOTXT
echo "	.. .. ${ESCAPEDEXPRESSION_1} .. .."
foreach FLDR ( ${ESCAPEDEXPRESSION_1} )

	if ( -e "${ESCAPEDEXPRESSION_2}" ) then
		chdir "${ESCAPEDEXPRESSION_2}"
		pwd
		if ( ! -e "pom.xml" ) continue
		echo -n git diff pom.xml
		git diff pom-MavenCentralRepo.xml > ${TMPFILE}
		if (  ! -z "${TMPFILE}" ) then
			echo ''; echo ''
			echo "Oh\!oh\! First commit the changes to this file.. before attempting to update it's Parent-POM's version \!\!\!"
			echo ''; echo ''
			kill -USR1 -${MYPID}
			sleep 200
			exit 9
		endif
		echo ' .. OK'

		if ( ! -e "pom-MavenCentralRepo.xml" ) continue
		echo -n git diff pom-MavenCentralRepo.xml
		git diff pom-MavenCentralRepo.xml > ${TMPFILE}
		if (  ! -z "${TMPFILE}" ) then
			echo ''; echo ''
			echo "Oh\!oh\! First commit the changes to this file.. before attempting to update it's Parent-POM's version \!\!\!"
			echo ''; echo ''
			kill -USR1 -${MYPID}
			sleep 200
			exit 10
		endif
		echo ' .. OK'
		echo ''
	else
		echo "  ${ESCAPEDEXPRESSION_2} "' is MISSING \!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\! (1)'
	endif

end
EOTXT

###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

cat >! ${UPDATESCRIPT} <<EOTXT
echo "	.. .. ${ESCAPEDEXPRESSION_1} .. .."
foreach FLDR ( ${ESCAPEDEXPRESSION_1} )

	if ( -e "${ESCAPEDEXPRESSION_2}" ) then
		chdir "${ESCAPEDEXPRESSION_2}"
		pwd
		if ( ! -e "pom.xml" ) continue
		echo \
		mvn -f pom.xml versions:update-parent
		mvn -f pom.xml versions:update-parent
		git commit -m "[Upgrade] Parent-POM(pom-TopLevelParent.xml) upgraded to new verion ${PARENTPOMVERSION}" pom.xml

		if ( ! -e "pom-MavenCentralRepo.xml" ) continue
		echo \
		mvn -f pom-MavenCentralRepo.xml versions:update-parent
		mvn -f pom-MavenCentralRepo.xml versions:update-parent
		git commit -m "[Upgrade] Parent-POM(pom-MavenCentralRepo-TopLevelParent.xml) upgraded to new verion ${REPOPARENTPOMVERSION}" pom-MavenCentralRepo.xml
		echo ''
	else
		echo "  ${ESCAPEDEXPRESSION_2} "' is MISSING \!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\!\! (1)'
	endif

	sleep 1
end
EOTXT

###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

chmod u+rwx ${CHECKSCRIPT}
chmod u+rwx ${UPDATESCRIPT}

##---------------------------------------------
###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##---------------------------------------------
### First check if ANY of the POM files are already modified.
### This script should NOT update ANY POM file unless that POM-file is already git-committed

# set PROJECT_LIST=( $RENAMED_PROJECTS )
# set PROJECT_LIST=( $ASIS_PROJECTS )

set PROJECT_LIST=( $PROJECTS )
source ${CHECKSCRIPT}
sleep 1

##---------------------------------------------
###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##---------------------------------------------
### Now update the Child POMs

set ANS='?'
while ( "$ANS" != "y" )
	echo -n "Continue? (or, press Cntl-C).. .. (y/n) :> "; set ANS=$<
end

# set PROJECT_LIST=( $RENAMED_PROJECTS )
# set PROJECT_LIST=( $ASIS_PROJECTS )

set PROJECT_LIST=( $PROJECTS )
source ${UPDATESCRIPT}
sleep 1

##---------------------------------------------
###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##---------------------------------------------

set EXITSTATUS=$status
##---------------------------------------------
### ATTENTION: onintr will jump to here.
CLEANUP:
set EXITSTATUS=99
\rm -f "${UPDATESCRIPT}"
\rm -f "${CHECKSCRIPT}"
\rm -f "${TMPFILE}"

exit $EXITSTATUS

#EoScript

#EoScript
