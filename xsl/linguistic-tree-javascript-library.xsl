<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="3.0">
    
    <xsl:variable name="linguistics-javascript" as="xs:string">
        var canvas = document.createElement("canvas");
        var ctx = canvas.getContext('2d');
        
        var indent0 = "\n";
        var indent1 = "\n\t";
        var indent2 = "\n\t\t";
        var indent3 = "\n\t\t\t";
        var indent4 = "\n\t\t\t\t";
        var indent5 = "\n\t\t\t\t\t";
        var indent6 = "\n\t\t\t\t\t\t";
        var indent7 = "\n\t\t\t\t\t\t\t";
        
        var example_01 = "[CP \n\t[C \\0]\n\t[TP \n\t\t[CP^ that Erin likes sushi ]\n\t\t[T {past}]\n\t\t[VP\n\t\t\t[V surprised]\n\t\t\t[DP \n\t\t\t\t[D me]\n\t\t\t]\n\t\t]\n\t]\n]";
        
        var example_02 = "[CP [C'"
        + indent2 +
        "[C \\0]"
        + indent2 +
        "[TP"
        + indent3 +
        "[DP^ Sarah]"
        + indent3 +
        "[T' tT&lt;1>"
        + indent4 +
        "[VP [V'"
        + indent6 +
        "[AdvP [Adv' [Adv often]]]"
        + indent6 +
        "[V'"
        + indent7 +
        "[V+T_1 walk+{past}]"
        + indent7 +
        "[DP^ home]"
        + indent6 +
        "]"
        + indent4 +
        "]]"
        + indent2 +
        "]"
        + indent0 +
        "]]]";
        
        var example_03 = "[CP [C'"
        + indent2 +
        "[C+V+T_2 \\0+BE+{pres}]"
        + indent2 +
        "[TP"
        + indent3 +
        "[DP^ Sarah]"
        + indent3 +
        "[T'"
        + indent4 +
        "tT&lt;2&gt;_1"
        + indent4 +
        "[VP [V'"
        + indent5 +
        "tV&lt;1&gt;"
        + indent5 +
        "[VP"
        + indent6 +
        "[V'"
        + indent7 +
        "[V eating]"
        + indent7 +
        "[DP^ fruit]"
        + indent6 +
        "]"
        + indent5 +
        "]"
        + indent4 +
        "]]"
        + indent3 +
        "]"
        + indent2 +
        "]"
        + indent0 +
        "]]";
        
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
        
        var setPlaintext = function(example) {
            var textBox = document.getElementById("text-tree");
            var generateButton = document.getElementById("submit");
            switch (example) {
                case '1':
                    textBox.value = example_01;
                    break;
                case '2':
                    textBox.value = example_02;
                    break;
                case '3':
                    textBox.value = example_03;
             }
            textBox.scrollIntoView();
            generateButton.click();
        }

    </xsl:variable>
</xsl:stylesheet>