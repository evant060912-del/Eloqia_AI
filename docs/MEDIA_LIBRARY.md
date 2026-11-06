# Médiathèque « Real English videos »

Bibliothèque de vraies vidéos et enregistrements, classés par **accent**,
**niveau A1–C2**, **catégorie** et **parcours** (général / académique).
Ouverture : Learn → Listening → carte « Real English videos ».

## Ce que contient chaque vidéo

| Élément | Où | Remarque |
|---|---|---|
| Lecteur intégré | `VideoClip.mp4` ou `VideoClip.youtube` | MP4 domaine public, ou lecteur YouTube officiel |
| Sous-titres synchronisés | `subtitlesAsset` (WebVTT) / YouTube | MP4 : `tools/make_subtitles.py` ; YouTube : sous-titres du lecteur |
| Transcription | `audio` (après la réponse) | **Uniquement** pour le domaine public ou nos propres enregistrements |
| Vocabulaire, expressions | `MediaInfo.vocabulary`, `MediaInfo.idioms` | Avec l'exemple tiré de la vidéo |
| Questions + explications | `Exercise.why`, `Exercise.evidence` | Écrites à partir de la transcription réelle |
| Réécouter un passage | `VideoClip.segments` (`ClipSegment`) | **Vrais minutages seulement** |

## Catégories

Technology · Science · Literature · Medicine · Finance & Business · History ·
Culture & Society · Environment · Arts & Entertainment · Everyday English.
Chaque vidéo est aussi **General** ou **Academic** (`ContentTrack`).

## Niveaux : ce qui change vraiment (`levelDescriptors`)

| Niveau | Débit (mots/min) | Discours | Vocabulaire / grammaire | Sujets |
|---|---|---|---|---|
| A1 | 80–110 | lent, très clair, scénarisé | 500 mots ; présent, *to be* | présentations, maison |
| A2 | 100–130 | lent à modéré | 1 000 mots ; passé simple, *going to* | situations courantes |
| B1 | 120–150 | naturel modéré, plusieurs voix | 2 000 mots ; present perfect, conditionnels | travail, opinions |
| B2 | 140–170 | vraie vitesse, interviews, reportages | 4 000 mots ; passif, past perfect | sciences et société |
| C1 | 160–190 | natif rapide, non scénarisé | vocabulaire académique, idiomes | conférences, débats |
| C2 | 170–220 | tout style : cours denses, Parlement, lecture littéraire | registres rares et littéraires | sujets abstraits |

Une vidéo est placée à son niveau d'après **la vidéo elle-même** (débit,
vocabulaire, grammaire, sujet), pas d'après la difficulté des questions.

## Sources autorisées (usage commercial possible)

| Accent | Source | Mode |
|---|---|---|
| 🇺🇸 | VOA Learning English, NASA, NIH, National Park Service | Domaine public : MP4 + transcription dans l'appli |
| 🇬🇧 | BBC Learning English, British Council, Royal Institution, BBC Ideas | Lecteur YouTube officiel (intégration autorisée par la chaîne) |
| 🇬🇧 | Parlement britannique | Open Parliament Licence |
| 🇦🇺 | ABC Australia, Australian Academy of Science, chaînes de vulgarisation | Lecteur YouTube officiel |
| Tous | LibriVox (livres lus, domaine public) | Audio + texte |

Attention VOA : seuls les contenus **écrits par VOA** sont dans le domaine
public. Les articles adaptés d'agences (mention « reported for Reuters/AP/AFP »)
sont exclus.

Enregistrements audio (reportages, lectures) : `VideoClip.mp4(url: '….mp3',
audioOnly: true)` affiche un panneau audio au lieu d'une image.

Exclus : licences « NC » (TED, MIT OCW…), téléchargement de vidéos YouTube,
copie de transcriptions protégées. **Diversité** : `MediaCoverage.creatorsFor`
compte les créateurs par accent ; varier chaînes, intervenants et formats.

## Ajouter une vidéo

1. Votre fils envoie : lien, minutes de l'extrait, transcription
   (YouTube : « Afficher la transcription »).
2. Claude écrit la leçon : niveau, catégorie, parcours, accent, créateur,
   vocabulaire, expressions, questions expliquées, passages à réécouter.
3. MP4 du domaine public : `python tools/make_subtitles.py --url … --out
   assets/subtitles/<id>.vtt` pour les sous-titres synchronisés.
4. Chaque dialogue de synthèse remplacé (même accent, même niveau) est retiré.

## État de la bibliothèque

`MediaCatalog.coverage` donne le nombre de vidéos par catégorie, niveau et
accent ; `missing()` liste les catégories sous l'objectif de 20 vidéos.
