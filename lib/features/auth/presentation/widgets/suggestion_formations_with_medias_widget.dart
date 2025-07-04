import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';

class SuggestionFormationsWithMediasWidget extends StatelessWidget {
  final List<FormationWithMedias> formations;
  final void Function(FormationWithMedias)? onTapFormation;

  const SuggestionFormationsWithMediasWidget({
    super.key,
    required this.formations,
    this.onTapFormation,
  });

  @override
  Widget build(BuildContext context) {
    if (formations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Aucune formation trouvée.'),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        screenWidth < 350
            ? 180.0
            : (screenWidth < 450 ? 200.0 : screenWidth / 2.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Suggestions de formations',
            style: TextStyle(
              fontSize: screenWidth < 350 ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        SizedBox(
          height: cardWidth * 0.7,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: formations.length,
            itemBuilder: (context, index) {
              final f = formations[index];
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap:
                        onTapFormation != null
                            ? () => onTapFormation!(f)
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f.titre,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.video_library,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${f.medias.length} média(s)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              onPressed:
                                  onTapFormation != null
                                      ? () => onTapFormation!(f)
                                      : null,
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Voir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
