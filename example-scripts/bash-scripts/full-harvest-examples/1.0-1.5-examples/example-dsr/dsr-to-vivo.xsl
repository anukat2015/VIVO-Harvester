<!--
  Copyright (c) 2010-2011 VIVO Harvester Team. For full list of contributors, please see the AUTHORS file provided.
  All rights reserved.
  This program and the accompanying materials are made available under the terms of the new BSD license which accompanies this distribution, and is available at http://www.opensource.org/licenses/bsd-license.html
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    xmlns:core='http://vivoweb.org/ontology/core#'
    xmlns:score='http://vivoweb.org/ontology/score#'
    xmlns:rdfs='http://www.w3.org/2000/01/rdf-schema#'
    xmlns:ufVivo='http://vivo.ufl.edu/ontology/vivo-ufl/'
    xmlns:db-vwVIVO='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwVIVO/'
    xmlns:db-vwContracts='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwContracts/'
    xmlns:db-vwProjectTeam='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwProjectTeam/'
    xmlns:db-vwProjects='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwProjects/'>
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="baseURI">http://vivoweb.org/harvest/ufl/dsr/</xsl:variable>
    
    <xsl:template match="rdf:RDF">
        <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
            xmlns:core='http://vivoweb.org/ontology/core#'
            xmlns:rdfs='http://www.w3.org/2000/01/rdf-schema#'
            xmlns:ufVivo='http://vivo.ufl.edu/ontology/vivo-ufl/'
            xmlns:score='http://vivoweb.org/ontology/score#'
            xmlns:db-vwVIVO='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwVIVO/'
            xmlns:db-vwContracts='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwContracts/'
            xmlns:db-vwProjectTeam='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwProjectTeam/'
            xmlns:db-vwProjects='jdbc:jtds:sqlserver://10.241.46.60:1433/DSR/fields/vwProjects/' > 
            <xsl:apply-templates select='rdf:Description' />        
        </rdf:RDF>
    </xsl:template>
    
    <xsl:template match="rdf:Description">
        <xsl:variable name="this" select="." />
        <xsl:analyze-string select="../@xml:base" regex="^.*/([^/]+?)$">
            <xsl:matching-substring>
                <xsl:variable name="table" select="regex-group(1)" />
                <xsl:variable name="rdfid" select="$this/@rdf:ID" />
                
                <xsl:analyze-string select="$rdfid" regex="^id_-_(.*?)(_-_.+)*?$">
                    <xsl:matching-substring>
<!--                    This is where the types of data are translated differently-->
                        <xsl:choose>
                            <xsl:when test="$table = 'vwContracts'">
                                <xsl:call-template name="t_vwContracts">
                                    <xsl:with-param name="grantid" select="normalize-space( regex-group(1) )" />
                                    <xsl:with-param name="this" select="$this" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$table = 'vwProjectTeam'">
                                <xsl:call-template name="t_vwProjectTeam">
                                    <xsl:with-param name="this" select="$this" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$table = 'vwVIVO'">
                                <xsl:call-template name="t_vwVIVO">
                                    <xsl:with-param name="this" select="$this" />
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:matching-substring>       
                </xsl:analyze-string>
            </xsl:matching-substring>
        </xsl:analyze-string>
    
    </xsl:template>
        
    <xsl:template name="t_vwContracts">
        <xsl:param name='grantid' />
        <xsl:param name='this' />
        <xsl:variable name="startDate">           
            <xsl:analyze-string select="$this/db-vwContracts:BEGIN_DT" regex="^(....-..-..).*?$">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>

        <xsl:variable name="endDate">           
            <xsl:analyze-string select="$this/db-vwContracts:END_DT" regex="^(....-..-..).*?$">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>  
        
<!--    Creating a Grant-->
        <rdf:Description rdf:about="{$baseURI}grant/grant{$grantid}">
            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
            <rdf:type rdf:resource="http://vivoweb.org/ontology/core#Grant"/>
            <rdf:type rdf:resource="http://vivoweb.org/ontology/core#Agreement"/>
            <ufVivo:psContractNumber><xsl:value-of select="$grantid" /></ufVivo:psContractNumber>
            <rdfs:label><xsl:value-of select="$this/db-vwContracts:Title"/></rdfs:label>
            <core:totalAwardAmount><xsl:value-of select="$this/db-vwContracts:TotalAwarded"/></core:totalAwardAmount>
            <core:administeredBy>
<!--            Creating a department to match with or a stub if no match-->
                <rdf:Description rdf:about="{$baseURI}org/org{$this/db-vwContracts:ContractDeptID}">
                    <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                    <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                    <ufVivo:deptID><xsl:value-of select="$this/db-vwContracts:ContractDeptID"/></ufVivo:deptID>
                    <core:administers rdf:resource="{$baseURI}grant/grant{$grantid}" />
                    <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>
                </rdf:Description>
            </core:administeredBy>
            
