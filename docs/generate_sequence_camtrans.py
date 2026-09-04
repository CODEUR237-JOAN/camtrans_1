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
participant "Système\\n(CamTrans)" as S
participant "SGBD\\n(Firebase)" as B

ref over C, B : S'authentifier et activer GPS
|||

C -> S : Saisit les informations (trajet, marchandise)
activate S
S -> S : Interroge l'IA (Estimation prix, volume, véhicule)
S --> C : Affiche l'estimation détaillée

alt [Si estimation acceptée]
    C -> S : Valide la commande
    
    S -> B : Enregistre les informations de la commande
    activate B
    B -> B : Sauvegarde et traitement Cloud
    B --> S : Retourne le succès de l'enregistrement
    deactivate B
    
    S -> S : Lance l'algorithme de dispatch (Transporteurs)
    
    alt [Connexion réseau disponible]
        S --> C : Affiche confirmation de création
        S --> C : Redirige vers l'écran de suivi Radar
    else [Connexion interrompue]
        S -> S : Sauvegarde temporaire en cache local
        S --> C : Affiche un message d'erreur
    end
    
else [Si estimation refusée]
    C -> S : Annule ou modifie la saisie
    S --> C : Rétablit l'écran d'accueil
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

output_path = os.path.join('c:\\tmp\\update_camtrans\\docs', 'diagramme_sequence_creer_camtrans.png')

with urllib.request.urlopen(req) as response:
    with open(output_path, 'wb') as f:
        f.write(response.read())

print(f'SUCCESS: {output_path}')
