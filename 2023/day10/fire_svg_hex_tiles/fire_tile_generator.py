# Generate reference tiles

# hold parts in variables
svgopen = '<svg width="208mm" height="180mm" viewBox="0 0 208 180" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">'
svgclose = '</svg>'

line_style = 'fill:none;stroke:#000000;stroke-width:5;stroke-linejoin:bevel;stroke-miterlimit:10'

dirdict = {
        1: "M 78.019224,45 104,90",
        2: "M 129.98075,45 104,90",
        4: "m 52.038458,90 51.961532,0",
        8: "m 104,90 51.96153,0",
        16: "M 78.019224,135 104,90",
        32: "M 129.98075,135 104,90"
}

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

        fh.write(svgclose)

