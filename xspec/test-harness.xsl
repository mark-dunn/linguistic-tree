<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    
    xmlns:dc="urn:datacraft"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:js="http://saxonica.com/ns/globalJS"
    
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:import href="../xsl/linguistic-tree.xsl"/>
    
    <xsl:variable name="dummy-input" as="element(h:input)">
        <h:input/>
    </xsl:variable>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for interactive XSL function ixsl:page().</xd:p>            
        </xd:desc>
        <xd:return>An HTML document that contains dummy examples of buttons used elsewhere in the XSLT</xd:return>
    </xd:doc>
    <xsl:function name="ixsl:page" as="document-node()">
        <xsl:document>
            <html>
                <button id="style-serif" class="active">Serif</button>
                <button id="style-sansserif">Sans-serif</button>
                <button id="style-monospace">Monospace</button>
                
                <button id="term-bold">Bold</button>
                <button id="term-italic">Italic</button>
                
                <button id="nonterm-bold">Bold</button>
                <button id="nonterm-italic">Italic</button>
                
                
            </html>
        </xsl:document>
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for interactive XSL function ixsl:get().</xd:p>            
        </xd:desc>
    </xd:doc>
    <xsl:function name="ixsl:get" as="xs:string">
        <xsl:param name="input" as="element()"/>
        <xsl:param name="value" as="xs:string"/>
        <xsl:sequence select="''"/>
    </xsl:function>
    


    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for function which uses interactive XSL to get a value from a control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-text-tree" as="xs:string?">
        <xsl:sequence select="''"/>
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for function which uses interactive XSL to get a value from a control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-font-size" as="xs:integer">
        <xsl:sequence select="16"/>
    </xsl:function>

    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for function which uses interactive XSL to get a value from a control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-horizontal-space" as="xs:integer">
        <xsl:sequence select="20"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for function which uses interactive XSL to get a value from a control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-vertical-space" as="xs:integer">
        <xsl:sequence select="40"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for Javascript function which interacts with control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="js:toggleActive" as="processing-instruction()">
        <xsl:param name="button-id" as="xs:string"/>
        <xsl:processing-instruction name="xspec" select="'In production, would call JavaScript function'"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for Javascript function which interacts with control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="js:toggleFont" as="processing-instruction()">
        <xsl:param name="button-id" as="xs:string"/>
        <xsl:processing-instruction name="xspec" select="'In production, would call JavaScript function'"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for Javascript function which interacts with control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="js:setSVG" as="processing-instruction()">
        <xsl:param name="svg" as="xs:string"/>
        <xsl:processing-instruction name="xspec" select="'In production, would call JavaScript function'"/>
    </xsl:function>

    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for Javascript function which interacts with control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="js:getTextWidth" as="xs:double">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="font" as="xs:string"/>
        <xsl:sequence select="30"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Override for Javascript function which interacts with control on the page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="js:getColour" as="xs:string">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="'black'"/>
    </xsl:function>
    
   
  
</xsl:stylesheet>