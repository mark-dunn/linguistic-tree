<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="3.0">
    
    <xsl:variable name="linguistics-javascript" as="xs:string">
        var canvas = document.createElement("canvas");
        var ctx = canvas.getContext('2d');
        
        var svg = null;
        
        var setSVG = function(content) {
            svg = "&lt;?xml version=\"1.0\" encoding=\"UTF-8\"?>\n&lt;!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n" + content;
        }
         
        var download = function() {
            var a = document.createElement('a');
            var blob = new Blob([svg], {type: 'image/svg+xml'});
            var url = URL.createObjectURL(blob);
            a.setAttribute('href', url);
            a.setAttribute('download', 'tree.svg');
            a.click();
         }
         
        var getTextWidth = function(value,font) {
            ctx.font = font;
            var w = ctx.measureText(value).width
            //console.log('[getTextWidth] ' + value + ' ' + w);
            return w;
        }
        
        var toggleActive = function(ID) {
            var item = document.getElementById(ID);
            if (item.className == 'active') {
                item.classList.remove('active');
            }
            else {
                item.classList.add('active');
            }   
        }
        
        var toggleFont = function(ID) {
            var item = document.getElementById(ID);
            if (item.className == 'active') {
                // do nothing
            }
            else {
                item.classList.add('active');
                switch (ID) {
                    case 'style-serif': 
                    document.getElementById('style-sansserif').classList.remove('active');
                    document.getElementById('style-monospace').classList.remove('active');
                    break;                    
                    case 'style-sansserif': 
                    document.getElementById('style-serif').classList.remove('active');
                    document.getElementById('style-monospace').classList.remove('active');
                    break;                    
                    case 'style-monospace': 
                    document.getElementById('style-serif').classList.remove('active');
                    document.getElementById('style-sansserif').classList.remove('active');
                    }
            }   
            
        }

        var getColour = function(radioName) {
            var selector = 'input[name="' + radioName + '"]:checked';
            return document.querySelector(selector).value;
        }

    </xsl:variable>
</xsl:stylesheet>