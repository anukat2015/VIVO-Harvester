#!/bin/bash

# Copyright (c) 2010 Christopher Haines, Dale Scheppler, Nicholas Skaggs, Stephen V. Williams.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the new BSD license
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/bsd-license.html
# 
# Contributors:
#     Christopher Haines, Dale Scheppler, Nicholas Skaggs, Stephen V. Williams - initial API and implementation

# Set working directory
cd `dirname $(readlink -f $0)`
cd ..

HARVESTER_TASK=pubmed

#variables for model arguments
INPUT="-i config/jenaModels/h2.xml -I dbUrl=jdbc:h2:XMLVault/h2Pubmed/all/store;MODE=HSQLDB -I modelName=Pubmed"
OUTPUT="-o config/jenaModels/h2.xml -O modelName=Pubmed -O dbUrl=jdbc:h2:XMLVault/h2Pubmed/all/store;MODE=HSQLDB"
VIVO="-v config/jenaModels/VIVO.xml"
SCORE="-s config/jenaModels/h2.xml -S dbUrl=jdbc:h2:XMLVault/h2Pubmed/score/store;MODE=HSQLDB -S modelName=PubmedScore"
MATCHEDINPUT="-i config/jenaModels/h2.xml -I modelName=PubmedScore -I dbUrl=jdbc:h2:XMLVault/h2Pubmed/score/store;MODE=HSQLDB"

#variables for scoring
WORKEMAIL="-A wEmail=org.vivoweb.harvester.score.algorithm.NormalizedLevenshteinDifference -F wEmail=http://vivoweb.org/ontology/core#workEmail -W wEmail=.4 -P wEmail=http://vivoweb.org/ontology/score#workEmail"
FNAME="-A fName=org.vivoweb.harvester.score.algorithm.NormalizedLevenshteinDifference -F fName=http://xmlns.com/foaf/0.1/firstName -W fName=.2 -P fName=http://vivoweb.org/ontology/score#foreName"
LNAME="-A lName=org.vivoweb.harvester.score.algorithm.NormalizedLevenshteinDifference -F lName=http://xmlns.com/foaf/0.1/lastName -W lName=.3 -P lName=http://xmlns.com/foaf/0.1/lastName"
MNAME="-A mName=org.vivoweb.harvester.score.algorithm.NormalizedLevenshteinDifference -F mName=http://vivoweb.org/ontology/core#middleName -W mName=.1 -P mName=http://vivoweb.org/ontology/score#middleName"

if [ -f scripts/env ]; then
  . scripts/env
else
  exit 1
fi

#clear old fetches
rm -rf XMLVault/h2Pubmed/XML

# Execute Fetch for Pubmed
$PubmedFetch -X config/tasks/PubmedFetch.xml

# backup fetch
date=`date +%Y-%m-%d_%T`
tar -czpf backups/.$date.tar.gz XMLVault/h2Pubmed/XML
rm -rf backups/pubmed.xml.latest.tar.gz
ln -s pubmed.xml.$date.tar.gz backups/pubmed.xml.latest.tar.gz
# uncomment to restore previous fetch
#tar -xzpf backups/pubmed.xml.latest.tar.gz XMLVault/h2Pubmed/XML

# clear old translates
rm -rf XMLVault/h2Pubmed/RDF

# Execute Translate using the PubmedToVIVO.xsl file
$XSLTranslator -i config/recordHandlers/Pubmed-XML-h2RH.xml -x config/datamaps/PubmedToVivo.xsl -o config/recordHandlers/Pubmed-RDF-h2RH.xml

# backup translate
date=`date +%Y-%m-%d_%T`
tar -czpf backups/pubmed.rdf.$date.tar.gz XMLVault/h2Pubmed/RDF
rm -rf backups/pubmed.rdf.latest.tar.gz
ln -s pubmed.rdf.$date.tar.gz backups/pubmed.rdf.latest.tar.gz
# uncomment to restore previous translate
#tar -xzpf backups/pubmed.rdf.latest.tar.gz XMLVault/h2Pubmed/RDF

# Clear old H2 models
rm -rf XMLVault/h2Pubmed/all

# Execute Transfer to import from record handler into local temp model
$Transfer $OUTPUT -h config/recordHandlers/Pubmed-RDF-h2RH.xml

# backup H2 translate Models
date=`date +%Y-%m-%d_%T`
tar -czpf backups/pubmed.all.$date.tar.gz XMLVault/h2Pubmed/all
rm -rf backups/pubmed.all.latest.tar.gz
ln -s ps.all.$date.tar.gz backups/pubmed.all.latest.tar.gz
# uncomment to restore previous H2 translate models
#tar -xzpf backups/pubmed.all.latest.tar.gz XMLVault/h2Pubmed/all

# clear old score models
rm -rf XMLVault/h2Pubmed/score

# Execute Score to disambiguate data in "scoring" JENA model
$Score $VIVO $INPUT $SCORE $WORKEMAIL
#$Score $VIVO $INPUT $SCORE $FNAME
#$Score $VIVO $INPUT $SCORE $LNAME
#$Score $VIVO $INPUT $SCORE $MNAME

# Execute match to match and link data into "vivo" JENA model
$Match $INPUT $SCORE -t .5
 
# back H2 score models
date=`date +%Y-%m-%d_%T`
tar -czpf backups/pubmed.scored.$date.tar.gz XMLVault/h2Pubmed/scored
rm -rf backups/pubmed.scored.latest.tar.gz
ln -s ps.scored.$date.tar.gz backups/pubmed.scored.latest.tar.gz
# uncomment to restore previous H2 score models
#tar -xzpf backups/pubmed.scored.latest.tar.gz XMLVault/h2Pubmed/scored

# Execute Qualify - depending on your data source you may not need to qualify follow the below examples for qualifying
# Off by default, examples show below
#$Qualify -j config/jenaModels/VIVO.xml -t "Prof" -v "Professor" -d http://vivoweb.org/ontology/core#Title
#$Qualify -j config/jenaModels/VIVO.xml -r .*JAMA.* -v "The Journal of American Medical Association" -d http://vivoweb.org/ontology/core#Title

# Execute ChangeNamespace to get into current namespace
$ChangeNamespace $VIVO $MATCHEDINPUT -n http://vivo.ufl.edu/individual/ -o http://vivoweb.org/harvest/pubmedPub/
$ChangeNamespace $VIVO $MATCHEDINPUT -n http://vivo.ufl.edu/individual/ -o http://vivoweb.org/harvest/pubmedAuthorship/
$ChangeNamespace $VIVO $MATCHEDINPUT -n http://vivo.ufl.edu/individual/ -o http://vivoweb.org/harvest/pubmedAuthor/
$ChangeNamespace $VIVO $MATCHEDINPUT -n http://vivo.ufl.edu/individual/ -o http://vivoweb.org/harvest/pubmedJournal/
