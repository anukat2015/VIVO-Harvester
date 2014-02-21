#!/bin/bash
# Copyright (c) 2010-2011 Christopher Haines, Dale Scheppler, Nicholas Skaggs, Stephen V. Williams, James Pence, Michael Barbieri.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the new BSD license
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/bsd-license.html
# 
# Contributors:
#     Christopher Haines, Dale Scheppler, Nicholas Skaggs, Stephen V. Williams, James Pence, Michael Barbieri - initial API and implementation
# set to the directory where the harvester was installed or unpacked
# HARVESTER_INSTALL_DIR is set to the location of the installed harvester
#       If the deb file was used to install the harvester then the
#       directory should be set to /usr/share/vivo/harvester which is the
#       current location associated with the deb installation.
#       Since it is also possible the harvester was installed by
#       uncompressing the tar.gz the setting is available to be changed
#       and should agree with the installation location
#
# QUERIES:
#
# Person Export
# ===========================================
# PREFIX core: <http://vivoweb.org/ontology/core#> 
# PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
# PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
# PREFIX bibo: <http://purl.org/ontology/bibo/> 
# PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#> 
# PREFIX ufVivo: <http://vivo.ufl.edu/ontology/vivo-ufl/>
# PREFIX public: <http://vitro.mannlib.cornell.edu/ns/vitro/public#>
# CONSTRUCT { 
#    ?x ufVivo:ufid ?ufid .
#    ?x rdf:type foaf:Person . 
#    ?x core:primaryEmail ?email . 
#    ?x core:primaryPhoneNumber ?phone . 
#    ?x core:faxNumber ?fax . 
#    ?x foaf:firstName ?fname . 
#    ?x foaf:lastName ?lname . 
#    ?x core:middleName ?mname . 
#    ?x bibo:prefixName ?prename . 
#    ?x bibo:suffixName ?suffname . 
#    ?x rdfs:label ?label . 
#    ?x ufVivo:gatorlink ?glid . 
#    ?x core:preferredTitle ?preftitle . 
#    ?x ufVivo:homeDept ?dept . 
#    ?x ufVivo:privacyFlag ?flag .
#    ?x public:mainImage ?img .
# } 
# WHERE { 
#    ?x ufVivo:ufid ?ufid .
#    OPTIONAL{?x core:primaryEmail ?email .} 
#    OPTIONAL{?x core:primaryPhoneNumber ?phone . } 
#    OPTIONAL{?x core:faxNumber ?fax . } 
#    OPTIONAL{?x foaf:firstName ?fname . } 
#    OPTIONAL{?x foaf:lastName ?lname . } 
#    OPTIONAL{?x core:middleName ?mname . } 
#    OPTIONAL{?x bibo:prefixName ?prename . } 
#    OPTIONAL{?x bibo:suffixName ?suffname . } 
#    OPTIONAL{?x rdfs:label ?label . } 
#    OPTIONAL{?x ufVivo:gatorlink ?glid . } 
#    OPTIONAL{?x core:preferredTitle ?preftitle .} 
#    OPTIONAL{?x ufVivo:homeDept ?dept . } 
#    OPTIONAL{?x ufVivo:privacyFlag ?flag . }
# }
#
# Department Export
# =================
# PREFIX core: <http://vivoweb.org/ontology/core#> 
# PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
# PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
# PREFIX bibo: <http://purl.org/ontology/bibo/> 
# PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#> 
# PREFIX ufVivo: <http://vivo.ufl.edu/ontology/vivo-ufl/> 
# CONSTRUCT { 
#    ?x ufVivo:deptID ?y .
# } 
# WHERE { 
#    ?x ufVivo:deptID ?y .
# }

