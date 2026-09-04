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

actor "Transporteur" as T
participant "Système\\n(CamTrans)" as S
participant "SGBD\\n(Firebase)" as B

ref over T, B : S'authentifier et passer "En Ligne"
|||

S -> T : Affiche notification de nouvelle course (Push)
T -> S : Ouvre la Popup et consulte les détails (Prix, Trajet)
note right of T: Dispose de 30 secondes pour agir

alt [Si Transporteur ACCEPTE]
    T -> S : Clique sur « Accepter la course »
    activate S
    S -> B : Vérifie la disponibilité de la course
    activate B
    
    alt [Course toujours disponible]
        B --> S : Retourne statut "Disponible"
        S -> B : Assigne transporteur et MAJ statut "Acceptée"
        S -> B : MAJ statut transporteur "Indisponible"
        deactivate B
        S --> T : Redirige vers l'écran de suivi GPS
        
    else [Course expirée / annulée]
        B --> S : Retourne erreur "Non disponible"
        S --> T : Affiche message d'erreur
        S --> T : Rétablit l'écran d'accueil
    end
    deactivate S
    
else [Si Transporteur REFUSE]
    T -> S : Clique sur « Refuser »
    S -> S : Masque la proposition
    S -> S : Relance l'algorithme de dispatch
    
else [Si Expiration du délai - Timeout]
    ... Plus de 30 secondes s'écoulent ...
    S -> S : Expire la proposition
    S -> S : Relance l'algorithme de dispatch
end

@enduml
"""

url = 'https://kroki.io/plantuml/png'
data = json.dumps({
    "diagram_source": puml_code,
    "diagram_type": "plantuml",
    "output_format": "png"
}).encode('utf-8')

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})

output_path = os.path.join('c:\\tmp\\update_camtrans\\docs', 'diagramme_sequence_consulter_camtrans.png')

with urllib.request.urlopen(req) as response:
    with open(output_path, 'wb') as f:
        f.write(response.read())

print(f'SUCCESS: {output_path}')
