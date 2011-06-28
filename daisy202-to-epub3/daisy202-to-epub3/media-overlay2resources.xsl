<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:d="http://www.daisy.org/ns/pipeline/data" xmlns:smil="http://www.w3.org/ns/SMIL"
    exclude-result-prefixes="#all" version="2.0">

    <xsl:template match="/*">
        <d:fileset>
            <xsl:attribute name="xml:base" select="replace(@xml:base,'^(.+/)[^/]*','$1')"/>
            <xsl:for-each select="distinct-values(//smil:audio/@src)">
                <d:file href="{.}"/>
            </xsl:for-each>
        </d:fileset>
    </xsl:template>

</xsl:stylesheet>