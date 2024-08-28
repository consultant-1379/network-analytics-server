#!/bin/bash

if [ "$2" == "" ]; then
    	echo usage: $0 \<Branch\> \<RState\>
    	exit -1
else
	versionProperties=install/version.properties
	theDate=\#$(date +"%c")
	module=$1
	branch=$2
	workspace=$3
fi

function getProductNumber {
        product=`cat $workspace/build.cfg | grep $module | grep $branch | awk -F " " '{print $3}'`
}


function setRstate {

        revision=`cat $workspace/build.cfg | grep $module | grep $branch | awk -F " " '{print $4}'`

       	if git tag | grep $product-$revision; then
	        rstate=`git tag | grep $revision | tail -1 | sed s/.*-// | perl -nle 'sub nxt{$_=shift;$l=length$_;sprintf"%0${l}d",++$_}print $1.nxt($2) if/^(.*?)(\d+$)/';`
        else
                ammendment_level=01
                rstate=$revision$ammendment_level
        fi
	echo "Building R-State:$rstate"

}

#function appendRStateToPlatformReleaseXml {

#		versionXml="src/main/resources/version/platform-release.xml"
		
#		if [ ! -e ${versionXml} ] ; then
#			echo "platform version xml file is missing from build: ${versionXml}"
#			exit -1
#		fi

#		mv src/main/resources/version/platform-release.xml src/main/resources/version/platform-release.${rstate}.xml

#}


function nexusDeploy {

	#RepoURL=http://eselivm2v214l.lmera.ericsson.se:8081/nexus/content/repositories/assure-releases
    RepoURL=https://arm1s11-eiffel013.eiffel.gic.ericsson.se:8443/nexus/content/repositories/assure-releases
	GroupId=com.ericsson.eniq
	ArtifactId=$module
	isoName=NetAnServer1205
	
	echo "****"	
	echo "Deploying the iso /$isoName-17.0-B.iso as ${ArtifactId}${rstate}.iso to Nexus...."
        mv target/iso/$isoName-*.iso target/${ArtifactId}.iso
	echo "****"	

  	mvn -B deploy:deploy-file \
	        	-Durl=${RepoURL} \
		        -DrepositoryId=assure-releases \
		        -DgroupId=${GroupId} \
		        -Dversion=${rstate} \
		        -DartifactId=${ArtifactId} \
		        -Dfile=target/${ArtifactId}.iso
		         
 				

}

getProductNumber
setRstate
git checkout $branch
git pull origin $branchgetProductNumber
appendRStateToPlatformReleaseXml

#add maven command here
mvn exec:exec -U

nexusDeploy

rsp=$?

if [ $rsp == 0 ]; then

  git tag $product-$rstate
  git pull
  git push --tag origin $branch

fi

exit $rsp
