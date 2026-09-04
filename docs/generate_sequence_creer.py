import urllib.request
import json
import os

puml_code = """
@startuml
skinparam backgroundColor white
skinparam defaultFontName sans-serif
skinparam sequence {
    ParticipantBackgroundColor #AAFFFF
    ParticipantBorderColor #0055AA
    LifeLineBorderColor #0055AA
    ActorBackgroundColor white
    ActorBorderColor #0055AA
    GroupBorderColor #0055AA
    GroupHeaderFontColor black
    GroupBackgroundColor white
    ReferenceBackgroundColor #CCCCCC
    ReferenceHeaderBackgroundColor #CCCCCC
}

hide footbox

actor "Client" as C
participant "Système" as S
participant "SGBD" as B

ref over C, B : S'authentifier()
|||

C -> S : Sélectionne "Nouvelle commande"
S -> C : Affiche le formulaire de création
C -> S : Remplir le formulaire
C -> S : Valide le formulaire
activate S
S -> S : Analyse le formulaire

alt SI FORMAT OK
    S -> B : Envoi des infos du formulaire
    activate B
    B -> B : Traitement des informations
    B -> S : Renvoi des résultats
    deactivate B
    S -> S : Analyse des résultats
    
    alt Connexion disponible
        S -> C : Affiche confirmation de création
    else Connexion interrompue
        S -> S : Sauvegarde temporaire en brouillon
        S --> C : affiche message d'erreur
    end
else SI FORMAT INCORRECT
    S --> C : Renvoi formulaire
end
deactivate S

@enduml
"""

url = 'https://kroki.io/plantuml/png'
data = json.dumps({
    "diagram_source": puml_code,
    "diagram_type": "plantuml",
    "output_format": "png"
}).encode('utf-8')

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})

output_path = os.path.join('c:\\tmp\\update_camtrans\\docs', 'diagramme_sequence_creer_commande.png')

with urllib.request.urlopen(req) as response:
    with open(output_path, 'wb') as f:
        f.write(response.read())

print(f'SUCCESS: {output_path}')
