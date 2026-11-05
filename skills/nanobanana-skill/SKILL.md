---
name: nanobanana-skill
description: 'Generate or edit images via Google Gemini (nanobanana). This is the DEFAULT image skill — use whenever the user asks to generate, create, or edit an image and does NOT name another provider. Triggers: "nanobanana", "generate image", "create image", "edit image", "图片生成", "生成图片", "AI绘图", "图片编辑". Do NOT use for diagrams (架构图/流程图/时序图) — draw those with Mermaid or code instead.'
allowed-tools: Read, Write, Glob, Grep, Task, Bash(cat:*), Bash(ls:*), Bash(tree:*), Bash(python3:*)
---

# Nanobanana Image Generation Skill

Generate or edit images using Google Gemini API through the nanobanana tool.

## Requirements

1. **GEMINI_API_KEY**: Must be configured in `~/.nanobanana.env` or `export GEMINI_API_KEY=<your-api-key>`
2. **Python3 with dependent packages installed**: google-genai, Pillow, python-dotenv. They could be installed via `python3 -m pip install -r ${CLAUDE_SKILL_DIR}/requirements.txt` if not installed yet.
3. **Executable**: `${CLAUDE_SKILL_DIR}/nanobanana.py`

## Instructions

### For image generation

1. Ask the user for:
   - What they want to create (the prompt)
   - Desired aspect ratio/size (optional, defaults to 9:16 portrait)
   - Output filename (optional, auto-generates UUID if not specified)
   - Model preference (optional, defaults to gemini-nano-banana-2.1)
   - Resolution (optional, defaults to 1K)

2. Run the nanobanana script with appropriate parameters:

   ```bash
   python3 ${CLAUDE_SKILL_DIR}/nanobanana.py --prompt "description of image" --output "filename.png"
   ```

3. Show the user the saved image path when complete

### For image editing

1. Ask the user for:
   - Input image file(s) to edit
   - What changes they want (the prompt)
   - Output filename (optional)

2. Run with input images:

   ```bash
   python3 ${CLAUDE_SKILL_DIR}/nanobanana.py --prompt "editing instructions" --input image1.png image2.png --output "edited.png"
   ```

## Available Options

### Aspect Ratios (--size)

- `1024x1024` (1:1) - Square
- `832x1248` (2:3) - Portrait
- `1248x832` (3:2) - Landscape
- `864x1184` (3:4) - Portrait
- `1184x864` (4:3) - Landscape
- `896x1152` (4:5) - Portrait
- `1152x896` (5:4) - Landscape
- `768x1344` (9:16) - Portrait (default)
- `1344x768` (16:9) - Landscape
- `1536x672` (21:9) - Ultra-wide

### Models (--model)

- `gemini-nano-banana-2.1` (default) - Latest, fast, high quality
- `gemini-3.1-flash-image` - Previous fast model
- `gemini-3-pro-image` - Higher quality for detailed/complex scenes
- `gemini-2.5-flash-image` - Legacy model; no Google Search or thinking (auto-disabled), always outputs 1K regardless of `--resolution`

### Resolution (--resolution)

- `1K` (default)
- `2K`
- `4K`

### Other Options

- `--no-search` - Disable Google Search grounding (enabled by default)
- `--no-think` - Disable thinking/reasoning mode

## Examples

### Generate a simple image

```bash
python3 ${CLAUDE_SKILL_DIR}/nanobanana.py --prompt "A serene mountain landscape at sunset with a lake"
```

### Generate with specific size and output

```bash
python3 ${CLAUDE_SKILL_DIR}/nanobanana.py \
  --prompt "Modern minimalist logo for a tech startup" \
  --size 1024x1024 \
  --output "logo.png"
```

### Generate landscape image with high resolution

```bash
python3 ${CLAUDE_SKILL_DIR}/nanobanana.py \
  --prompt "Futuristic cityscape with flying cars" \
  --size 1344x768 \
  --resolution 2K \
  --output "cityscape.png"
```

### Edit existing images

```bash
python3 ${CLAUDE_SKILL_DIR}/nanobanana.py \
  --prompt "Add a rainbow in the sky" \
  --input photo.png \
  --output "photo-with-rainbow.png"
```

### Use pro model for higher quality

```bash
python3 ${CLAUDE_SKILL_DIR}/nanobanana.py \
  --prompt "Detailed portrait of a cat in watercolor style" \
  --model gemini-3-pro-image \
  --output "cat-portrait.png"
```

## Error Handling

If the script fails:

- Check that `GEMINI_API_KEY` is exported or set in ~/.nanobanana.env
- Verify input image files exist and are readable
- Ensure the output directory is writable
- If no image is generated, try making the prompt more specific about wanting an image

## Best Practices

1. Be descriptive in prompts - include style, mood, colors, composition
2. For logos/graphics, use square aspect ratio (1024x1024)
3. For social media posts, use 9:16 for stories or 1:1 for posts
4. For wallpapers, use 16:9 or 21:9
5. Start with 1K resolution for testing, upgrade to 2K/4K for final output
6. Use gemini-nano-banana-2.1 (default) for most tasks; try gemini-3-pro-image for complex, detail-heavy scenes
