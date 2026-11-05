#!/usr/bin/env python3
"""Synchronised subtitles (WebVTT) for a public-domain video, made locally.

Only for media the app may legally host or show with its text: public-domain
works (VOA Learning English, NASA, NIH...) or your own recordings. YouTube
videos already show their own synchronised captions in the official player:
never download them.

Free, runs on your computer (no account, no API):
    pip install faster-whisper
    python tools/make_subtitles.py --url https://.../video.mp4 \
        --out assets/subtitles/video-voa-welcome.vtt

Then:
  1. Check the text against the official transcript and fix names.
  2. Add `assets/subtitles/` under `flutter: assets:` in pubspec.yaml (once).
  3. In the lesson: VideoClip.mp4(..., subtitlesAsset:
     'assets/subtitles/video-voa-welcome.vtt', segments: [...]).
The script also prints the timings of each sentence, to choose the passages
learners can replay (ClipSegment('Label', start, end)).
"""

import argparse
import os
import tempfile
import urllib.request


def stamp(seconds: float) -> str:
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", required=True, help="MP4/MP3 URL or local file")
    parser.add_argument("--out", required=True, help="output .vtt path")
    parser.add_argument("--model", default="small", help="tiny/base/small/medium")
    args = parser.parse_args()

    from faster_whisper import WhisperModel  # pip install faster-whisper

    source = args.url
    if source.startswith("http"):
        tmp = tempfile.NamedTemporaryFile(suffix=os.path.splitext(source)[1] or ".mp4", delete=False)
        print(f"Downloading {source} …")
        urllib.request.urlretrieve(source, tmp.name)
        source = tmp.name

    model = WhisperModel(args.model, device="auto", compute_type="int8")
    segments, _ = model.transcribe(source, language="en", vad_filter=True)

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as vtt:
        vtt.write("WEBVTT\n\n")
        for i, seg in enumerate(segments, 1):
            text = seg.text.strip()
            vtt.write(f"{i}\n{stamp(seg.start)} --> {stamp(seg.end)}\n{text}\n\n")
            print(f"[{int(seg.start):>4}s – {int(seg.end) + 1:>4}s] {text}")
    print(f"\nWritten: {args.out}")


if __name__ == "__main__":
    main()
