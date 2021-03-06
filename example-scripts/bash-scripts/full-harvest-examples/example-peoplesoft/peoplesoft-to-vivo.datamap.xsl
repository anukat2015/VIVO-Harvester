<!--
  Copyright (c) 2010-2011 VIVO Harvester Team. For full list of contributors, please see the AUTHORS file provided.
  All rights reserved.
  This program and the accompanying materials are made available under the terms of the new BSD license which accompanies this distribution, and is available at http://www.opensource.org/licenses/bsd-license.html
-->
<!-- <?xml version="1.0"?> -->
<!-- Header information for the Style Sheet
	The style sheet requires xmlns for each prefix you use in constructing
	the new elements
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:core="http://vivoweb.org/ontology/core#"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:ufVivo="http://vivo.ufl.edu/ontology/vivo-ufl/"
	xmlns:db-people="http://vivo.ufl.edu/ingested/peoplesoft/fields/people/"
	xmlns:db-positions="http://vivo.ufl.edu/ingested/peoplesoft/fields/positions/"
	xmlns:score='http://vivoweb.org/ontology/score#'
	xmlns:bibo='http://purl.org/ontology/bibo/'
	xmlns:rdfs='http://www.w3.org/2000/01/rdf-schema#'>
<!--
	xmlns:db-people="jdbc:jtds:sqlserver://erp-prod-odbc.ad.ufl.edu:1433/ODBCWH;domain=UFAD/fields/people/"
	xmlns:db-positions="jdbc:jtds:sqlserver://erp-prod-odbc.ad.ufl.edu:1433/ODBCWH;domain=UFAD/fields/positions/"
