<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:util="http://getalp.org#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="tei util"
    version="2.0">
    
    <!-- Global variables to be used during transform -->
    <xsl:variable name="lexinfo">
        <!-- Mapping between entry gramatical feature encoding to lexinfo entities -->
        <util:entry key="pl.">lexinfo:plural</util:entry>
        <util:entry key="m.">lexinfo:masculine</util:entry>
        <util:entry key="f.">lexinfo:feminine</util:entry>
        <util:entry key="n.">lexinfo:neutral</util:entry>
    </xsl:variable>
    <xsl:function name="util:convert" as="xs:string">
        <xsl:param name="arg" as="xs:string"/>
        <xsl:sequence select="$lexinfo/util:entry[@key=normalize-space($arg)]"/>
    </xsl:function>
    <!-- Default template -->
    <xsl:template match="@*|node()">
        <xsl:param name="lemmaUri" />
        <xsl:param name="senseUri" />
        <xsl:copy>
            <xsl:apply-templates select="@*|node()">
                <xsl:with-param name="lemmaUri" select="$lemmaUri" />
                <xsl:with-param name="senseUri" select="$senseUri" />
            </xsl:apply-templates>   
        </xsl:copy>
    </xsl:template>
    <!-- Defining the RDFa structure of entries -->
    <xsl:template match="tei:entry">
        <xsl:variable name="lemmaUri" select="encode-for-uri(./tei:form/tei:orth)"/>
        <xsl:message>Creating entry <xsl:value-of select="$lemmaUri"/></xsl:message>
        <xsl:copy>
            <xsl:attribute name="about">att:<xsl:value-of select="$lemmaUri"/>_entry</xsl:attribute>
            <xsl:attribute name="typeof">ontolex:LexicalEntry</xsl:attribute>
            <xsl:apply-templates select="@*|node()">
                <xsl:with-param name="lemmaUri" select="$lemmaUri" />
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:gramGrp/tei:number">
        <xsl:copy>
            <xsl:attribute name="rel">lexinfo:number</xsl:attribute>
            <xsl:attribute name="href"><xsl:value-of select="util:convert(text())"/></xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:gramGrp/tei:gen">
        <xsl:copy>
            <xsl:attribute name="rel">lexinfo:gender</xsl:attribute>
            <xsl:attribute name="href"><xsl:value-of select="util:convert(text())"/></xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>  
    <!-- Handling senses -->
    <xsl:template match="tei:sense">
        <xsl:param name="lemmaUri" />
        <xsl:message>Creating sense for <xsl:value-of select="$lemmaUri"/></xsl:message>
        <xsl:variable name="senseUri">att:<xsl:value-of select="$lemmaUri"/>_sense_<xsl:number/></xsl:variable>
        <xsl:copy>
            <xsl:attribute name="resource"><xsl:value-of select="$senseUri"/></xsl:attribute>
            <xsl:attribute name="rel">ontolex:sense</xsl:attribute>
            <xsl:attribute name="typeof">ontolex:LexicalSense</xsl:attribute>
            <xsl:apply-templates select="@*|node()">
                <xsl:with-param name="lemmaUri" select="$lemmaUri" />
                <xsl:with-param name="senseUri" select="$senseUri" />
            </xsl:apply-templates>        
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:sense/tei:def">
        <xsl:copy>
            <xsl:attribute name="property">dc:description</xsl:attribute>
            <xsl:attribute name="datatype">plaintext</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:sense/tei:cit[@type='translation']">
        <xsl:param name="lemmaUri" />
        <xsl:param name="senseUri" />
        <xsl:copy>
            <xsl:attribute name="property">dc:description</xsl:attribute>
            <xsl:attribute name="datatype">plaintext</xsl:attribute>
            <xsl:apply-templates select="@*|node()">
                <xsl:with-param name="lemmaUri" select="$lemmaUri" />
                <xsl:with-param name="senseUri" select="$senseUri" />
            </xsl:apply-templates>        
         </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:sense/tei:cit[@type='example']/tei:bibl[@source]">
        <xsl:param name="lemmaUri" />
        <xsl:param name="senseUri" />
        <xsl:copy>
            <xsl:attribute name="resource">att:<xsl:value-of select="$senseUri"/>_Att_<xsl:number count="tei:cit"/>_<xsl:number/></xsl:attribute>
            <xsl:attribute name="rel">frac:attestation</xsl:attribute>
            <xsl:attribute name="typeof">frac:Attestation</xsl:attribute>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="span" namespace="http://www.tei-c.org/ns/1.0" inherit-namespaces="no">
                <xsl:attribute name="rel" select="'frac:locus'"/>
                <xsl:element name="span" namespace="http://www.tei-c.org/ns/1.0" inherit-namespaces="no">
                <xsl:attribute name="property" select="'dc:isPartOf'"/>
                <xsl:attribute name="resource">att:<xsl:value-of select="substring-after(@source,'#')"/></xsl:attribute>
            </xsl:element>
            </xsl:element>
            <xsl:element name="span" namespace="http://www.tei-c.org/ns/1.0" inherit-namespaces="no">
                <xsl:attribute name="property" select="'rdf:value'"/>
                <xsl:value-of select="text()"/>
            </xsl:element>
         </xsl:copy>
    </xsl:template>
    <!-- Defining resources for bibliography -->
    <xsl:template match="tei:bibl[@*[name()='xml:id']]">
        <xsl:copy>
            <xsl:attribute name="resource">att:<xsl:value-of select="@xml:id"/></xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:bibl/tei:title">
        <xsl:copy>
            <xsl:attribute name="property">dc:title</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- Root rule to add namespaces to the root -->
    <xsl:template match="tei:TEI">
        <xsl:copy>
            <xsl:namespace name="ontolex">http://www.w3.org/ns/lemon/ontolex#</xsl:namespace>
            <xsl:namespace name="lexinfo">http://www.lexinfo.net/ontology/3.0/lexinfo#</xsl:namespace>
            <xsl:namespace name="att">http://www.semanticweb.org/fahadkhan/ontologies/2022/8/geardagas_entry#</xsl:namespace>
            <xsl:namespace name="dc">http://purl.org/dc/terms/</xsl:namespace>
            <xsl:namespace name="frac">http://www.w3.org/ns/lemon/frac#</xsl:namespace>
            <xsl:namespace name="bibo">http://purl.org/ontology/bibo/</xsl:namespace>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>