<!--            Creating a sponsor attached to the grant-->
            <xsl:choose>
                <xsl:when test="string($this/db-vwContracts:FlowThruSponsor) = ''">
                    <core:grantAwardedBy>
                        <rdf:Description rdf:about="{$baseURI}sponsor/sponsor{$this/db-vwContracts:SponsorID}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <rdfs:label><xsl:value-of select="$this/db-vwContracts:Sponsor"/></rdfs:label>
                            <core:awardsGrant rdf:resource="{$baseURI}grant/grant{$grantid}"/>
                            <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>
                            <ufVivo:sponsorID><xsl:value-of select="$this/db-vwContracts:SponsorID"/></ufVivo:sponsorID>
                        </rdf:Description>
                    </core:grantAwardedBy>
                </xsl:when>
                <xsl:otherwise>
<!--            Creating a sponsor and a subcontracting sponsor attached to the grant-->
                    <core:grantSubcontractedThrough>
                        <rdf:Description rdf:about="{$baseURI}sponsor/sponsor{$this/db-vwContracts:SponsorID}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <rdfs:label><xsl:value-of select="$this/db-vwContracts:Sponsor"/></rdfs:label>
                            <core:subcontractsGrant rdf:resource="{$baseURI}grant/grant{$grantid}"/>
                            <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>
                            <ufVivo:sponsorID><xsl:value-of select="$this/db-vwContracts:SponsorID"/></ufVivo:sponsorID>
                        </rdf:Description>
                    </core:grantSubcontractedThrough>
                    <core:grantAwardedBy>
                        <rdf:Description rdf:about="{$baseURI}sponsor/sponsor{$this/db-vwContracts:FlowThruSponsorID}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <rdfs:label><xsl:value-of select="$this/db-vwContracts:FlowThruSponsor"/></rdfs:label>
                            <core:awardsGrant rdf:resource="{$baseURI}grant/grant{$grantid}"/>
                            <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>
                            <ufVivo:sponsorID><xsl:value-of select="$this/db-vwContracts:FlowThruSponsorID"/></ufVivo:sponsorID>
                        </rdf:Description>
                    </core:grantAwardedBy>
                </xsl:otherwise>
            </xsl:choose>
                        
            <core:dateTimeInterval rdf:resource="{$baseURI}timeInterval/start{$startDate}toEnd{$endDate}" />
            
        </rdf:Description>
        <!-- The beginning of the dateTimeInterval subgroup -->
        <!-- using the dates as part of the identifier allows dates to automatically align with each other based on that value. -->
         <rdf:Description rdf:about="{$baseURI}timeInterval/start{$startDate}toEnd{$endDate}">
             <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Thing"/>
             <rdf:type rdf:resource="http://vivoweb.org/ontology/core#DateTimeInterval"/>
             <core:start rdf:resource="{$baseURI}timeInterval/date{$startDate}"/>
             <core:end rdf:resource="{$baseURI}timeInterval/date{$endDate}"/>
         </rdf:Description>
         
         <rdf:Description rdf:about="{$baseURI}timeInterval/date{$startDate}">
             <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Thing"/>
             <rdf:type rdf:resource="http://vivoweb.org/ontology/core#DateTimeValue"/>
             <core:dateTimePrecision rdf:resource="http://vivoweb.org/ontology/core#yearMonthDayPrecision"/>
             <core:dateTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime"><xsl:value-of select="$startDate" />T00:00:00</core:dateTime>
         </rdf:Description>
                  
         <rdf:Description rdf:about="{$baseURI}timeInterval/date{$endDate}">
             <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Thing"/>
             <rdf:type rdf:resource="http://vivoweb.org/ontology/core#DateTimeValue"/>
             <core:dateTimePrecision rdf:resource="http://vivoweb.org/ontology/core#yearMonthDayPrecision"/>
             <core:dateTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime"><xsl:value-of select="$endDate" />T00:00:00</core:dateTime>
         </rdf:Description>
         <!-- The end of the dateTimeInterval subgroup -->
    </xsl:template>
        
    <xsl:template name="t_vwProjectTeam">
        <xsl:param name='this' />
        <xsl:variable name='grantid' select='$this/db-vwProjectTeam:ContractNumber'/>
        <xsl:choose>
            <xsl:when test="$this/db-vwProjectTeam:isPI = 'Y'">
