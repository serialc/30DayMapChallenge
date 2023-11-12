# Generate reference tiles

# hold parts in variables
svgopen = '<svg width="208mm" height="180mm" viewBox="0 0 208 180" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">'
svgclose = '</svg>'

line_style = 'fill:none;stroke:#000000;stroke-width:5;stroke-linejoin:bevel;stroke-miterlimit:10'

dirdict = {
        1: "M 52.038459,60 104, 30",
        2: "m 104,30 51.96153,30",
        4: "M 52.038459,120 V 60",
        8: "M 155.96152,60 V 120",
        16: "M 104,150 52.038459,120",
        32: "M 155.96152,120 104,150"
}

textopen = '<text style="font-size:88.1944px;line-height:1.25;font-family:sans-serif;text-align:center;text-anchor:middle;stroke-width:0.3" x="104.08822" y="121.4854">'
textclose = '</text>'

#for tnum in [1,2,4,8,16,32]:
for tnum in range(64):

    print(tnum)
    bcode = '{0:06b}'.format(tnum)

    # create svg
    with open("" + str(tnum) + ".svg", 'w') as fh:

        fh.write(svgopen)

        if bcode[5] == '1':
            fh.write('<path style="' + line_style + '" d="' + dirdict[1] + '" />')
        if bcode[4] == '1':
            fh.write('<path style="' + line_style + '" d="' + dirdict[2] + '" />')
        if bcode[3] == '1':
            fh.write('<path style="' + line_style + '" d="' + dirdict[4] + '" />')
        if bcode[2] == '1':
            fh.write('<path style="' + line_style + '" d="' + dirdict[8] + '" />')
        if bcode[1] == '1':
            fh.write('<path style="' + line_style + '" d="' + dirdict[16] + '" />')
        if bcode[0] == '1':
            fh.write('<path style="' + line_style + '" d="' + dirdict[32] + '" />')

        fh.write(textopen + str(tnum) + textclose)
        fh.write(svgclose)

