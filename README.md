# linguistic-tree
Create a syntax tree from a plain text format using XSLT executed by SaxonJS in a browser.

Inspired by Miles Shang's [syntree](https://mshang.ca/syntree/).

This version creates diagrams in SVG format using XSLT.

## Setting up the tool

The stylesheet must be compiled and executed using [SaxonJS](https://www.saxonica.com/saxonjs).

Deploy `index.xhtml`, the compiled SEF, and a copy of SaxonJS to your web host.

Open `index.xhtml` in your browser to run the tool.

An instance of the tool is deployed at <https://linguistics.datacraft.co.uk>

## Using the tool

The plain text format consists of a collection of nested expressions.

An expression consists of square brackets containing a category label followed by one or more space-separated values.

```
[category value+]
```

A value may be either a single string or a nested expression.

The tool lays out the category labels and values, and draws lines between them.

### Additional features of the plain text format

If a category label includes the `^` character a triangle will be drawn to its value, instead of a line.

Movement arrows can be indicated by appending `<1>` to the value where the arrow starts and `_1` to the category or value where it ends.

Use different arrow labels if there is more than one arrow in the tree, e.g. `<2>`.

The combination `\0` can be used to produce the character `Ø`.

If a value needs to include square brackets, use `{}` characters in the plain text format, since square brackets are reserved for identifying expressions.

### Additional features of the tool

Various controls are provided to change the font style of terminal and non-terminal values in the tree, to change the line colour, and to download the generated SVG file.

