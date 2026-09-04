import os

def create_svg():
    svg_width = 1100
    svg_height = 750
    
    # CSS styles
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {svg_width} {svg_height}" width="{svg_width}" height="{svg_height}">
    <defs>
        <style>
            .line {{ stroke: #0077FF; stroke-width: 1.5; fill: none; }}
            .box {{ fill: #AAEEFF; stroke: #0055AA; stroke-width: 1.5; }}
            .text {{ font-family: Arial, sans-serif; font-size: 13px; fill: black; }}
            .arrow {{ fill: #0077FF; stroke: none; }}
        </style>
    </defs>
    
    <!-- Title -->
    <rect x="850" y="20" width="220" height="40" fill="white" stroke="#0077FF" stroke-width="1"/>
    <text x="960" y="38" class="text" text-anchor="middle" font-size="11" font-style="italic">DIAGRAMME DE</text>
    <text x="960" y="52" class="text" text-anchor="middle" font-size="11" font-style="italic">COMMUNICATION CREER COMMANDE</text>
    '''

    # ACTOR (Client)
    ax, ay = 150, 150
    svg += f'''
    <circle cx="{ax}" cy="{ay-20}" r="10" class="line" fill="white"/>
    <line x1="{ax}" y1="{ay-10}" x2="{ax}" y2="{ay+20}" class="line"/>
    <line x1="{ax-15}" y1="{ay}" x2="{ax+15}" y2="{ay}" class="line"/>
    <line x1="{ax}" y1="{ay+20}" x2="{ax-10}" y2="{ay+40}" class="line"/>
    <line x1="{ax}" y1="{ay+20}" x2="{ax+10}" y2="{ay+40}" class="line"/>
    <text x="{ax}" y="{ay+60}" class="text" text-anchor="middle">Client</text>
    '''

    # SYSTEM BOX
    sx, sy = 550, 500
    sw, sh = 80, 40
    svg += f'''
    <rect x="{sx-sw/2}" y="{sy-sh/2}" width="{sw}" height="{sh}" class="box"/>
    <text x="{sx}" y="{sy+5}" class="text" text-anchor="middle">Système</text>
    '''

    # SGBD BOX
    bx, by = 950, 250
    svg += f'''
    <rect x="{bx-sw/2}" y="{by-sh/2}" width="{sw}" height="{sh}" class="box"/>
    <text x="{bx}" y="{by+5}" class="text" text-anchor="middle">SGBD</text>
    '''

    # MAIN LINES (Orthogonal)
    # Actor to System
    svg += f'<polyline points="{ax},{ay+65} {ax},{sy} {sx-sw/2},{sy}" class="line"/>'
    
    # System to SGBD
    svg += f'<polyline points="{sx+sw/2},{sy} {bx},{sy} {bx},{by+sh/2}" class="line"/>'

    # Self System Line 1 (Top left)
    svg += f'<polyline points="{sx},{sy-sh/2} {sx},{sy-sh/2-40} {sx-sw/2-20},{sy-sh/2-40} {sx-sw/2-20},{sy-sh/2+10} {sx-sw/2},{sy-sh/2+10}" class="line"/>'

    # Self System Line 2 (Top right)
    svg += f'<polyline points="{sx+20},{sy-sh/2} {sx+20},{sy-sh/2-60} {sx+sw/2+40},{sy-sh/2-60} {sx+sw/2+40},{sy-sh/2+20} {sx+sw/2},{sy-sh/2+20}" class="line"/>'

    # Helper function to draw message text + small arrow
    def draw_msg(x, y, text, dir):
        s = f'<text x="{x}" y="{y}" class="text" text-anchor="middle">{text}</text>\\n'
        # Draw small arrow below the text
        if dir == 'down':
            s += f'<polygon points="{x-2},{y+5} {x+2},{y+5} {x},{y+15}" class="arrow"/>'
            s += f'<line x1="{x}" y1="{y+5}" x2="{x}" y2="{y+15}" class="line" stroke-width="1"/>'
        elif dir == 'up':
            s += f'<polygon points="{x-2},{y+15} {x+2},{y+15} {x},{y+5}" class="arrow"/>'
            s += f'<line x1="{x}" y1="{y+5}" x2="{x}" y2="{y+15}" class="line" stroke-width="1"/>'
        elif dir == 'right':
            s += f'<polygon points="{x+10},{y+9} {x+10},{y+13} {x+20},{y+11}" class="arrow"/>'
            s += f'<line x1="{x-10}" y1="{y+11}" x2="{x+20}" y2="{y+11}" class="line" stroke-width="1"/>'
        elif dir == 'left':
            s += f'<polygon points="{x-10},{y+9} {x-10},{y+13} {x-20},{y+11}" class="arrow"/>'
            s += f'<line x1="{x-20}" y1="{y+11}" x2="{x+10}" y2="{y+11}" class="line" stroke-width="1"/>'
        return s

    # MESSAGES

    # Client <-> Systeme (Vertical Line)
    svg += draw_msg(ax + 100, 260, "1: saisirDemande(Trajet, Marchandise)", 'down')
    svg += draw_msg(ax - 90, 300, "3: afficherEstimation(Prix, Vehicule)", 'up')
    svg += draw_msg(ax + 90, 340, "4: [Si Accord] cliquerConfirmer()", 'down')
    svg += draw_msg(ax - 70, 380, "8: afficherSuiviRadar()", 'up')

    # Client <-> Systeme (Horizontal Line)
    svg += draw_msg(280, sy - 20, "4.a: [Si Refus] cliquerAnnuler()", 'right')
    svg += draw_msg(360, sy + 30, "4.b: [Refus] retourneAccueil()", 'left')

    # Systeme <-> SGBD (Horizontal Line)
    svg += draw_msg(700, sy - 20, "5: enregistrerCourse(Client, Vehicule)", 'right')

    # Systeme <-> SGBD (Vertical Line)
    svg += draw_msg(bx + 70, 320, "6: statutSuccès()", 'down')
    svg += draw_msg(bx - 100, 360, "5.a: [Erreur réseau] retourneErreur()", 'down')

    # Self System Lines
    # IA 
    svg += draw_msg(sx - 130, sy - 80, "2: interrogerIA(Description)", 'right')
    
    # Dispatch
    svg += draw_msg(sx + 150, sy - 110, "7: lancerRechercheTransporteurs()", 'right')


    svg += '</svg>'
    
    out_path = os.path.join('c:\\\\tmp\\\\update_camtrans\\\\docs', 'diagramme_poweramc_creer_commande.svg')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(svg)
    print(f"SUCCESS: {out_path}")

create_svg()
