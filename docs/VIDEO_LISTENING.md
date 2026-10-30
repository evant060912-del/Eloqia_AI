# Écoute avec de vraies vidéos

Les leçons d'écoute peuvent utiliser une vraie vidéo à la place des voix de
synthèse. Deux sources sont prévues, toutes deux légales et gratuites.

## 1. VOA Learning English (domaine public)

Les vidéos et transcriptions de VOA Learning English sont des œuvres du
gouvernement américain : elles sont dans le **domaine public**. L'appli peut
les lire directement et afficher leur transcription.

1. Ouvrir la leçon sur https://learningenglish.voanews.com
2. Sous la vidéo, dans **Direct link**, copier le lien **360p** (fichier `.mp4`).
3. Copier la transcription de la page (dialogue ou texte).
4. Ajouter une leçon dans `lib/features/lessons/content/video_listening_content.dart` :

```dart
video: const VideoClip.mp4(
  url: 'https://voa-video-ns.akamaized.net/....mp4',
  credit: 'VOA Learning English, <titre>. Public domain (U.S. government work).',
  sourcePage: 'https://learningenglish.voanews.com/a/....html',
),
audio: const <AudioLine>[ AudioLine('Anna', '...'), ... ], // la transcription
```

## 2. YouTube (lecteur officiel intégré)

On **n'enregistre pas et ne télécharge pas** les vidéos YouTube (interdit par
les conditions de YouTube et le droit d'auteur). On les intègre avec le lecteur
officiel : la vidéo reste sur YouTube, avec ses sous-titres, et l'appli ajoute
seulement ses propres questions.

1. Choisir une vidéo dont l'intégration est autorisée (bouton **Partager →
   Intégrer** présent sur YouTube).
2. Noter son identifiant : dans `https://www.youtube.com/watch?v=AbCdEf12345`,
   c'est `AbCdEf12345`. Noter aussi le début et la fin de l'extrait (en secondes).
3. Ajouter :

```dart
video: const VideoClip.youtube(
  id: 'AbCdEf12345',
  startSeconds: 30,
  endSeconds: 150,
  credit: 'Nom de la chaîne, titre de la vidéo (YouTube).',
  sourcePage: 'https://www.youtube.com/watch?v=AbCdEf12345',
),
// pas de transcription copiée dans l'appli : audio reste vide
```

Pour les questions : coller la transcription YouTube (« Afficher la
transcription ») dans le chat avec Claude, qui rédige les questions. La
transcription sert seulement à écrire les questions, elle n'est pas copiée dans
l'appli.

## Règles

- Questions toujours originales ; chaque question de compréhension a une
  indication (`evidence`) qui dit où écouter.
- Indiquer la source dans `credit` (affiché sous la vidéo).
- Préférer des extraits de 1 à 4 minutes.
