# monOS project documents

Course deliverables for Sistemas Operativos (Universidad Mariano Gálvez de
Guatemala, Campus Huehuetenango, 2026).

| File | Content |
|---|---|
| `monOS-entregable.pdf` | Submitted deliverable: title page, links and technical report |
| `monOS-propuesta-de-valor.pdf` | Value proposition and tool catalog used in the presentation |

Links: website https://monos-os.vercel.app · launch video
https://monos-os.vercel.app/lanzamiento.html · ISO on
[Google Drive](https://drive.google.com/drive/folders/1nUSszLPcizV07Xjbe--AbGI46P8qUbDi?usp=sharing).

## Sources

The PDFs are HTML pages printed with headless Chromium:

```bash
chromium --headless=new --no-pdf-header-footer --print-to-pdf=out.pdf docs/src/entregable/entregable.html
```

`src/video/` builds the launch video (`website/media/lanzamiento.mp4`):
`cards/gen.py` renders the title cards with Chromium and `build.sh` cuts and
joins the clips with ffmpeg. The input recordings were deleted after the
project; `build.sh` keeps their original paths for reference. Music: "Path Of
The Fireflies" by AERØHEAD, CC BY-NC 3.0.