-->
	<!-- This will create indenting in xml readers -->
	<xsl:output method="xml" indent="yes"/>
	<xsl:variable name="baseURI">http://vivo.ufl.edu/translated/peoplesoft/</xsl:variable>

	<!-- The main node of the record loaded 
		This serves as the header of the RDF file produced
	 -->
	<xsl:template match="rdf:RDF">
		<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
			xmlns:vitro="http://vitro.mannlib.cornell.edu/ns/vitro/public#"
			xmlns:ufl="http://vivo.ufl.edu/ontology/vivo-ufl/"
			xmlns:db-people="http://vivo.ufl.edu/ingested/peoplesoft/fields/people/"
			xmlns:db-positions="http://vivo.ufl.edu/ingested/peoplesoft/fields/positions/"
			xmlns:foaf="http://xmlns.com/foaf/0.1/"
			xmlns:owl="http://www.w3.org/2002/07/owl#"
			xmlns:core="http://vivoweb.org/ontology/core#"
			xmlns:score="http://vivoweb.org/ontology/score#"
			xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" >
			<xsl:apply-templates select="rdf:Description" />
		</rdf:RDF>
	</xsl:template>
	
	<xsl:template match="rdf:Description">
		<xsl:variable name="this" select="." />
		<xsl:variable name="table">
			<xsl:analyze-string select="../@xml:base" regex="^.*/([^/]+?)$">
				<xsl:matching-substring>
					<xsl:value-of select="regex-group(1)" />
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$table = 'people'">
				<xsl:call-template name="people">
					<xsl:with-param name="this" select="$this" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$table = 'positions'">
				<xsl:call-template name="positions">
					<xsl:with-param name="this" select="$this" />
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="people">
		<xsl:param name='this' />
		<xsl:variable name="ufid" select="$this/db-people:UFID"/>
		<rdf:Description rdf:about="{$baseURI}person/ufid{$ufid}">
			<ufVivo:ufid><xsl:value-of select="$ufid"/></ufVivo:ufid>
			<ufVivo:harvestedBy>PeopleSoft-Harvester</ufVivo:harvestedBy>
			<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
			<core:email><xsl:value-of select="$this/db-people:EMAIL" /></core:email>
			<xsl:if test="normalize-space( $this/db-people:PHONE_AREA ) or normalize-space( $this/db-people:PHONE_NUM )">
				<core:phoneNumber>
					<xsl:if test="normalize-space( $this/db-people:PHONE_AREA )">
						<xsl:value-of select="$this/db-people:PHONE_AREA"/>
					</xsl:if>
					<xsl:if test="normalize-space( $this/db-people:PHONE_AREA ) and normalize-space( $this/db-people:PHONE_NUM )">
						<xsl:text>-</xsl:text>
					</xsl:if>
					<xsl:if test="normalize-space( $this/db-people:PHONE_NUM )">
						<xsl:analyze-string select="$this/db-people:PHONE_NUM" regex="^(...)(....).*?$">
							<xsl:matching-substring>
								<xsl:value-of select="regex-group(1)"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="regex-group(2)"/>
							</xsl:matching-substring>
						</xsl:analyze-string>
					</xsl:if>
				</core:phoneNumber>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:FAX_AREA ) or normalize-space( $this/db-people:FAX_NUM )">
				<core:faxNumber>
					<xsl:if test="normalize-space( $this/db-people:FAX_AREA )">
						<xsl:value-of select="$this/db-people:FAX_AREA"/>
					</xsl:if>
					<xsl:if test="normalize-space( $this/db-people:FAX_AREA ) and normalize-space( $this/db-people:FAX_NUM )">
						<xsl:text>-</xsl:text>
					</xsl:if>
					<xsl:if test="normalize-space( $this/db-people:FAX_NUM )">
						<xsl:analyze-string select="$this/db-people:FAX_NUM" regex="^(...)(....).*?$">
							<xsl:matching-substring>
								<xsl:value-of select="regex-group(1)"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="regex-group(2)"/>
							</xsl:matching-substring>
						</xsl:analyze-string>
					</xsl:if>
				</core:faxNumber>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:FNAME )">
				<foaf:firstName><xsl:value-of select="$this/db-people:FNAME"/></foaf:firstName>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:LNAME )">
				<foaf:lastName><xsl:value-of select="$this/db-people:LNAME"/></foaf:lastName>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:MNAME )">
				<core:middleName><xsl:value-of select="$this/db-people:MNAME"/></core:middleName>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:PRENAME )">
				<bibo:prefixName><xsl:value-of select="$this/db-people:PRENAME"/></bibo:prefixName>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:SUFNAME )">
				<bibo:suffixName><xsl:value-of select="$this/db-people:SUFNAME"/></bibo:suffixName>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:FULLNAME )">
				<rdfs:label><xsl:value-of select="$this/db-people:FULLNAME"/></rdfs:label>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:GATORLINK )">
				<ufVivo:gatorlink rdf:datatype="http://www.w3.org/2001/XMLSchema#string"><xsl:value-of select="$this/db-people:GATORLINK"/></ufVivo:gatorlink>
			</xsl:if>
			<xsl:if test="normalize-space( $this/db-people:TITLE )">
				<core:preferredTitle><xsl:value-of select="$this/db-people:TITLE"/></core:preferredTitle>
			</xsl:if>
		</rdf:Description>
	</xsl:template>
	
	<xsl:template name="positions">
		<xsl:param name='this' />
		<xsl:variable name="ufid" select="$this/db-positions:UFID"/>
		<xsl:variable name="fullorgnum" select="$this/db-positions:DEPTID"/>
		<xsl:variable name="typeCode" select="$this/db-positions:TYPECODE"/>
		<xsl:variable name="startYear">
			<xsl:analyze-string select="$this/db-positions:BEGINTS" regex="^(....).*?$">
				<xsl:matching-substring>
					<xsl:value-of select="regex-group(1)"/>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:variable name="startDate">
			<xsl:analyze-string select="$this/db-positions:BEGINTS" regex="^(....-..-..).*?$">
				<xsl:matching-substring>
					<xsl:value-of select="regex-group(1)"/>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<rdf:Description rdf:about="{$baseURI}person/ufid{$ufid}">
			<xsl:choose>
				<xsl:when test="$typeCode=192">
					<rdf:type rdf:resource="http://vivoweb.org/ontology/core#FacultyMember"/>
				</xsl:when>
				<xsl:when test="$typeCode=195">
					<rdf:type rdf:resource="http://vivoweb.org/ontology/core#NonAcademic"/>
				</xsl:when>
				<xsl:when test="$typeCode=197">
					<rdf:type rdf:resource="http://vivo.ufl.edu/ontology/vivo-ufl/CourtesyFaculty"/>
				</xsl:when>
				<xsl:when test="$typeCode=200">
					<rdf:type rdf:resource="http://vivoweb.org/ontology/core#EmeritusProfessor"/>
				</xsl:when>
				<xsl:when test="$typeCode=219">
					<rdf:type rdf:resource="http://vivoweb.org/ontology/core#FacultyMember"/>
				</xsl:when>
				<xsl:when test="$typeCode=221">
					<rdf:type rdf:resource="http://vivo.ufl.edu/ontology/vivo-ufl/Consultant"/>
				</xsl:when>
			</xsl:choose>
			<core:personInPosition>
				<rdf:Description rdf:about="{$baseURI}position/positionFor{$ufid}in{$fullorgnum}as{$typeCode}from{$startDate}">
					<ufVivo:harvestedBy>PeopleSoft-Harvester</ufVivo:harvestedBy>
					<rdfs:label><xsl:value-of select="$this/db-positions:UFTITLE"/></rdfs:label>
					<xsl:choose>
						<xsl:when test="$typeCode=192">
							<rdf:type rdf:resource="http://vivoweb.org/ontology/core#FacultyPosition"/>
						</xsl:when>
						<xsl:when test="$typeCode=195">
							<rdf:type rdf:resource="http://vivoweb.org/ontology/core#NonAcademicPosition"/>
						</xsl:when>
						<xsl:when test="$typeCode=197">
							<rdf:type rdf:resource="http://vivo.ufl.edu/ontology/vivo-ufl/CourtesyFacultyPos"/>
						</xsl:when>
						<xsl:when test="$typeCode=200">
							<rdf:type rdf:resource="http://vivoweb.org/ontology/core#FacultyPosition"/>
						</xsl:when>
						<xsl:when test="$typeCode=219">
							<rdf:type rdf:resource="http://vivoweb.org/ontology/core#FacultyPosition"/>
						</xsl:when>
						<xsl:when test="$typeCode=221">
							<rdf:type rdf:resource="http://vivo.ufl.edu/ontology/vivo-ufl/ConsultantPos"/>
						</xsl:when>
						<xsl:otherwise>
							<rdf:type rdf:resource="http://vivoweb.org/ontology/core#Position"/>
						</xsl:otherwise>
					</xsl:choose>
					<rdf:type rdf:resource="http://vivoweb.org/ontology/core#DependentResource"/>
					<ufVivo:deptIDofPosition><xsl:value-of select="$fullorgnum"/></ufVivo:deptIDofPosition>
					<core:positionInOrganization>
						<rdf:Description rdf:about="{$baseURI}org/org{$fullorgnum}">
							<ufVivo:harvestedBy>PeopleSoft-Harvester</ufVivo:harvestedBy>
							<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>
				    		<ufVivo:deptID><xsl:value-of select="$fullorgnum"/></ufVivo:deptID>
							<core:organizationForPosition rdf:resource="{$baseURI}position/positionFor{$ufid}in{$fullorgnum}as{$typeCode}from{$startDate}"/>
						</rdf:Description>
					</core:positionInOrganization>
					<core:positionForPerson rdf:resource="{$baseURI}person/ufid{$ufid}"/>
					<core:startYear rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear"><xsl:value-of select="$startYear"/></core:startYear>
				</rdf:Description>
			</core:personInPosition>
		</rdf:Description>
	</xsl:template>
</xsl:stylesheet>
