#!/usr/bin/env python

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))

import iptcinfo

def checkrefid(filename,fileobj,ncounter):

    """
    ----------------------------------------------------
    write clean header for refid update
    ----------------------------------------------------
    """

    nDisplay = 0

    #~ if chkfile(filename):
    info = iptcinfo.IPTCInfo(filename,force=True)

    if len(info.data) > 3:
        if info.data['reference number'] >= 0 or info.data['reference number'] <> None:
            ldigit = info.data['reference number'].isdigit()
            if ldigit:
                nDisplay = 1
            else:
                nDisplay = 2
                info.keywords = []
                info.supplementalCategories = []
                info.contacts = []
                info.data['reference number'] = [0]
                info.save()
        else:
            nDisplay = 3
            info.keywords = []
            info.supplementalCategories = []
            info.contacts = []
            info.data['reference number'] = [0]
            info.save()

    print "number.... ",ncounter , filename

    if nDisplay == 2 or nDisplay == 3:
        try:
            info = iptcinfo.IPTCInfo(filename)
            fileobj.writelines('"' + str(nDisplay) + '","' + str(ncounter) + '","' + str(info.data['reference number']) + '","' + filename + '"' + "\n")
        except:
            fileobj.writelines('"' + str(nDisplay) + '","' + str(ncounter) + '","000000","' + filename + '"' + "\n")
    elif nDisplay == 1:
        fileobj.writelines('"' + str(nDisplay) + '","' + str(ncounter) + '","' + str(info.data['reference number']) + '","' + filename + '"' + "\n")

    else:
        fileobj.writelines('"DONT EXIST","' + filename + '"' + "\n")

    if nDisplay == 0:
        fileobj.writelines('"' + str(nDisplay) + '","' + str(ncounter) + '","000000","' + filename + '"' + "\n")
    return

if '__main__' == __name__:
    checkrefid('test.jpg', sys.stdout, 100)


##
## -IPTC:objectpreviewfileformat=0


##
