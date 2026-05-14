# FileMarkdown

FileMarkdown scans a folder tree on your machine, collects structured evidence from files (sizes, dates, samples of text, optional image descriptions), and writes **Markdown reports** you can read in any editor or viewer. Narrative sections can be produced with a **local LLM** via [Ollama](https://ollama.com/), or you can run fully **offline, deterministic** summaries without AI.

All processing is local by default: paths and file contents stay on your computer unless you choose to share the generated Markdown yourself.

## What you get

- **One Markdown file per immediate child folder** under the root you choose (each report focuses on that subtree, not a flat file list).
- **One root-level Markdown report** that ties the whole scan together (overview, child-folder highlights, optional cleanup hints).
- **Optional JSON inventory** listing scan metadata, output paths, and child report information.

Reports are written to a single **output directory** (default name `Folder-Markups`, or a path you pass in), which the scanner normally excludes from the scan when that directory lives inside the root.

## Requirements

- **Python 3** (3.10 or newer recommended)
- Dependencies listed in `Folder Searcher/requirements.txt` (`requests`, `PyMuPDF`, `python-docx`, `openpyxl`, `Pillow`)
- **Ollama** (optional but recommended) if you want AI-written narratives and optional vision analysis. Pull a model first, for example: `ollama pull qwen2.5:7b`

## Installation

```text
cd "Folder Searcher"
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

On macOS or Linux, activate the venv with `source .venv/bin/activate` instead.

## How to run

### Windows launcher (easiest)

Double-click or run `Folder Searcher/run_folder_md_ai_dashboard.bat` from a command prompt. It will:

1. Ask you to **pick the folder to scan** in a standard dialog.
2. Let you use the **default output folder** (`<scanned folder>\Folder-Markups`) or **browse** for another.
3. Walk through short **Y/N choices** (JSON manifest, image analysis, hidden files, AI on or off, model defaults).

The batch file expects `app.py` in the same `Folder Searcher` directory. It prefers the `py -3` launcher when available, then falls back to `python`.

### Command line

```text
cd "Folder Searcher"
python app.py "C:\path\to\folder" --output-dir "C:\path\to\Folder-Markups"
```

Common flags:

| Flag | Meaning |
|------|---------|
| `--disable-ai` | No Ollama calls; deterministic text only. |
| `--analyze-images` | Send selected images to the vision model (when AI is enabled). |
| `--think` | Request thinking-style traces from models that support it. |
| `--model`, `--ollama-url` | Model name and Ollama base URL (default model in code: `qwen2.5:7b`, default URL: `http://localhost:11434`). |
| `--inventory-json PATH` | Write a JSON manifest to `PATH` after the run. |
| `--include-hidden` | Include hidden files and directories. |

Run `python app.py --help` for the full list (sampling limits, timeouts, context window, and more).

## How it works

The tool runs in clear stages:

1. **Recursive scan**  
   Walks the tree from your chosen root, classifies files (text, images, archives, documents, and so on), and skips common noise such as `node_modules`, virtual environments, build outputs, and similar generated trees. Optional inclusion of hidden items is controlled by `--include-hidden`.

2. **Evidence building per top-level folder**  
   For each immediate child of the root (plus the root's own loose files), the tool picks a **sample of eligible files**: representative names, largest items, recent items, and **excerpts** from text-like and office formats within size limits. PDFs go through PyMuPDF; `.docx` through `python-docx`; `.xlsx` through `openpyxl`; images can be described by the model when `--analyze-images` is on. Caps such as `--max-doc-evidence-per-folder` keep very large folders practical.

3. **Optional AI layer**  
   If AI is enabled and Ollama is reachable, the tool builds prompts and calls the local model for **folder-level narratives** (summary, purpose, tags) and for the **root report**. If the client fails to initialize or a call errors, the code falls back to deterministic wording so you still get usable Markdown.

4. **Markdown rendering**  
   Each folder and the root get a `.md` file written under `--output-dir`, using sensible, unique filenames when names would collide.

5. **Optional manifest**  
   If you set `--inventory-json`, a JSON file is written with overview stats, output directory, generated file list, child report metadata, and cleanup-oriented hints gathered during the scan.

## Tips

- **Large trees**: Tighten limits with flags like `--max-doc-evidence-per-folder` and `--max-image-evidence-per-folder`, or disable AI with `--disable-ai` for a faster pass.
- **Models**: The batch launcher defaults to `qwen2.5:7b` with `--think`. Any Ollama model you have pulled will work as long as it fits your hardware; vision features need a vision-capable model when using `--analyze-images`.
- **Output location**: Putting `--output-dir` inside the scanned root is supported; the scanner excludes that output directory from indexing so you do not recurse into your own reports.

## Repository layout

```text
FileMarkdown/
  README.md                 (this file)
  Folder Searcher/
    app.py                  main CLI and pipeline
    requirements.txt        Python dependencies
    run_folder_md_ai_dashboard.bat   Windows GUI-oriented launcher
```