# Image Export
# ================
# PREFIX core: <http://vivoweb.org/ontology/core#> 
# PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
# PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
# PREFIX bibo: <http://purl.org/ontology/bibo/> 
# PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#> 
# PREFIX ufVivo: <http://vivo.ufl.edu/ontology/vivo-ufl/> 
# PREFIX public: <http://vitro.mannlib.cornell.edu/ns/vitro/public#>
# CONSTRUCT { 
#    ?x ufVivo:ufid ?ufid .
#    ?x public:mainImage ?img .
#    ?img ?p ?o .
#    ?o ?p2 ?o2 . 
#    ?o2 ?p3 ?o3 .
#    ?o3 ?p4 ?o4 .
#    ?o4 ?p5 ?o5 .
# } 
# WHERE { 
#    ?x ufVivo:ufid ?ufid .
#    OPTIONAL{
#        ?x public:mainImage ?img .
#        OPTIONAL { ?img ?p ?o .
#        OPTIONAL { ?o ?p2 ?o2 .
#        OPTIONAL { ?o2 ?p3 ?o3 .
#        OPTIONAL { ?o3 ?p4 ?o4 .
#        OPTIONAL { ?o4 ?p5 ?o5 .
#        }}}}}
# }

export HARVESTER_INSTALL_DIR=/data/vivo/harvester/harvester_1.3
export HARVEST_NAME=people-seeding
export DATE=`date +%Y-%m-%d'T'%T`

