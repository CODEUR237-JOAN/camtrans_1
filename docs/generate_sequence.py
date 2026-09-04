import urllib.request
import json
import os

puml_code = """
@startuml
skinparam backgroundColor white
skinparam defaultFontName sans-serif
skinparam sequence {
    ParticipantBackgroundColor #AAEEFF
    ParticipantBorderColor #0055AA
    LifeLineBorderColor #0055AA
    ActorBackgroundColor white
    ActorBorderColor #0055AA
}

actor "Transporteur" as T
participant "Système" as S
database "Base de Données" as B

== Réception de la proposition ==
S -> T : 1. Affiche notification (alerte sonore)
T -> S : 2. Consulte détails (Trajet, Prix, etc.)
note right of T: 3. Temps limité (ex: 30s)

alt 4. Accepter la course
    T -> S : 4. Clique sur « Accepter »
    S -> B : 5. Vérifie si course toujours disponible
    
    alt 5.a Course expirée/annulée
        B --> S : [Non disponible]
        S -> T : Affiche erreur "Course non disponible"
        S -> T : Rétablit l'écran d'accueil
    else Course disponible
        B --> S : [Disponible]
        S -> B : 6. Lie le transporteur & MAJ statut "Acceptée"
        S -> B : 7. MAJ statut transporteur "Indisponible"
        S -> T : 8. Redirige vers écran GPS
    end

else 4.a Refus manuel
    T -> S : Clique sur « Refuser »
    S -> S : Masque proposition\\nRelance algorithme dispatch

else 4.b Expiration du délai (Timeout)
    ... 30 secondes s'écoulent ...
    S -> S : Expire la proposition\\nRelance algorithme dispatch
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

output_path = os.path.join('c:\\tmp\\update_camtrans\\docs', 'diagramme_sequence_consulter.png')

with urllib.request.urlopen(req) as response:
    with open(output_path, 'wb') as f:
        f.write(response.read())

print(f'SUCCESS: {output_path}')
