import re
import sys

file_path = r'lib\fonctionnalites\client\creer_demande.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f"Error reading file: {e}")
    sys.exit(1)

# 1. Hide CTA
content = re.sub(
    r'child: _buildBottomCTA\(etat, notifier\),',
    r'child: _etapeCourante == 4 ? const SizedBox.shrink() : _buildBottomCTA(etat, notifier),',
    content
)

# 2. Replace _buildEtape5Matching
radar_search = """  Widget _buildEtape5Matching(
    BuildContext context,
    EtatDemandeExpedition etat,
  ) {
    return AnimatedRadarSearch(
      onSearchComplete: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const ResumeExpeditionBottomSheet(),
          ),
        );
      },
    );
  }"""

content = re.sub(
    r'Widget _buildEtape5Matching\(.*?\)\s*\{.*?return Column\(.*?\);\s*\}',
    radar_search,
    content,
    flags=re.DOTALL
)

# 3. Add AnimatedRadarSearch class at the end
radar_class = """
import 'dart:async';

class AnimatedRadarSearch extends StatefulWidget {
  final VoidCallback onSearchComplete;

  const AnimatedRadarSearch({super.key, required this.onSearchComplete});

  @override
  State<AnimatedRadarSearch> createState() => _AnimatedRadarSearchState();
}

class _AnimatedRadarSearchState extends State<AnimatedRadarSearch> {
  int _step = 0;
  Timer? _timer;

  final List<String> _messages = [
    "Recherche de transporteurs à proximité...",
    "Analyse du trafic en temps réel...",
    "Contact des chauffeurs les mieux notés...",
    "Négociation du meilleur tarif...",
    "Chauffeur trouvé ! Finalisation...",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_step < _messages.length - 1) {
        setState(() {
          _step++;
        });
      } else {
        timer.cancel();
        widget.onSearchComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _step == _messages.length - 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Stack(
          alignment: Alignment.center,
          children: [
            if (!isFinished)
              ...List.generate(3, (index) {
                return Container(
                  width: 100.0 + (index * 80),
                  height: 100.0 + (index * 80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CouleursApp.primaire.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      duration: const Duration(seconds: 2),
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.5, 1.5),
                    )
                    .fade(
                      duration: const Duration(seconds: 2),
                      begin: 0.8,
                      end: 0.0,
                    );
              }),

            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isFinished ? CouleursApp.succes : CouleursApp.primaire,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isFinished ? CouleursApp.succes : CouleursApp.primaire)
                        .withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                isFinished ? Icons.check : Icons.search, 
                color: Colors.white, 
                size: 30
              ),
            )
                .animate(
                  target: isFinished ? 0 : 1,
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  duration: const Duration(milliseconds: 800),
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                ),
          ],
        ),
        const SizedBox(height: 60),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _messages[_step],
            key: ValueKey<int>(_step),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isFinished ? CouleursApp.succes : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (isFinished)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton.icon(
              onPressed: widget.onSearchComplete,
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              label: Text(
                "Voir la proposition",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.primaire,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ).animate().fadeIn().scale(),
          )
        else
          Text(
            "Un instant, nous trouvons le meilleur chauffeur pour votre trajet.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
"""

content += radar_class

try:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Patch applied successfully')
except Exception as e:
    print(f"Error writing file: {e}")
