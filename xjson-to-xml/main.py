#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import json
import sys

def attrsAndValue(d):
    if isinstance(d, dict) and (('@' in d) or ("#" in d)):
        return (d.get('@'), d.get("#"))
    else:
        return ({}, d)

def makeEl(parent, name, attributes):
    el = ET.SubElement(parent, name)
    for aname, aval in attributes.items():
        el.set(aname, aval)
    return el

def iteritem(root, k, v):
    attrs, val = attrsAndValue(v)
    if isinstance(val, dict):
        el = makeEl(root, k, attrs)
        iterdict(el, val)
    elif isinstance(val, list):
        for vv in val:
            iteritem(root, k, vv)
    else:
        el = makeEl(root, k, attrs)
        el.text = val

def iterdict(root, d):
    for k,v in d.items():
        iteritem(root, k, v)

rootTagName = sys.argv[1]
        
doc = json.loads(sys.stdin.read())
root = ET.Element(rootTagName)

iterdict(root, doc)
ET.dump(root)
