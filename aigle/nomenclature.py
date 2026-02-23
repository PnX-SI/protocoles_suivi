

import json

template = '{"type": "{TYPE}", "cd_nomenclature": "{label}", "mnemonique":"{label}", "label_default":"{label}", "definition_default":"{label}"}'

l = [
"non suivi",
"reproduction en cours",
"1 jeune envolé",
"2 jeunes envolés",
"échec",
"pas de conclusion possible",
"pas de reproduction constatée",
]

nom_type = "AIGLE_STATUT_REPRODUCTION"
template = template.replace("{TYPE}", nom_type)
final_json = []
for el in l :
    temp = template.replace("{label}", el)
    to_dict = json.loads(temp)
    # print(to_dict)
    to_dict["cd_nomenclature"] = to_dict["cd_nomenclature"].replace(" ", "_").upper()
    final_json.append(
        to_dict
    )
    

print(
    json.dumps(final_json, indent=4, ensure_ascii=False).encode("utf-").decode()
)







# l = [
# "calcaires", 
# "quartzites", 
# "flyschs", 
# "cristallin", 
# "magmatiques", 
# "métamorphique", 
# "sédimentaires", 
# "végétal", 
# "inconnu", 
# "basaltes", 
# "spilites", 
# "andésites", 
# "diorites", 
# "dolérites", 
# "syérites", 
# "calcschistes", 
# "cipolins", 
# "grès", 
# "micaschistes", 
# "cargneules", 
# "leptyrites", 
# "dacites", 
# "granites", 
# "conglomérats", 
# "gabbros", 
# "schistes", 
# "gneiss", 
# "Dolomies", 
# "gypses", 
# "marnes", 
# "rhyolites", 
# "Amphibolites"
# ]


# "aucun comportement",
# "festons",
# "transport de branche",
# "accouplement",
# "autre (voir remarques)",
# "2 jeunes seuls",
# "1 jeune seul",
# "combat(s)",
# "Cri(s)",
# "transport de proie",
# "vol en tandem",
# "rassemblement d'aigles",
# "aigle(s) perché(s)",
# "1 jeune avec les adultes",
# "2 jeunes avec les adultes",