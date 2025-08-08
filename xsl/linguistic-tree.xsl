<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:dc="urn:datacraft"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:js="http://saxonica.com/ns/globalJS" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:ev="http://www.w3.org/2001/xml-events"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns="http://www.w3.org/2000/svg"
    
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>linguistic-tree.xsl</xd:b></xd:p>
            <xd:p>Turn an expression using <xd:a href="http://glottopedia.org/index.php/Labeled_bracketing">labelled bracketing</xd:a> into an SVG image of the corresponding syntax tree diagram.</xd:p>
            <xd:p>Inspired by Miles Shang's <xd:a href="https://mshang.ca/syntree/">syntree</xd:a> Javascript tool.</xd:p>
            <xd:p><xd:a href="https://www.w3.org/TR/SVG11/">SVG 1.1 spec</xd:a></xd:p>
            <xd:p><xd:b>NOTE:</xd:b> +++++ Don't forget to compile the stylesheet after making changes +++++</xd:p>
            <xd:p>sh /Users/mark/GitHub/linguistic-tree/compile-xsl.sh</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:include href="linguistic-tree-javascript-library.xsl"/>
    
    <xsl:mode name="add-widths" on-no-match="shallow-copy"/>
    <xsl:mode name="add-text-coordinates" on-no-match="shallow-copy"/>
    <xsl:mode name="add-expression-coordinates" on-no-match="shallow-copy"/>
    <xsl:mode name="add-arrow-coordinates" on-no-match="shallow-copy"/>
    
    <xsl:variable static="yes" name="LOGLEVEL" as="xs:integer" select="0"/>
        
    <xsl:variable name="page" as="document-node()" select="ixsl:page()"/>
    
    <xsl:variable name="margin-x" as="xs:integer" select="5"/>
    <xsl:variable name="margin-y" as="xs:integer" select="5"/>
    <xsl:variable name="pt-to-px" as="xs:double" select="4 div 3"/>
    <xsl:variable name="text-margin-y" as="xs:integer" select="8"/>
    
    
    <!-- [category value] -->
    <xsl:variable name="expression-regex" as="xs:string" select="'^\s*\[\s*([^\s]+)\s+([\s\S]+)\s*\]\s*$'"/>
    
    <!-- [category ...] ...
        OR value ... [
        
        But ']' may not be the match for '[' 
        We may need to go further along the expression
        so we move past nested expressions 
        to the matching ']'
    -->
    <xsl:variable name="expression-candidate" as="xs:string" select="'^\s*(\[\s*[^\s]+\s+[^\]]+\s*\]|[^\[\]]+\s*\[)([\s\S]*)$'"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Main template. Create SVG and insert it into page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="main">
        <xsl:message use-when="$LOGLEVEL ge 1">[main] Creating SVG</xsl:message>
        <!-- 
            Write Javascript into HTML header
        -->
        <xsl:apply-templates select="$page/h:html/h:head" mode="set-js"/>
          
        <xsl:call-template name="draw-tree"/>
 
    </xsl:template>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-expression-x() returns the x-coordinate of an expression in a tree diagram.</xd:p>
        </xd:desc>
        <xd:param name="expression">Expression in linguistic tree.</xd:param>
        <xd:param name="hor-space">Amount of horizontal space between items in rows (in pixels).</xd:param>
        <xd:return>Value calculated from x position of parent expression and width of preceding siblings.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-expression-x" as="xs:double">
        <xsl:param name="expression" as="element(dc:expression)"/>
        <xsl:param name="hor-space" as="xs:integer"/>
        
        <xsl:variable name="parent-expression" as="element(dc:expression)?" select="$expression/parent::dc:values/parent::dc:expression"/>
        <xsl:variable name="preceding" as="element()*" select="$expression/preceding-sibling::*"/>
        
        <xsl:variable name="preceding-x-additions" as="xs:double*">
            <xsl:for-each select="$preceding">
                <xsl:sequence select="dc:get-width(.,$hor-space) + $hor-space"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="exists($parent-expression)">
                <xsl:sequence select="dc:get-expression-x($parent-expression,$hor-space) + sum($preceding-x-additions)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$margin-x + sum($preceding-x-additions)"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function get-x() returns x-coordinate of item in linguistic tree.</xd:p>
        </xd:desc>
        <xd:param name="item">A category or value.</xd:param>
        <xd:param name="hor-space">Amount of horizontal space between items in rows (in pixels).</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-x" as="xs:double">
        <xsl:param name="item" as="element()"/>
        <xsl:param name="hor-space" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$item[self::dc:category]">
                <xsl:sequence select="dc:get-category-x($item,$hor-space)"/>
            </xsl:when>
            <xsl:when test="$item[self::dc:value]">
                <xsl:sequence select="dc:get-value-x($item,$hor-space)"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- should never reach here -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    

    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-category-x() returns the x-coordinate of a category in a tree diagram.</xd:p>
        </xd:desc>
        <xd:param name="category">Category in linguistic tree.</xd:param>
        <xd:param name="hor-space">Amount of horizontal space between items in rows (in pixels).</xd:param>
        <xd:return>Value calculated from x position of first and last children, and width of last child.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-category-x" as="xs:double">
        <xsl:param name="category" as="element(dc:category)"/>
        <xsl:param name="hor-space" as="xs:integer"/>
        
        <xsl:variable name="width" as="xs:double" select="$category/@width"/>
        
        <xsl:variable name="children" as="element()*" select="$category/following-sibling::dc:values/*"/>
        <xsl:variable name="first-child" as="element()" select="$children[1]"/>
        <xsl:variable name="last-child" as="element()" select="$children[last()]"/>
        
        <xsl:variable name="last-child-x" as="xs:double" select="if ($last-child[self::dc:expression]) then dc:get-category-x($last-child/dc:category,$hor-space) else dc:get-value-x($last-child,$hor-space)"/>
        <xsl:variable name="last-child-width" as="xs:double" select="if ($last-child[self::dc:expression]) then $last-child/dc:category/@width else $last-child/@width"/>
        <xsl:variable name="last-child-mid-x" as="xs:double" select="$last-child-x + ($last-child-width div 2)"/>
        
        <xsl:variable name="first-child-x" as="xs:double" select="if ($first-child[self::dc:expression]) then dc:get-category-x($first-child/dc:category,$hor-space) else dc:get-value-x($first-child,$hor-space)"/>
        <xsl:variable name="first-child-width" as="xs:double" select="if ($first-child[self::dc:expression]) then $first-child/dc:category/@width else $first-child/@width"/>
        <xsl:variable name="first-child-mid-x" as="xs:double" select="$first-child-x + ($first-child-width div 2)"/>
        
        <xsl:variable name="mid-x" as="xs:double" select="($last-child-mid-x + $first-child-mid-x) div 2"/>
        
        <xsl:variable name="children-total-width" as="xs:double" select="$last-child-x + $last-child-width - $first-child-x"/>
        
        <xsl:choose>
            <xsl:when test="count($children) = 1 and $first-child[self::dc:expression] and $width > $children-total-width">
                <!-- 
                    For a category with one line down to another (shorter) category,
                    base x coordinate on mid point of child.
                -->
                <xsl:sequence select="$mid-x - $category/@width div 2"/>
            </xsl:when>
            <xsl:when test="$width > $children-total-width">
                <!-- 
                    For an extremely long category
                    use x coordinate of parent expression
                -->
                <xsl:value-of select="$category/parent::dc:expression/@x"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- 
                    Otherwise base the x coordinate on the mid-point
                    of the first and last children.
                -->
                <xsl:sequence select="$mid-x - $category/@width div 2"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-value-x() returns the x-coordinate of a value in a tree diagram.</xd:p>
        </xd:desc>
        <xd:param name="value">Value in linguistic tree.</xd:param>
        <xd:param name="hor-space">Amount of horizontal space between items in rows (in pixels).</xd:param>
        <xd:return>Value calculated from x position of preceding sibling, or x position of parent expression.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-value-x" as="xs:double">
        <xsl:param name="value" as="element(dc:value)"/>
        <xsl:param name="hor-space" as="xs:integer"/>
        
        <xsl:variable name="preceding" as="element()?" select="$value/preceding-sibling::*[1]"/>
        <xsl:variable name="following" as="element()?" select="$value/following-sibling::*[1]"/>
        <xsl:variable name="parent-expression" as="element(dc:expression)" select="$value/parent::dc:values/parent::dc:expression"/>
        <xsl:variable name="parent-x" as="xs:double" select="$value/parent::dc:values/parent::dc:expression/@x"/>
        <xsl:variable name="parent-category" as="element(dc:category)" select="$parent-expression/dc:category"/>
        <xsl:variable name="width" as="xs:double" select="$value/@width"/>
        <xsl:variable name="category-width" as="xs:double" select="$parent-category/@width"/>
        <xsl:choose>
            <!-- 
                If parent category is wider than the value,
                base the x coordinate on the mid-point of the parent.
            -->
            <xsl:when test="empty($preceding) and empty($following) and $width &lt; $category-width">
                <xsl:sequence select="$parent-x + ($category-width div 2) - ($width div 2)"/>
            </xsl:when>
            <xsl:when test="empty($preceding)">
                <xsl:sequence select="$parent-x"/>
            </xsl:when>
            <xsl:when test="$preceding[self::dc:expression]">
                <xsl:variable name="prec-x" as="xs:double" select="xs:double($preceding/@x)"/>
                <xsl:variable name="prec-width" as="xs:double" select="xs:double($preceding/@width)"/>
                <xsl:sequence select="$prec-x + $prec-width + $hor-space"/>
            </xsl:when>
            <xsl:when test="$preceding[self::dc:value]">
                <xsl:variable name="prec-x" as="xs:double" select="dc:get-value-x($preceding,$hor-space)"/>
                <xsl:variable name="prec-width" as="xs:double" select="xs:double($preceding/@width)"/>
                <xsl:sequence select="$prec-x + $prec-width + $hor-space"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- should never reach this -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-expression-y() returns the y-coordinate of an expression in a linguistic tree.</xd:p>
        </xd:desc>
        <xd:param name="expression">Expression in linguistic tree.</xd:param>
        <xd:param name="vert-space">Amount of vertical space between rows (in pixels).</xd:param>
        <xd:param name="font-size">Size of font, in pt. Convert to px with $pt-to-px variable.</xd:param>
        <xd:return>Value calculated from number of preceding rows, height of rows, and vertical space between rows.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-expression-y" as="xs:double">
        <xsl:param name="expression" as="element(dc:expression)"/>
        <xsl:param name="vert-space" as="xs:integer"/>
        <xsl:param name="font-size" as="xs:integer"/>
        
        <xsl:variable name="preceding-rows" as="element(dc:expression)*" select="$expression/ancestor::dc:expression"/>
        
        <!--<xsl:message select="'[dc:get-expression-y] Preceding rows: ' || count($preceding-rows)"/>-->
        <xsl:sequence select="$margin-y + (count($preceding-rows) * (($font-size * $pt-to-px) + $vert-space))"/>
        
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:p>Function dc:get-expression-width() returns the width of an expression element in the tree.</xd:p>
        <xd:param name="expression">An expression element.</xd:param>
        <xd:param name="hor-space">Amount of horizontal space between items in rows (in pixels).</xd:param>
        <xd:return>Larger of category width and value derived from width of children. If a child is a nested expression we recursively call this function.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-expression-width" as="xs:double">
        <xsl:param name="expression" as="element(dc:expression)"/>
        <xsl:param name="hor-space" as="xs:integer"/>
        
        <xsl:variable name="category-width" as="xs:double" select="$expression/dc:category/@width"/>
        <xsl:variable name="children" as="element()+" select="$expression/dc:values/*"/>
        
        <xsl:variable name="child-widths" as="xs:double+" select="for $c in $children return dc:get-width($c,$hor-space)"/>
        
        <xsl:variable name="children-total-width" as="xs:double" select="sum($child-widths) + $hor-space * (count($children) - 1)"/>
        
        <xsl:sequence select="max(($category-width,$children-total-width))"/>
        
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-width() returns the width of a value in a tree.</xd:p>
            <xd:p>If the value is itself an expression we recursively call dc:get-expression-width().</xd:p>
            <xd:p>Otherwise we return the value/@width previously set.</xd:p>
        </xd:desc>
        <xd:param name="item">A child of the values element in a parsed expression, either a value element or another expression element.</xd:param>
        <xd:param name="hor-space">Amount of horizontal space between items in rows (in pixels).</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-width" as="xs:double">
        <xsl:param name="item" as="element()"/>
        <xsl:param name="hor-space" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$item[self::dc:value]">
                <xsl:variable name="value-width" as="xs:double" select="$item/@width"/>
                <xsl:message use-when="$LOGLEVEL ge 5">[dc:get-width] Width of value '<xsl:sequence select="$item/text()"/>' = <xsl:sequence select="$value-width"/></xsl:message>
                <xsl:value-of select="$value-width"/>
            </xsl:when>
            <xsl:when test="$item[self::dc:expression]">
                <xsl:variable name="expression-width" as="xs:double" select="dc:get-expression-width($item,$hor-space)"/>
                <xsl:message use-when="$LOGLEVEL ge 5">[dc:get-width] Width of expression '<xsl:sequence select="$item/dc:category/text()"/>' = <xsl:sequence select="$expression-width"/></xsl:message>
                <xsl:sequence select="$expression-width"/>
            </xsl:when>
        </xsl:choose>
        
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Handle change to source text.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="h:textarea[@id eq 'text-tree']" mode="ixsl:onkeyup">
        <xsl:call-template name="draw-tree"/>
    </xsl:template>
    <xsl:template match="h:textarea[@id eq 'text-tree']" mode="ixsl:onchange">
        <xsl:call-template name="draw-tree"/>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Handle click on "Submit".</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="h:button[@id eq 'submit']" mode="ixsl:onclick">
        <xsl:call-template name="draw-tree"/>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Handle click on bold/italic selection buttons.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="h:button[@id = ('term-bold','term-italic','nonterm-bold','nonterm-italic','terminal-lines')]" mode="ixsl:onclick">
        <xsl:sequence select="js:toggleActive(string(@id))"/>
        <xsl:call-template name="draw-tree"/>
    </xsl:template>
 
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Handle click on font selection buttons.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="h:button[@id = ('style-serif','style-sansserif','style-monospace')]" mode="ixsl:onclick">
        <xsl:sequence select="js:toggleFont(string(@id))"/>
        <xsl:call-template name="draw-tree"/>
    </xsl:template>
 
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Handle change to selection of option.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="h:input" mode="ixsl:onclick">
        <xsl:call-template name="draw-tree"/>
    </xsl:template>


    <xd:doc scope="component">
        <xd:desc>
            <xd:p>This is the main template for creating the SVG version of the linguistic tree.</xd:p>
            <xd:p>Template is called when the page is loaded and when a change is made in the controls on the page.</xd:p>
            <xd:ul>
                <xd:li>Identify the plain text tree and its display options.</xd:li>
                <xd:li>Parse the tree into an intermediate XML format.</xd:li>
                <xd:li>Identify values for font, line colour, etc from the page controls.</xd:li>
                <xd:li>Convert the XML to SVG.</xd:li>
                <xd:li>Place the SVG and its serialized raw text on the page.</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template name="draw-tree">
        
        <!-- 
            Get settings from page
            - plain text version of tree
            - font style (for terminal and non-terminal items)
            - line colour
            - space between items
            - etc
        -->
        <xsl:variable name="texttree" as="xs:string" select="dc:get-text-tree()"/>
        
        <!-- values 8 to 16 -->
        <xsl:variable name="font-size" as="xs:integer" select="dc:get-font-size()"/>
        <!-- serif, sans-serif, monospace -->
        <xsl:variable name="font-style-serif" as="xs:string?" select="if (dc:get-button-state('style-serif')) then 'serif' else ()"/>
        <xsl:variable name="font-style-sansserif" as="xs:string?" select="if (dc:get-button-state('style-sansserif')) then 'sans-serif' else ()"/>
        <xsl:variable name="font-style-monospace" as="xs:string?" select="if (dc:get-button-state('style-monospace')) then 'monospace' else ()"/>
        <!-- Exactly one of these should be set. Fall back to 'serif' just in case none are set. -->
        <xsl:variable name="font-style" as="xs:string" select="($font-style-serif,$font-style-sansserif,$font-style-monospace,'serif')[1]"/>
        
        <xsl:variable name="term-lines" as="xs:string?" select="dc:get-button-state('terminal-lines')"/>
        
        <xsl:variable name="term-font-weight" as="xs:string?" select="dc:get-button-state('term-bold')"/>
        <xsl:variable name="term-font-style" as="xs:string?" select="dc:get-button-state('term-italic')"/>
        <xsl:variable name="term-colour" as="xs:string" select="dc:get-colour('term-colour')"/>
        <xsl:variable name="nonterm-font-weight" as="xs:string?" select="dc:get-button-state('nonterm-bold')"/>
        <xsl:variable name="nonterm-font-style" as="xs:string?" select="dc:get-button-state('nonterm-italic')"/>
        <xsl:variable name="nonterm-colour" as="xs:string" select="dc:get-colour('nonterm-colour')"/>
        
        <xsl:variable name="line-colour" as="xs:string" select="dc:get-colour('line-colour')"/>
        
        <!-- values 35 to 70 (in increments of 5) -->
        <xsl:variable name="vertical-space" as="xs:integer" select="dc:get-vertical-space()"/>
        <!-- values 10 to 50 (in increments of 5) -->
        <xsl:variable name="horizontal-space" as="xs:integer" select="dc:get-horizontal-space()"/>
        
        <xsl:variable name="terminal-font" as="xs:string" select="(if ($term-font-weight) then 'bold ' else ()) || (if ($term-font-style) then 'italic ' else ()) || $font-size || 'pt ' || $font-style"/>
        <xsl:variable name="nonterminal-font" as="xs:string" select="(if ($nonterm-font-weight) then 'bold ' else ()) || (if ($nonterm-font-style) then 'italic ' else ())  || $font-size || 'pt ' || $font-style"/>
        
        <!-- 
            Get first intermediate XML format,
            giving the basic structure of the tree.
        -->
        <xsl:variable name="parsed-tree" as="element()?" select="dc:parse-text-tree($texttree)"/>      
        
        <!-- 
            Add @width to dc:category and dc:value elements.
            The fonts descriptions are passed for a call to 
            a Javascript function to calculate the width from the text.
            (Getting text width is not possible in XSLT.)
        -->
        <xsl:variable name="parsed-tree-widths" as="element(dc:expression)?">
            <xsl:apply-templates select="$parsed-tree" mode="add-widths">
                <xsl:with-param name="term-font" as="xs:string" select="$terminal-font" tunnel="yes"/>
                <xsl:with-param name="nonterm-font" as="xs:string" select="$nonterminal-font" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="image-width" select="dc:get-expression-width($parsed-tree-widths,$horizontal-space) + (2 * $margin-x)"/>
        
        <!--<xsl:message>[draw-tree] Image width = <xsl:sequence select="$image-width"/></xsl:message>-->
        
        <!-- 
            Add coordinates and widths for the expressions [category value+]
            
            We process the XML from the top down,
            but the width of an expression is derived from the widths 
            of the items and expressions within it.
            
            We recursively call a function dc:get-expression-width()
            to get the width of an expression.
            
            The logic means that the function is called multiple times
            on a lower-level expression, once when calculating its own width
            and also each time we are calculating the width of an ancestor expression.
        -->
        <xsl:variable name="parsed-tree-expression-coordinates" as="element(dc:expression)?">
            <xsl:apply-templates select="$parsed-tree-widths" mode="add-expression-coordinates">
                <xsl:with-param name="hor-space" as="xs:integer" select="$horizontal-space" tunnel="yes"/>
                <xsl:with-param name="vert-space" as="xs:integer" select="$vertical-space" tunnel="yes"/>
                <xsl:with-param name="font-size" as="xs:integer" select="$font-size" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <!-- 
            Add coordinates and widths for the text items
            (categories and values) within the expression.
            
            These are partly derived from the coordinates 
            assigned to the expressions in the previous pass.
        -->
        <xsl:variable name="parsed-tree-text-coordinates" as="element(dc:expression)?">
            <xsl:apply-templates select="$parsed-tree-expression-coordinates" mode="add-text-coordinates">
                <xsl:with-param name="hor-space" as="xs:integer" select="$horizontal-space" tunnel="yes"/>
                <xsl:with-param name="vert-space" as="xs:integer" select="$vertical-space" tunnel="yes"/>
                <xsl:with-param name="font-size" as="xs:integer" select="$font-size" tunnel="yes"/>
                <xsl:with-param name="term-lines" as="xs:boolean" select="if ($term-lines) then true() else false()" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        
        <!-- 
            Add a base level for the arc of each arrow,
            by identifying the intervening values, 
            looking at their y coordinates, and 
            going below the lowest intervening value.
            
            This pass also identifies the arrow direction,
            which is used to adjust the start/end point of arrows
            that go in/out of the same value.
        -->
        <xsl:variable name="parsed-tree-arrow-coordinates" as="element(dc:expression)?">
            <xsl:apply-templates select="$parsed-tree-text-coordinates" mode="add-arrow-coordinates">
                <xsl:with-param name="hor-space" as="xs:integer" select="$horizontal-space" tunnel="yes"/>
                <xsl:with-param name="vert-space" as="xs:integer" select="$vertical-space" tunnel="yes"/>
                <xsl:with-param name="font-size" as="xs:integer" select="$font-size" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:message use-when="$LOGLEVEL ge 5">[draw-tree] Intermediate XML:
            <xsl:sequence select="fn:serialize($parsed-tree-arrow-coordinates,map{'indent':true()})"/>
        </xsl:message>
        
       
        
        <!-- 
            Now that we have all the y coordinates,
            including the bottom of arrow arcs,
            we can calculate the total image height.
            
            We add another row height so that descenders on letters
             (e.g. 'g', 'y') don't pass out of shot.
        -->
        <xsl:variable name="image-height" select="max($parsed-tree-arrow-coordinates//dc:value/(@y|@arrow-bottom-y)) + ($font-size * $pt-to-px) + $margin-y"/>
        
        <!-- 
            Now we convert the completed intermediate XML
            to SVG.
            
            This involves two passes over the intermediate XML,
            one to populate the text items and lines,
            the second to draw the arrows.
            
            (Could be combined into one pass, 
            but the code is easier to read this way.)
        -->        
        <xsl:variable name="svg" as="element(svg:svg)">
            <svg
                version="1.1" width="{$image-width}" height="{$image-height}" style="background-color:white">
                <desc>Syntax tree diagram generated at https://linguistics.datacraft.co.uk/</desc>
                
                <style type="text/css">
                    text {
                        font-family: <xsl:sequence select="$font-style"/>;
                        font-size: <xsl:sequence select="$font-size"/>pt;
                    }
                    text.terminal {
                        font-weight: <xsl:sequence select="if ($term-font-weight) then 'bold' else ('normal')"/>;
                        font-style: <xsl:sequence select="if ($term-font-style) then 'italic' else ('normal')"/>;
                    }
                    text.nonterminal {
                        font-weight: <xsl:sequence select="if ($nonterm-font-weight) then 'bold' else ('normal')"/>;
                        font-style: <xsl:sequence select="if ($nonterm-font-style) then 'italic' else ('normal')"/>;
                    }
                    tspan.subscript {font-size:smaller}
                </style>
                
                <xsl:apply-templates select="$parsed-tree-arrow-coordinates//*[self::dc:category or self::dc:value]" mode="draw-text">
                    <xsl:with-param name="vert-space" as="xs:integer" select="$vertical-space" tunnel="yes"/>
                    <xsl:with-param name="term-colour" as="xs:string" select="$term-colour"/>
                    <xsl:with-param name="nonterm-colour" as="xs:string" select="$nonterm-colour"/>
                    <xsl:with-param name="line-colour" as="xs:string" select="$line-colour" tunnel="yes"/>
                    <xsl:with-param name="term-lines" as="xs:boolean" select="if ($term-lines) then true() else false()" tunnel="yes"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="$parsed-tree-arrow-coordinates//*[@arrow-start]" mode="draw-arrow">
                    <xsl:with-param name="tree" as="element(dc:expression)?" select="$parsed-tree-text-coordinates"/>
                    <xsl:with-param name="vert-space" as="xs:integer" select="$vertical-space"/>
                    <xsl:with-param name="line-colour" as="xs:string" select="$line-colour"/>
                </xsl:apply-templates>
            </svg>
        </xsl:variable>
        
        <!-- 
            Put the SVG on the page...
        -->
        <xsl:result-document href="#svg" method="ixsl:replace-content">
            <xsl:sequence select="$svg"/>
        </xsl:result-document>
        
        <!-- 
            ... and in serialized format ...
        -->
        <xsl:result-document href="#raw-svg" method="ixsl:replace-content">
            <xsl:sequence select="fn:serialize($svg,map{'indent':true()})"/>
        </xsl:result-document>
        
        <!-- 
            ... and the intermediate XML.
        -->
        <xsl:result-document href="#xml-tree" method="ixsl:replace-content">
            <xsl:sequence select="fn:serialize($parsed-tree-arrow-coordinates,map{'indent':true()})"/>
        </xsl:result-document>
        
        <!-- 
            Populate Javascript svg variable
            for download
        -->
        <xsl:sequence select="js:setSVG(serialize($svg, map{'indent':true()}))"/>
        
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Draw quadratic curve between points labelled @arrow-start and @arrow-end</xd:p>
            <xd:p>See <xd:a href="https://svg-tutorial.com/svg/arc">SVG tutorial</xd:a></xd:p>
        </xd:desc>
        <xd:param name="tree">Full tree.</xd:param>
        <xd:param name="vert-space">Amount of vertical space between rows (in pixels).</xd:param>
        <xd:param name="line-colour">Colour to apply to line.</xd:param>
    </xd:doc>
    <xsl:template match="dc:value[@arrow-start]" mode="draw-arrow">
        <xsl:param name="tree" as="element(dc:expression)"/>
        <xsl:param name="vert-space" as="xs:integer"/>
        <xsl:param name="line-colour" as="xs:string"/>
        
        <xsl:variable name="arrow-end" as="element(dc:value)" select="dc:get-arrow-end(.)"/>
        
        <!--<xsl:message>[draw-arrow] Arrow end: <xsl:value-of select="fn:serialize($arrow-end)"/></xsl:message>-->
        
        <xsl:variable name="start-displacement" as="xs:string" select="dc:get-arrow-dx('start',.)"/>
        <xsl:variable name="end-displacement" as="xs:string" select="dc:get-arrow-dx('end',.)"/>
        <xsl:variable name="start-dx" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$start-displacement eq 'left'">
                    <xsl:sequence select="-5"/>
                </xsl:when>
                <xsl:when test="$start-displacement eq 'right'">
                    <xsl:sequence select="5"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="end-dx" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$end-displacement eq 'left'">
                    <xsl:sequence select="-5"/>
                </xsl:when>
                <xsl:when test="$end-displacement eq 'right'">
                    <xsl:sequence select="5"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="start-x" as="xs:double" select="@x + (@width div 2) + $start-dx"/>
        <xsl:variable name="start-y" as="xs:double" select="@y + $text-margin-y"/>   
        
        <xsl:variable name="end-x" as="xs:double" select="$arrow-end/@x + ($arrow-end/@width div 2) + $end-dx"/>
        <xsl:variable name="end-y" as="xs:double" select="$arrow-end/@y + $text-margin-y"/>
        
        <xsl:variable name="bottom-y" as="xs:double" select="@arrow-bottom-y"/>
        <xsl:variable name="bottom-x" as="xs:double" select="($start-x + $end-x) div 2"/>
        <path d="M {$start-x} {$start-y} Q {$start-x} {$bottom-y} {$bottom-x} {$bottom-y}" stroke="{$line-colour}" stroke-width="2" fill="none"/>
        <path d="M {$bottom-x} {$bottom-y} Q {$end-x} {$bottom-y} {$end-x} {$end-y}" stroke="{$line-colour}" stroke-width="2" fill="none"/>
        
        <!-- arrowhead -->
        <polygon points="{$end-x},{$end-y},{$end-x - 3},{$end-y + 6},{$end-x + 3},{$end-y + 6}" style="stroke:{$line-colour};stroke-width:2;fill:{$line-colour}" />
        
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-arrow-dx() identifies whether to displace the start or end of an arrow, and in which direction, if a dc:value is both the start and end point of an arrow.</xd:p>
        </xd:desc>
        <xd:param name="arrow-end-point">Either "start" or "end".</xd:param>
        <xd:param name="item">A dc:value element.</xd:param>
        <xd:return>"left", "right, or "none".</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-arrow-dx" as="xs:string">
        <xsl:param name="arrow-end-point" as="xs:string"/>
        <xsl:param name="item" as="element(dc:value)"/>
        
        <xsl:variable name="prev-item" as="element(dc:value)?" select="if ($item/@arrow-end) then $item/ancestor::dc:expression[last()]//dc:value[@arrow-start eq $item/@arrow-end] else ()"/>
        <xsl:variable name="next-item" as="element(dc:value)" select="dc:get-arrow-end($item)"/>
         
        <!-- focus on the value at the selected end of the arrow -->
        <xsl:variable name="focus-item" as="element(dc:value)" select="if ($arrow-end-point eq 'start') then $item else $next-item"/>
        <xsl:variable name="focus-prev-item" as="element(dc:value)?" select="if ($arrow-end-point eq 'start') then $prev-item else $item"/>
        
        <xsl:choose>
            <xsl:when test="not($focus-item/@arrow-start and $focus-item/@arrow-end)">
                <xsl:sequence select="'none'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="focus-next-item" as="element(dc:value)" select="dc:get-arrow-end($focus-item)"/>
                <xsl:variable name="focus-x" as="xs:double" select="$focus-item/@x"/>
                <xsl:variable name="focus-next-x" as="xs:double" select="$focus-next-item/@x"/>
                <xsl:variable name="focus-prev-x" as="xs:double" select="$focus-prev-item/@x"/>
                <xsl:variable name="arrow-out-direction" as="xs:string" select="$focus-item/@arrow-direction"/>
                <xsl:variable name="arrow-in-direction" as="xs:string" select="$focus-prev-item/@arrow-direction"/>
                <xsl:variable name="arrow-out-bottom" as="xs:string" select="$focus-item/@arrow-bottom-y"/>
                <xsl:variable name="arrow-in-bottom" as="xs:string" select="$focus-prev-item/@arrow-bottom-y"/>
                
                <xsl:variable name="arrow-out-dx" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="$arrow-out-direction eq 'left' and $arrow-in-direction eq 'left'">
                            <xsl:sequence select="'left'"/>
                        </xsl:when>
                        <xsl:when test="$arrow-out-direction eq 'right' and $arrow-in-direction eq 'right'">
                            <xsl:sequence select="'right'"/>
                        </xsl:when>
                        <xsl:when test="$arrow-out-direction eq 'left' and $arrow-in-direction eq 'right' and ($arrow-out-bottom > $arrow-in-bottom or $focus-next-x &lt; $focus-prev-x)">
                            <xsl:sequence select="'right'"/>
                        </xsl:when>
                        <xsl:when test="$arrow-out-direction eq 'left' and $arrow-in-direction eq 'right' and ($arrow-out-bottom &lt; $arrow-in-bottom or $focus-next-x > $focus-prev-x)">
                            <xsl:sequence select="'left'"/>
                        </xsl:when>
                        <xsl:when test="$arrow-out-direction eq 'right' and $arrow-in-direction eq 'left' and ($arrow-out-bottom > $arrow-in-bottom or $focus-next-x > $focus-prev-x)">
                            <xsl:sequence select="'left'"/>
                        </xsl:when>
                        <xsl:when test="$arrow-out-direction eq 'right' and $arrow-in-direction eq 'left' and ($arrow-out-bottom &lt; $arrow-in-bottom or $focus-next-x &lt; $focus-prev-x)">
                            <xsl:sequence select="'right'"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="arrow-in-dx" as="xs:string" select="if ($arrow-out-dx eq 'left') then 'right' else 'left'"/>
                
                <xsl:sequence select="if ($arrow-end-point eq 'start') then $arrow-out-dx else $arrow-in-dx"/>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Generate SVG text box from item in linguistic tree.</xd:p>
            <xd:p>Then if we are handling a dc:category, apply templates to its child values in "line" mode to draw the lines/triangles from the category to its children.</xd:p>
        </xd:desc>
        <xd:param name="term-colour">Colour to apply to text of terminals (values).</xd:param>
        <xd:param name="nonterm-colour">Colour to apply to text of terminals (categories).</xd:param>
    </xd:doc>
    <xsl:template match="dc:category | dc:value" mode="draw-text">
        <xsl:param name="term-colour" as="xs:string"/>
        <xsl:param name="nonterm-colour" as="xs:string"/>
        
        <xsl:variable name="text-class" as="xs:string" select="if (self::dc:category) then 'nonterminal' else 'terminal'"/>
        <xsl:variable name="text-colour" as="xs:string" select="if (self::dc:category) then $nonterm-colour else $term-colour"/>
        
        <text x="{@x}" y="{@y}" class="{$text-class}" fill="{$text-colour}">
            <xsl:apply-templates select="child::node()" mode="#current"/>
            <xsl:if test="self::dc:category">
                <xsl:apply-templates select="@arrow-end" mode="#current"/>
            </xsl:if>
        </text>
        
        <xsl:variable name="line-start-x" as="xs:double" select="@x + (@width div 2)"/>
        <xsl:apply-templates select="following-sibling::dc:values/*" mode="line">
            <xsl:with-param name="start-x" as="xs:double" select="$line-start-x"/>
            <xsl:with-param name="start-y" as="xs:double" select="@y"/>
            <xsl:with-param name="draw-triangle" as="xs:boolean" select="if (@triangle eq 'yes') then true() else false()"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Parse text.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="text()" mode="draw-text">
        <xsl:sequence select="dc:parse-value(.)"/>
    </xsl:template>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Draw lines leading from category to its children. Template is applied to the child.</xd:p>
        </xd:desc>
        <xd:param name="start-x">x coordinate of start of line, derived from parent.</xd:param>
        <xd:param name="start-y">y coordinate of start of line, derived from parent.</xd:param>
        <xd:param name="draw-triangle">Boolean indicating whether to draw a triangle instead of a line.</xd:param>
        <xd:param name="vert-space">Amount of vertical space between rows (in pixels).</xd:param> 
        <xd:param name="line-colour">Colour to apply to line/triangle.</xd:param>
        <xd:param name="term-lines">Boolean indicating whether terminal lines are needed.</xd:param>
    </xd:doc>
    <xsl:template match="dc:expression | dc:value" mode="line">
        <xsl:param name="start-x" as="xs:double"/>
        <xsl:param name="start-y" as="xs:double"/>
        <xsl:param name="draw-triangle" as="xs:boolean"/>
        <xsl:param name="vert-space" as="xs:integer" tunnel="yes"/>
        <xsl:param name="line-colour" as="xs:string" tunnel="yes"/>
        <xsl:param name="term-lines" as="xs:boolean" tunnel="yes"/>
        
        <xsl:variable name="end-y" as="xs:double" select="$start-y + $vert-space - $text-margin-y"/>
        
        <xsl:choose>
            <xsl:when test="$draw-triangle">
                <xsl:variable name="base-x1" as="xs:double" select="@x"/>
                <xsl:variable name="base-x2" as="xs:double" select="@x + @width"/>
                <polygon points="{$start-x},{$start-y+$text-margin-y},{$base-x1},{$end-y},{$base-x2},{$end-y}" style="stroke:{$line-colour};stroke-width:2;fill:none" />
            </xsl:when> 
            <xsl:when test="self::dc:value[not(preceding-sibling::* or following-sibling::*)] and not($term-lines)"/>
            <xsl:otherwise>
                <xsl:variable name="end-x" as="xs:double" select="if (self::dc:expression) then (child::dc:category/@x + (child::dc:category/@width div 2)) else (@x + (@width div 2))"/>
                
                <line x1="{$start-x}" y1="{$start-y+$text-margin-y}" x2="{$end-x}" y2="{$end-y}" style="stroke:{$line-colour};stroke-width:2" />
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Render arrow-end marker (on dc:category) as subscript.</xd:p>
            <xd:p>The @dy and @baseline-shift attributes attempt to do the same thing. @baseline-shift is nore correct but not supported in Firefox browsers.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="dc:category/@arrow-end" mode="draw-text">
        <tspan class="subscript" dy="0.4em" baseline-shift="sub">
            <xsl:value-of select="."/>
        </tspan>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Add x and y coordinates to category in tree.</xd:p>
            <xd:p>x and y are measured from top left, going right and down respectively.</xd:p>
            <xd:p>x position of category is derived from the positions and widths of the first and last items immediately beneath it. Because an item might be another category we may end up calling dc:get-category-x() recursively.</xd:p>
            <xd:p>y position of category = y position of parent expression + height of text.</xd:p>
        </xd:desc>
        <xd:param name="hor-space">Amount of horizontal space between expressions/values.</xd:param>
        <xd:param name="font-size">Size of font, used to calculate row height.</xd:param>
    </xd:doc>
    <xsl:template match="dc:category" mode="add-text-coordinates">
        <xsl:param name="hor-space" as="xs:integer" tunnel="yes"/>
        <xsl:param name="font-size" as="xs:integer" tunnel="yes"/>
        
        <xsl:variable name="parent-y" as="xs:double" select="xs:double(parent::dc:expression/@y)"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="x" select="dc:get-category-x(.,$hor-space)"/>
            <xsl:attribute name="y" select="$parent-y + ($font-size * $pt-to-px)"/>
            <xsl:apply-templates select="child::node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Locate bottom of curve of arrow between items in tree.</xd:p>
        </xd:desc>
        <xd:param name="vert-space">Amount of vertical space between rows of expressions/values.</xd:param>
    </xd:doc>
    <xsl:template match="@arrow-start" mode="add-arrow-coordinates">
        <xsl:param name="vert-space" as="xs:integer" tunnel="yes"/>
        <xsl:copy-of select="."/>
        
        <xsl:variable name="start-label" as="xs:string" select="string(.)"/>
        <xsl:variable name="end-value" as="element(dc:value)" select="dc:get-arrow-end(..)"/>
        
        <xsl:variable name="start-x" as="xs:double" select="parent::dc:value/@x"/>
        <xsl:variable name="end-x" as="xs:double" select="$end-value/@x"/>
        
        <xsl:variable name="direction" as="xs:string" select="if ($start-x > $end-x) then 'left' else 'right'"/>
        
        <xsl:variable name="intervening-values" as="element(dc:value)*">
            <xsl:choose>
                <xsl:when test="$direction eq 'left'">
                    <xsl:sequence select="dc:get-prev(..,$start-label)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="dc:get-next(..,$start-label)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- 
            Add enough space below the lowest value 
            to try to ensure the arrow clears it
        -->
        <xsl:variable name="bottom-y" as="xs:double" select="max(($intervening-values|..)/@y) + (1.5 * $vert-space)"/>
        <xsl:message use-when="$LOGLEVEL ge 5">[add-arrow-coordinates] Number of items to end of arrow: <xsl:value-of select="count($intervening-values)"/></xsl:message>
        <xsl:message use-when="$LOGLEVEL ge 5">[add-arrow-coordinates] Bottom of arc: <xsl:value-of select="$bottom-y"/></xsl:message>
        <xsl:attribute name="arrow-bottom-y" select="$bottom-y"/>
        <xsl:attribute name="arrow-direction" select="$direction"/>
    </xsl:template>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function get-arrow-end() returns the dc:value element where a movement arrow ends. If the @arrow-end is on a dc:category element we choose its first dc:value.</xd:p>
        </xd:desc>
        <xd:param name="arrow-start">dc:value element with @arrow-start attribute.</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-arrow-end" as="element(dc:value)?">
        <xsl:param name="arrow-start" as="element(dc:value)"/>
        
        <xsl:variable name="arrow-label" as="xs:string" select="string($arrow-start/@arrow-start)"/>
        <xsl:variable name="arrow-end-item" as="element()*" select="$arrow-start/ancestor::dc:expression[last()]//*[@arrow-end = $arrow-label]"/>
        
        <xsl:choose>
            <xsl:when test="count($arrow-end-item) = 1">
                <xsl:variable name="arrow-end" as="element(dc:value)" select="if ($arrow-end-item[self::dc:category]) then ($arrow-end-item/following-sibling::dc:values//dc:value)[1] else $arrow-end-item"/>
                <xsl:sequence select="$arrow-end"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>[dc:get-arrow-end] ERROR: Number of @arrow-end values matching '<xsl:sequence select="$arrow-label"/>' is <xsl:value-of select="count($arrow-end-item)"/> (there must be exactly 1).</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-prev() identifies the next value to the left of the current value. Called recursively we end up with a sequence. This allows us to identify the bottom of the curve needed to join an @arrow-start to an @arrow-end without drawing over other items in the tree.</xd:p>
        </xd:desc>
        <xd:param name="this">A dc:value or dc:expression element.</xd:param>
        <xd:param name="arrow-label">The label for the arrow. We stop when we have reached the end of the chain.</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-prev" as="element(dc:value)*">
        <xsl:param name="this" as="element()"/>
        <xsl:param name="arrow-label" as="xs:string"/>
        
        <xsl:variable name="preceding-sibling" as="element()?" select="$this/preceding-sibling::*[1]"/>
        <xsl:variable name="parent-expression" as="element(dc:expression)?" select="$this/parent::dc:values/parent::dc:expression"/>  
        
        <xsl:choose>
            <xsl:when test="$preceding-sibling[self::dc:value]">
                <xsl:message use-when="$LOGLEVEL > 5">[dc:get-prev] Adding preceding sibling value <xsl:value-of select="fn:serialize($preceding-sibling)"/></xsl:message>
                <xsl:sequence select="$preceding-sibling"/>
                <xsl:if test="not($preceding-sibling/@arrow-end = $arrow-label or $preceding-sibling/parent::dc:values/preceding-sibling::dc:category/@arrow-end = $arrow-label)">
                    <xsl:sequence select="dc:get-prev($preceding-sibling,$arrow-label)"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$preceding-sibling[self::dc:expression]">
                <xsl:variable name="prec" as="element(dc:value)" select="($preceding-sibling//dc:value)[last()]"/>
                <xsl:message use-when="$LOGLEVEL > 5">[dc:get-prev] Adding preceding value from preceding sibling expression <xsl:value-of select="fn:serialize($prec)"/></xsl:message>
                <xsl:sequence select="$prec"/>
                <xsl:if test="not($prec/@arrow-end = $arrow-label or $prec/parent::dc:values/preceding-sibling::dc:category/@arrow-end = $arrow-label)">
                    <xsl:sequence select="dc:get-prev($prec,$arrow-label)"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="exists($parent-expression)">
                <xsl:sequence select="dc:get-prev($parent-expression,$arrow-label)"/>
            </xsl:when>
            
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-next() identifies the next value to the right of the current value. Called recursively we end up with a sequence. This allows us to identify the bottom of the curve needed to join an @arrow-start to an @arrow-end without drawing over other items in the tree.</xd:p>
        </xd:desc>
        <xd:param name="this">A dc:value or dc:expression element.</xd:param>
        <xd:param name="arrow-label">The label for the arrow. We stop when we have reached the end of the chain.</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-next" as="element(dc:value)*">
        <xsl:param name="this" as="element()"/>
        <xsl:param name="arrow-label" as="xs:string"/>
        
        <xsl:variable name="following-sibling" as="element()?" select="$this/following-sibling::*[1]"/>
        <xsl:variable name="parent-expression" as="element(dc:expression)?" select="$this/parent::dc:values/parent::dc:expression"/>  
        
        <xsl:choose>
            <xsl:when test="$following-sibling[self::dc:value]">
                <xsl:message use-when="$LOGLEVEL > 5">[dc:get-next] Adding following sibling value <xsl:value-of select="fn:serialize($following-sibling)"/></xsl:message>
                <xsl:sequence select="$following-sibling"/>
                <xsl:if test="not($following-sibling/@arrow-end or $following-sibling/parent::dc:values/preceding-sibling::dc:category/@arrow-end = $arrow-label)">
                    <xsl:sequence select="dc:get-next($following-sibling,$arrow-label)"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$following-sibling[self::dc:expression]">
                <xsl:variable name="next" as="element(dc:value)" select="($following-sibling//dc:value)[1]"/>
                <xsl:message use-when="$LOGLEVEL > 5">[dc:get-next] Adding following value from following sibling expression <xsl:value-of select="fn:serialize($next)"/></xsl:message>
                <xsl:sequence select="$next"/>
                <xsl:if test="not($next/@arrow-end = $arrow-label or $next/parent::dc:values/preceding-sibling::dc:category/@arrow-end = $arrow-label)">
                    <xsl:sequence select="dc:get-next($next,$arrow-label)"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="exists($parent-expression)">
                <xsl:sequence select="dc:get-next($parent-expression,$arrow-label)"/>
            </xsl:when>
            
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Add x and y coordinates to value in tree.</xd:p>
            <xd:p>x and y are measured from top left, going right and down respectively.</xd:p>
            <xd:p>x position of value derived from x coordinate of parent expression (if it is the first value underneath the parent category), or x position of preceding sibling expression/value + its width + horizontal space.</xd:p>
            <xd:p>y position of value = y position of parent expression + row height + vertical space between rows.</xd:p>
        </xd:desc>
        <xd:param name="hor-space">Amount of horizontal space between expressions/values.</xd:param>
        <xd:param name="vert-space">Amount of vertical space between rows of expressions/values.</xd:param>
        <xd:param name="font-size">Size of font, used to calculate row height.</xd:param>
        <xd:param name="term-lines">Boolean indicating whether terminal lines are needed. This affects the y coordinate of the text.</xd:param>
    </xd:doc>
    <xsl:template match="dc:value" mode="add-text-coordinates">
        <xsl:param name="hor-space" as="xs:integer" tunnel="yes"/>
        <xsl:param name="vert-space" as="xs:integer" tunnel="yes"/>
        <xsl:param name="font-size" as="xs:integer" tunnel="yes"/>
        <xsl:param name="term-lines" as="xs:boolean" tunnel="yes"/>
        
        <xsl:variable name="parent-y" as="xs:double" select="xs:double(parent::dc:values/parent::dc:expression/@y)"/>
        
        <!-- 
            Adjustment to a default 10 pixels
            if the terminal lines are switched off.
            (Otherwise we use the $vert-space value, 
            which create space for the terminal line.)
        -->
        <xsl:variable name="vert-space-adjusted" as="xs:integer" select="if ($term-lines or parent::dc:values/preceding-sibling::dc:category/@triangle or preceding-sibling::* or following-sibling::*) then $vert-space else 10"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="x" select="dc:get-value-x(.,$hor-space)"/>
            <xsl:attribute name="y" select="$parent-y + ($font-size * $pt-to-px) + $vert-space-adjusted + ($font-size * $pt-to-px)"/>
            <xsl:apply-templates select="child::node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Add x and y coordinates to expression in tree.</xd:p>
            <xd:p>x and y are measured from top left, going right and down respectively.</xd:p>
            <xd:p>x position of expression = x position of parent expression + width of preceding sibling expressions/values + horizontal spaces.</xd:p>
            <xd:p>x position of top expression is left margin.</xd:p>
            <xd:p>Width of expression is derived from width of items within it. The function dc:get-expression-width() is called recursively with dc:get-width() to achieve this.</xd:p>
        </xd:desc>
        <xd:param name="hor-space">Amount of horizontal space between expressions/values.</xd:param>
        <xd:param name="vert-space">Amount of vertical space between rows of expressions/values.</xd:param>
        <xd:param name="font-size">Size of font, used to calculate row height.</xd:param>
    </xd:doc>
    <xsl:template match="dc:expression" mode="add-expression-coordinates">
        <xsl:param name="hor-space" as="xs:integer" tunnel="yes"/>
        <xsl:param name="vert-space" as="xs:integer" tunnel="yes"/>
        <xsl:param name="font-size" as="xs:integer" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:attribute name="x" select="dc:get-expression-x(.,$hor-space)"/>
            <xsl:attribute name="y" select="dc:get-expression-y(.,$vert-space,$font-size)"/>
            <xsl:attribute name="width" select="dc:get-expression-width(.,$hor-space)"/>
            <xsl:apply-templates select="@*,child::node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Add width to category in tree.</xd:p>
            <xd:p>Make sure to pass a string (and not a text node) to js:getTextWidth().</xd:p>
        </xd:desc>
        <xd:param name="nonterm-font">Font value for a non-terminal value, e.g. "12pt".</xd:param>
    </xd:doc>
    <xsl:template match="dc:category" mode="add-widths">
        <xsl:param name="nonterm-font" as="xs:string" tunnel="yes" required="yes"/>
        <xsl:variable name="width" as="xs:double" select="js:getTextWidth(string(text()),$nonterm-font)"/>
        <xsl:copy>
            <xsl:attribute name="width" select="$width"/>
            <xsl:apply-templates select="@*,child::node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Add width to value in tree.</xd:p>
        </xd:desc>
        <xd:param name="term-font">Font value for a terminal value, e.g. "12pt".</xd:param>
    </xd:doc>
    <xsl:template match="dc:value" mode="add-widths">
        <xsl:param name="term-font" as="xs:string" tunnel="yes" required="yes"/>
        
        <xsl:variable name="parsed-value" as="xs:string" select="dc:parse-value(text())"/>
        
        <xsl:variable name="width" as="xs:double" select="js:getTextWidth($parsed-value,$term-font)"/>
        <xsl:copy>
            <xsl:attribute name="width" select="$width"/>
            <xsl:apply-templates select="@*,child::node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-text-tree() returns content of HTML textarea element with ID 'text-tree'</xd:p>
            <xd:p>(TO DO: implement this using XForms.)</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-text-tree" as="xs:string?">
        <xsl:variable name="textarea" as="element(h:textarea)" select="$page//h:textarea[@id eq 'text-tree']"/>
        <xsl:sequence select="ixsl:get($textarea, 'value')"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-vertical-space() returns setting of vertical space from input on page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-vertical-space" as="xs:integer">
        <xsl:variable name="input" as="element(h:input)" select="$page//h:input[@id eq 'height']"/>
        <xsl:sequence select="ixsl:get($input, 'value')"/>
    </xsl:function>

    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-horizontal-space() returns setting of vertical space from input on page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-horizontal-space" as="xs:integer">
        <xsl:variable name="input" as="element(h:input)" select="$page//h:input[@id eq 'width']"/>
        <xsl:sequence select="ixsl:get($input, 'value')"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-font-size() returns setting of font size from input on page.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="dc:get-font-size" as="xs:integer">
        <xsl:variable name="input" as="element(h:input)" select="$page//h:input[@id eq 'size']"/>
        <xsl:sequence select="ixsl:get($input, 'value')"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-button-state() identifies whether a button is active.</xd:p>
            <xd:p>Buttons in the HTML are used to select font-family, weight, and style.</xd:p>
        </xd:desc>
        <xd:param name="button-id">Value of button/@id.</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-button-state" as="xs:string?">
        <xsl:param name="button-id" as="xs:string"/>
        <xsl:variable name="input" as="element(h:button)" select="$page//h:button[@id eq $button-id]"/>
        <xsl:choose>
            <xsl:when test="$input[@class eq 'active']">
                <xsl:sequence select="'active'"/>
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-colour() returns setting of colour size from named radio button.</xd:p>
        </xd:desc>
        <xd:param name="radio-name">Value of input/@name in HTML radio buttons.</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-colour" as="xs:string">
        <xsl:param name="radio-name" as="xs:string"/>
        <xsl:variable name="colour" as="xs:string" select="js:getColour($radio-name)"/>
        <!--<xsl:message>[dc:get-colour] name: <xsl:sequence select="$radio-name"/>; colour: <xsl:value-of select="$colour"/></xsl:message>-->
        <xsl:value-of select="$colour"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:parse-text-tree() analyses a text tree and converts it to an XML structure, if it is a valid expression.</xd:p>
        </xd:desc>
        <xd:param name="text-tree">Text linguistics tree.</xd:param>
        <xd:return>JSON version of tree.</xd:return>
    </xd:doc>
    <xsl:function name="dc:parse-text-tree" as="element(dc:expression)?" visibility="public">
        <xsl:param name="text-tree" as="xs:string"/>
        
        <!-- 
            check that expression matches "[... ...]"
        -->
        <xsl:variable name="ok1" as="xs:boolean" select="fn:matches($text-tree,$expression-regex)"/>
        
        <xsl:variable name="ok2" as="xs:boolean" select="dc:is-balanced($text-tree)"/>
        
        <xsl:choose>
            <xsl:when test="$ok1 and $ok2">
                <xsl:analyze-string select="$text-tree" regex="{$expression-regex}">
                    <xsl:matching-substring>
                        <dc:expression>
                            <xsl:sequence select="dc:get-category(regex-group(1))"/>
                            
                            <xsl:variable name="values" as="xs:string+" select="dc:get-expression-values(regex-group(2))"/>
                            <dc:values>
                                <xsl:for-each select="$values">
                                    <xsl:message use-when="$LOGLEVEL ge 5">[dc:parse-text-tree] Parsing value "<xsl:sequence select="."/>"</xsl:message>
                                    <xsl:choose>
                                        <xsl:when test="matches(.,$expression-regex)">
                                            <xsl:sequence select="dc:parse-text-tree(.)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="dc:get-value(normalize-space(.))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </dc:values>
                            
                        </dc:expression>
                    </xsl:matching-substring>
                </xsl:analyze-string>
                
               
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>[dc:parse-text-tree] ERROR: Bad expression!</xsl:message>
                <xsl:message>[dc:parse-text-tree] <xsl:sequence select="if (not($ok2)) then 'Number of [ does not match number of ]' else 'does not match regex'"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:parse-value() maps some characters allowed as alternstives. E.g. '\0' to 'Ø' and '{}' to '[]'.</xd:p>
        </xd:desc>
        <xd:param name="unparsed-text">Content of a dc:value element.</xd:param>
    </xd:doc>
    <xsl:function name="dc:parse-value" as="xs:string">
        <xsl:param name="unparsed-text" as="xs:string"/>
        
        <xsl:variable name="pass1" as="xs:string" select="replace($unparsed-text,'\\0','Ø')"/>
        <xsl:variable name="pass2" as="xs:string" select="translate($pass1,'{}','[]')"/>
        <xsl:sequence select="$pass2"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-category() parses the string representing a category in a linguistic espression.</xd:p>
            <xd:p>A marker for a triangle connector ('^' in the plain text) is flagged, as is a marker for the end of an arrow ('_1' in the plain text).</xd:p>
        </xd:desc>
        <xd:param name="category">String representing a category, with possible markers.</xd:param>
        <xd:return>A category element, with attributes representing the markers and content the remaining string.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-category" as="element()">
        <xsl:param name="category" as="xs:string"/>
        <xsl:variable name="has-triangle" as="xs:boolean" select="contains($category,'^')"/>
        <xsl:variable name="category-parsed-1" as="xs:string" select="translate($category,'\^','')"/>
        <xsl:variable name="arrow-end" as="xs:string?" select="fn:substring-after($category-parsed-1,'_')"/>
        <xsl:variable name="category-parsed-2" as="xs:string" select="if ($arrow-end) then fn:substring-before($category-parsed-1,'_') else $category-parsed-1"/>
        <dc:category>
            <xsl:if test="$has-triangle">
                <xsl:attribute name="triangle" select="'yes'"/>
            </xsl:if>
            <xsl:if test="$arrow-end">
                <xsl:attribute name="arrow-end" select="$arrow-end"/>
            </xsl:if>
            <xsl:sequence select="$category-parsed-2"/>
        </dc:category>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-value() parses the string representing a category in a linguistic espression.</xd:p>
            <xd:p>A marker for the start of an arrow ('&lt;1&gt;' in the plain text) or end ('_1') is flagged.</xd:p>
        </xd:desc>
        <xd:param name="value">String representing a value, with possible markers.</xd:param>
        <xd:return>A value-text element, with attribute representing the marker and content the remaining string.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-value" as="element()">
        <xsl:param name="value" as="xs:string"/>
        
        <xsl:variable name="arrow-start" as="xs:string?" select="fn:substring-after(fn:substring-before($value,'&gt;'),'&lt;')"/>
        <xsl:variable name="value-parsed-1" as="xs:string" select="replace($value,'&lt;[^>]+>','')"/>
        
        <!--<xsl:message>[dc:get-value] First pass on value '<xsl:value-of select="$value"/>' is '<xsl:value-of select="$value-parsed-1"/>'</xsl:message>-->
        <xsl:variable name="arrow-end" as="xs:string?" select="fn:substring-after($value-parsed-1,'_')"/>
        <xsl:variable name="value-parsed-2" as="xs:string" select="if ($arrow-end) then fn:substring-before($value-parsed-1,'_') else $value-parsed-1"/>
        
        <!--<xsl:message>[dc:get-value] Second pass on value '<xsl:value-of select="$value"/>' is '<xsl:value-of select="$value-parsed-2"/>'</xsl:message>
        <xsl:message>[dc:get-value] Arrow end label is '<xsl:value-of select="$arrow-end"/>'</xsl:message>-->
        
        <dc:value>
            <xsl:if test="$arrow-start">
                <xsl:attribute name="arrow-start" select="$arrow-start"/>
            </xsl:if>
            <xsl:if test="$arrow-end">
                <xsl:attribute name="arrow-end" select="$arrow-end"/>
            </xsl:if>
            <xsl:sequence select="$value-parsed-2"/>
        </dc:value>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-expression-values() converts a string that may consist of multiple expressions into a sequence of strings, each containing a single value or expression.</xd:p>
        </xd:desc>
        <xd:param name="value">The value part of a linguistic expression, which may be a single value, or a sequence of expressions.</xd:param>
    </xd:doc>
    <xsl:function name="dc:get-expression-values" as="xs:string+">
        <xsl:param name="value" as="xs:string"/>
        <xsl:analyze-string select="$value" regex="{$expression-candidate}">
            <xsl:matching-substring>
                <xsl:variable name="candidate" as="xs:string" select="regex-group(1)"/>
                <xsl:variable name="remainder" as="xs:string?" select="regex-group(2)"/>
                <xsl:choose>
                    <!-- 
                        sometimes we look for a candidate value that has spaces
                        so we determine its end when we hit a '[' for the following expression
                        
                        This character must be removed from the candidate and attached to the remainder.
                        See definition of $expression-candidate
                    -->
                    <xsl:when test="ends-with($candidate,'[')">
                        <xsl:sequence select="substring($candidate,1,string-length($candidate) - 1)"/>
                        
                        <xsl:sequence select="dc:get-expression-values('[' || $remainder)"/>
                    </xsl:when>
                    <xsl:when test="dc:is-balanced($candidate)">
                        <xsl:message use-when="$LOGLEVEL ge 5">[dc:get-expression-values] Found valid split with candidate '<xsl:sequence select="$candidate"/>' and remainder '<xsl:sequence select="$remainder"/>'</xsl:message>
                        
                        <xsl:sequence select="$candidate"/>
                        
                        <xsl:if test="exists($remainder) and fn:normalize-space($remainder) ne ''">
                            <xsl:sequence select="dc:get-expression-values($remainder)"/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="split" as="xs:string+" select="dc:get-split($candidate,$remainder)"/>
                        <xsl:variable name="new-candidate" as="xs:string" select="$split[1]"/>
                        <xsl:variable name="new-remainder" as="xs:string?" select="$split[2]"/>
                        
                        <xsl:sequence select="$new-candidate"/>
                        
                        <xsl:if test="exists($new-remainder) and fn:normalize-space($new-remainder) ne ''">
                            <xsl:sequence select="dc:get-expression-values($new-remainder)"/>
                        </xsl:if>
                        
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="$value"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:is-balanced() determines whether an expression has a matching number of '[' and ']' characters.</xd:p>
        </xd:desc>
        <xd:param name="expression">String that is a linguistic expression, or part of one.</xd:param>
    </xd:doc>
    <xsl:function name="dc:is-balanced" as="xs:boolean">
        <xsl:param name="expression" as="xs:string"/>
        
        <xsl:variable name="openings" as="xs:string" select="replace($expression,'[^\[]','')"/>
        <xsl:variable name="closings" as="xs:string" select="replace($expression,'[^\]]','')"/>
        
        <xsl:sequence select="string-length($openings) = string-length($closings)"/>
    </xsl:function>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Function dc:get-split() gets a balanced expression from the start of a parent expression's value.</xd:p>
        </xd:desc>
        <xd:param name="candidate">Unbalanced expression, split too early.</xd:param>
        <xd:param name="remainder">Remainder of parent expression's value, starting with end of candidate expression.</xd:param>
        <xd:return>New candidate sequence consisting of candidate with more characters grabbed from remainder, and new remainder.</xd:return>
    </xd:doc>
    <xsl:function name="dc:get-split" as="xs:string+">
        <xsl:param name="candidate" as="xs:string"/>
        <xsl:param name="remainder" as="xs:string"/>
        
        <xsl:choose>
            <xsl:when test="dc:is-balanced($candidate)">
                <xsl:message use-when="$LOGLEVEL ge 4">[dc:get-split] Found valid split:
    Candidate: 
        <xsl:sequence select="$candidate"/>
                    
    Remainder:
        <xsl:sequence select="$remainder"/></xsl:message>
                <xsl:sequence select="($candidate,$remainder)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:analyze-string select="$remainder" regex="^([^\]]*\])([\s\S]*)$">
                    <xsl:matching-substring>
                        
                        <xsl:variable name="new-candidate" as="xs:string" select="$candidate || regex-group(1)"/>
                        <xsl:variable name="new-remainder" as="xs:string" select="regex-group(2)"/>       
                        <xsl:message use-when="$LOGLEVEL ge 4">[dc:get-split] Checking split:
    New candidate: 
        <xsl:sequence select="$new-candidate"/>
                            
    New remainder: 
        <xsl:sequence select="$new-remainder"/></xsl:message>
                        <xsl:sequence select="dc:get-split($new-candidate, $new-remainder)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:message>[dc:get-split] Problem parsing: 
    Candidate: 
        <xsl:sequence select="$candidate"/>
                            
    Remainder:
        <xsl:sequence select="$remainder"/></xsl:message>
                        <xsl:sequence select="($candidate,$remainder)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xd:doc scope="component">
        <xd:desc>Add Javascript to HTML head element</xd:desc>
    </xd:doc>
    <xsl:template match="h:head" mode="set-js">
        <!-- 
            for ixsl:page() 
            see http://www.saxonica.com/saxon-js/documentation/index.html#!ixsl-extension/functions/page
                    
            "the document node of the HTML DOM document"
            
            for href="?." 
            see http://www.saxonica.com/saxon-js/documentation/index.html#!development/result-documents
                        
            "the current context item as the target for inserting a generated fragment of HTML"
        -->
        
        <xsl:result-document href="?.">
            <script type="text/javascript">
                <xsl:sequence select="$linguistics-javascript"/>
            </script>
        </xsl:result-document>   
        
        
       
    </xsl:template>
    
</xsl:stylesheet>