# Add harvester binaries to path for execution
# The tools within this script refer to binaries supplied within the harvester
#       Since they can be located in another directory their path should be
#       included within the classpath and the path environment variables.
export PATH=$PATH:$HARVESTER_INSTALL_DIR/bin
export CLASSPATH=$CLASSPATH:$HARVESTER_INSTALL_DIR/bin/harvester.jar:$HARVESTER_INSTALL_DIR/bin/dependency/*
export CLASSPATH=$CLASSPATH:$HARVESTER_INSTALL_DIR/build/harvester.jar:$HARVESTER_INSTALL_DIR/build/dependency/*

# Create ufids.txt if it does not exist.
if [ ! -d ufids.txt ]; then
  touch ufids.txt
fi

# Create deptids.txt if it does not exist.
if [ ! -d deptids.txt ]; then
  touch deptids.txt
fi

# Create temp RDF/XML directories if they do not exist.
if [ ! -d data/temp-people-rdfxml ]; then
  mkdir data/temp-people-rdfxml
fi
if [ ! -d data/temp-image-rdfxml ]; then
  mkdir data/temp-image-rdfxml
fi

# Pull UFIDs from translated records.
grep -ho "ufid>[0-9]\{8\}" data/translated-records/* | grep -ho "[0-9]\{8\}" > ufids.txt

# Pull DeptIDs from translated records.
grep -ho "deptID>[0-9]\{8\}" data/translated-records/* | grep -ho "[0-9]\{8\}" > deptids.txt

# For each UFID in ufids.txt
for line in $(< ufids.txt); do
   # Person Export from VIVO with that UFID
   echo "Exporting Person UFID $line"
   harvester-jenaconnect -j vivo.model.xml -q "PREFIX core: <http://vivoweb.org/ontology/core#> PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> PREFIX bibo: <http://purl.org/ontology/bibo/> PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#> PREFIX ufVivo: <http://vivo.ufl.edu/ontology/vivo-ufl/> PREFIX public: <http://vitro.mannlib.cornell.edu/ns/vitro/public#> CONSTRUCT { ?x ufVivo:ufid \"$line\" . ?x a foaf:Person . ?x core:primaryEmail ?email . ?x core:primaryPhoneNumber ?phone . ?x core:faxNumber ?fax . ?x foaf:firstName ?fname . ?x foaf:lastName ?lname . ?x core:middleName ?mname . ?x bibo:prefixName ?prename . ?x bibo:suffixName ?suffname . ?x rdfs:label ?label . ?x ufVivo:gatorlink ?glid . ?x core:preferredTitle ?preftitle . ?x ufVivo:homeDept ?dept . ?x ufVivo:privacyFlag ?flag . } WHERE { ?x ufVivo:ufid \"$line\" . OPTIONAL{?x core:primaryEmail ?email .} OPTIONAL{?x core:primaryPhoneNumber ?phone . } OPTIONAL{?x core:faxNumber ?fax . } OPTIONAL{?x foaf:firstName ?fname . } OPTIONAL{?x foaf:lastName ?lname . } OPTIONAL{?x core:middleName ?mname . } OPTIONAL{?x bibo:prefixName ?prename . } OPTIONAL{?x bibo:suffixName ?suffname . } OPTIONAL{?x rdfs:label ?label . } OPTIONAL{?x ufVivo:gatorlink ?glid . } OPTIONAL{?x core:preferredTitle ?preftitle . } OPTIONAL{?x ufVivo:homeDept ?dept . } OPTIONAL{?x ufVivo:privacyFlag ?flag . } }" > data/temp-people-rdfxml/People_$line.xml

  # Image Export from VIVO with that UFID
  echo "Exporting Images associated with UFID $line"
  harvester-jenaconnect -j vivo.model.xml -q "PREFIX core: <http://vivoweb.org/ontology/core#> PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> PREFIX bibo: <http://purl.org/ontology/bibo/> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> PREFIX ufVivo: <http://vivo.ufl.edu/ontology/vivo-ufl/> PREFIX public: <http://vitro.mannlib.cornell.edu/ns/vitro/public#> CONSTRUCT { ?x ufVivo:ufid \"$line\" . ?x public:mainImage ?img . ?img ?p ?o . ?o ?p2 ?o2 . ?o2 ?p3 ?o3 . ?o3 ?p4 ?o4 . ?o4 ?p5 ?o5 . } WHERE { ?x ufVivo:ufid \"$line\" . OPTIONAL{ ?x public:mainImage ?img . OPTIONAL { ?img ?p ?o . OPTIONAL { ?o ?p2 ?o2 . OPTIONAL { ?o2 ?p3 ?o3 . OPTIONAL { ?o3 ?p4 ?o4 . OPTIONAL { ?o4 ?p5 ?o5 . }}}}}} }" > data/temp-image-rdfxml/Image_$line.xml

done

# For each deptID in deptids.txt
for line in $(< deptids.txt); do
  # Department Export from VIVO with that deptID
  echo "Exporting Department deptID $line"
  harvester-jenaconnect -j vivo.model.xml -q "PREFIX core: <http://vivoweb.org/ontology/core#> PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> PREFIX bibo: <http://purl.org/ontology/bibo/> PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#> PREFIX ufVivo: <http://vivo.ufl.edu/ontology/vivo-ufl/> CONSTRUCT { ?x ufVivo:deptID \"$line\" . } WHERE { ?x ufVivo:deptID \"$line\" . }" > data/temp-people-rdfxml/Departments_$line.xml 
done

# Load People and Department RDF/XML into previous-data-state Model then copy into proxy VIVO.
for f in data/temp-people-rdfxml/*; do
   # Check size of People Export, if 513b then skip it
   FILESIZE=$(stat -c %s "$f")
   #echo $FILESIZE
   if [ $FILESIZE -ne 513 ]; then
      if [ $FILESIZE -ne 0 ]; then
         harvester-transfer -o previous-data-state.model.xml -r $f -R RDF/XML
      fi
   fi
done

harvester-transfer -i previous-data-state.model.xml -o proxy-vivo.model.xml

# Load Image RDF/XML into VIVO Model. Image data must not exist in previous-data-state, 
# or else it will be wrongly subtracted.
for f in data/temp-image-rdfxml/* do
   # Check size of People Export, if 513b then skip it
   FILESIZE=$(stat -c %s "$f")
   #echo $FILESIZE
   if [ $FILESIZE -ne 513 ]; then
      if [ $FILESIZE -ne 0 ]; then
         harvester-transfer -o proxy-vivo.model.xml -r $f -R RDF/XML
      fi
   fi
done

# Clean up temp data.
if [ -d data/temp-people-rdfxml ]; then
   rm -rf data/temp-people-rdfxml
fi

if [ -d data/temp-image-rdfxml ]; then
   rm -rf data/temp-image-rdfxml
fi

#rm -rf ufids.txt
#rm -rf deptids.txt

harvester-transfer -i previous-data-state.model.xml -d data/completeOutput.xml