<!--            Creating the PI role-->
                <rdf:Description rdf:about="{$baseURI}piRole/inGrant{$grantid}For{$this/db-vwProjectTeam:InvestigatorID}">
                    <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                    <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                    <rdf:type rdf:resource="http://vivoweb.org/ontology/core#PrincipalInvestigatorRole"/>
                    <rdf:type rdf:resource="http://vivoweb.org/ontology/core#InvestigatorRole"/>
                    <rdf:type rdf:resource="http://vivoweb.org/ontology/core#ResearcherRole"/>
<!--              attaching the role to the grant -->
                    <core:roleIn>
                        <rdf:Description rdf:about="{$baseURI}grant/grant{$grantid}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <core:relatedRole rdf:resource="{$baseURI}piRole/inGrant{$grantid}For{$this/db-vwProjectTeam:InvestigatorID}"/>
                        </rdf:Description>
                    </core:roleIn>
<!--              attaching the role to a person stub which should be matched on. -->
                    <core:principalInvestigatorRoleOf>
                        <rdf:Description rdf:about="{$baseURI}person/person{$this/db-vwProjectTeam:InvestigatorID}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <!--<rdfs:label><xsl:value-of select="$this/db-vwProjectTeam:Investigator"/></rdfs:label> -->
                            <!--<rdf:type rdf:resource="http://vivoweb.org/harvester/excludeEntity" /> -->
                            <ufVivo:ufid ><xsl:value-of select="$this/db-vwProjectTeam:InvestigatorID"/></ufVivo:ufid>
                            <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
                            <core:hasPrincipalInvestigatorRole rdf:resource="{$baseURI}piRole/inGrant{$grantid}For{$this/db-vwProjectTeam:InvestigatorID}"/>
                        </rdf:Description>
                    </core:principalInvestigatorRoleOf>
                </rdf:Description>
            </xsl:when>
            <xsl:otherwise>
<!--            Creating the Co-PI role-->
                <rdf:Description rdf:about="{$baseURI}coPiRole/inGrant{$grantid}For{$this/db-vwProjectTeam:InvestigatorID}">
                    <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                    <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                    <rdf:type rdf:resource="http://vivoweb.org/ontology/core#CoPrincipalInvestigatorRole"/>
                    <rdf:type rdf:resource="http://vivoweb.org/ontology/core#InvestigatorRole"/>
                    <rdf:type rdf:resource="http://vivoweb.org/ontology/core#ResearcherRole"/>
<!--              attaching the role to the grant -->
                    <core:roleIn>
                        <rdf:Description rdf:about="{$baseURI}grant/grant{$grantid}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <core:relatedRole rdf:resource="{$baseURI}coPiRole/inGrant{$grantid}For{$this/db-vwProjectTeam:InvestigatorID}"/>
                        </rdf:Description>
                    </core:roleIn>
<!--              attaching the role to a person stub which should be matched on. -->
                    <core:co-PrincipalInvestigatorRoleOf>
                        <rdf:Description rdf:about="{$baseURI}person/person{$this/db-vwProjectTeam:InvestigatorID}">
                            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
                            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
                            <!--<rdfs:label><xsl:value-of select="$this/db-vwProjectTeam:Investigator"/></rdfs:label>-->
                            <!--<rdf:type rdf:resource="http://vivoweb.org/harvester/excludeEntity" />-->
                            <ufVivo:ufid ><xsl:value-of select="$this/db-vwProjectTeam:InvestigatorID"/></ufVivo:ufid>
                            <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
                            <core:hasCo-PrincipalInvestigatorRole rdf:resource="{$baseURI}coPiRole/inGrant{$grantid}For{$this/db-vwProjectTeam:InvestigatorID}"/>
                        </rdf:Description>
                    </core:co-PrincipalInvestigatorRoleOf>
                </rdf:Description>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="t_vwVIVO">
        <xsl:param name='this' />
        <xsl:if test="not( $this/db-vwVIVO:PS_Contract = '' or $this/db-vwVIVO:PS_Contract = 'null' )">
        <xsl:variable name='grantid' select='$this/db-vwVIVO:PS_Contract'/>
<!-- This grant description is for attaching the additional data about the grant from the vwVIVO view -->
        <rdf:Description rdf:about="{$baseURI}grant/grant{$grantid}">
            <ufVivo:harvestedBy>DSR-Harvester</ufVivo:harvestedBy>
            <ufVivo:dateHarvested><xsl:value-of select="current-date()" /></ufVivo:dateHarvested>
            <ufVivo:psContractNumber><xsl:value-of select="$grantid" /></ufVivo:psContractNumber>
            <ufVivo:dsrNumber><xsl:value-of select="$this/db-vwVIVO:DSR_Number" /></ufVivo:dsrNumber>
            <core:sponsorAwardId><xsl:value-of select="$this/db-vwVIVO:AgencyNumber"/></core:sponsorAwardId>
        </rdf:Description>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
