import urllib.request
import json
import os

puml_code = """
@startuml
skinparam backgroundColor white
skinparam defaultFontName sans-serif
skinparam node {
    BackgroundColor #AAEEFF
    BorderColor #0055AA
}
skinparam database {
    BackgroundColor #AAEEFF
    BorderColor #0055AA
}
skinparam actor {
    BackgroundColor white
    BorderColor #0055AA
}

actor "Transporteur" as T
node "Système" as S
database "Base de Données\\nCloud" as B

S -left-> T : 1: afficherNotification()\\n5.a.1: [Si Annulée] afficherErreur()\\n8: [Si succès] redirigerGPS()

T -right-> S : 2: consulterDetails()\\n4: [Choix=Accepter] cliquerAccepter()\\n4a: [Choix=Refuser] cliquerRefuser()

S -up-> S : 4b: [Timeout=30s] expirationDélai()

S -right-> B : 5: [Si Accepter] verifierDispo()\\n6: [Si dispo] majStatut("Acceptée")\\n7: [Si dispo] setTransp("Indisponible")

B -left-> S : 5.1: [Est Disponible]\\n5.a: [Est Annulée]

@enduml
"""

url = 'https://kroki.io/plantuml/png'
data = json.dumps({
    "diagram_source": puml_code,
    "diagram_type": "plantuml",
    "output_format": "png"
}).encode('utf-8')

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})

output_path = os.path.join('c:\\tmp\\update_camtrans\\docs', 'diagramme_communication_complet.png')

with urllib.request.urlopen(req) as response:
    with open(output_path, 'wb') as f:
        f.write(response.read())

print(f'SUCCESS: {output_path}')
