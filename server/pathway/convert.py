from collections import defaultdict
import json
from lxml import objectify
from optparse import OptionParser
import sys
      
def helpMes():
    print( "-f/--file   read kgml from FILENAME(omit '.xml'), produce two files: genelist and relation")
    
if __name__ == '__main__':

    usage = "usage: %prog [options]"  
    parser = OptionParser(usage)  
    parser.add_option("-f", "--file", dest="filename",  
                      help="read kgml from FILENAME(omit '.xml'), produce two files: genelist and relation")
    (options, args) = parser.parse_args(sys.argv)
    if options.filename is None:
        helpMes()
        exit(1)
    else:
        File = options.filename
 
    inFile = File+'.xml'
    outFile = File
    content = open(inFile).read()

    graphics = defaultdict(dict)
    genes = defaultdict(dict)
    xml = objectify.fromstring(content)

    links_reaction = defaultdict(list)
    for reaction_xml in getattr(xml, 'reaction', []):

        reversible = reaction_xml.get('type') == 'reversible'
        substrates = tuple(x.get('name') for x in getattr(reaction_xml, 'substrate', []))
        products = tuple(x.get('name') for x in getattr(reaction_xml, 'product', []))

        
        ID = reaction_xml.get('id')
        name = reaction_xml.get('name')
        key = (name, reversible, substrates, products)
        links_reaction[key].append(ID)


    reactions = {}
    for (name, reversible, substrates, products), IDs in links_reaction.items():

        ID = IDs[0]
        reaction = {}
        reaction.update({
            'name': name,
            'substrates': substrates,
            'products': products,
            'reversible': reversible,
            'related-reactions': IDs[1:],
        })
        reactions[name] = reaction
    component = {}
    for entry in getattr(xml, 'entry', []):

        ID = entry.get('id')
        t = entry.get('type')
        g = entry.graphics[0]

        graphics[ID] = {
            'type': t,
            'entryID': ID,
            'name': entry.get('name'),
        }
        genes[t][ID] = {
            'type': t,
            'reaction': '',
            'name': entry.get('name'),
        }
        if( t == 'group' ):
            comID = tuple(x.get('id') for x in getattr(entry, 'component', []))
            component[ID] = comID
            
        if( entry.get('reaction') in reactions ):
            genes[t][ID]['reaction']=reactions[entry.get('reaction')]
    
    links_relation = defaultdict(list)
    for relation_xml in getattr(xml, 'relation', []):
        
        Type = relation_xml.get('type')
        flag = 0
        Entry1 = ''
        Entry2 = ''
        for x in getattr(relation_xml, 'subtype', []):
            y = x.get('name')
            if( y == 'activation' or y == 'expression' or y == 'indirect effect' ):
                flag = 1

            if( y == 'inhibition' or y == 'regression' ):
                flag = 2

            if( y == 'link'):
                flag = 3
                
        if( flag == 1 ):
            Entry1 = relation_xml.get('entry1')
            Entry2 = relation_xml.get('entry2')
            subtype = 'activation'
    
        if( flag == 2 ):
            Entry1 = relation_xml.get('entry1')
            Entry2 = relation_xml.get('entry2')
            subtype = 'inhibition'

        if( flag == 3):
            Entry1 = relation_xml.get('entry1')
            Entry2 = relation_xml.get('entry2')
            
        if( flag != 0 ):
            key = ( Type, Entry1, Entry2, subtype )
            Entry = ( Entry1, Entry2 )
            links_relation[key].append( Entry )

    
    ID = 0;
    relations = {}
    for (Type, Entry1, Entry2, subtype ), IDs in links_relation.items():

        if( graphics[IDs[0][0]]['type'] == 'gene' or graphics[IDs[0][1]]['type'] == 'gene' ):
            Entry1Attr = graphics[IDs[0][0]]
            if( Entry1Attr['type'] == 'group' ):
                Entry1Attr['group'] = component[Entry1Attr['entryID']]
            Entry2Attr = graphics[IDs[0][1]]
            if( Entry2Attr['type'] == 'group' ):
                Entry2Attr['group'] = component[Entry2Attr['entryID']]
                
        relation = {}
        relation.update({
            'type': Type,
            'entry1': Entry1Attr,
            'entry2': Entry2Attr,
            'subtype':subtype,

        })
        relations[ID] = relation
        ID = ID + 1;


        
    json.dump({
        'relations': relations,
    }, open(outFile+'_relation.json', 'w'))


    json.dump({
        'genes': genes,
    }, open(outFile+'_genes.json', 'w'))
