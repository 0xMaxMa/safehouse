# Google Stitch SDK — Notes from Real Usage

## Known SDK Bug

`stitch.project(id).generate(prompt)` uses `outputComponents[0].design.screens[0]` but the actual
design response is at the **first component that has `design.screens`** (not always index 0).
The first component is often `designSystem`, not `design`.

**Always use `callTool` directly and find the right component:**

```js
const raw = await client.callTool("generate_screen_from_text", { projectId, prompt });
const comp = raw.outputComponents?.find(c => c.design?.screens?.length > 0);
const screenData = comp.design.screens[0];
```

## Response Structures

### create_project
```json
{ "name": "projects/<id>", "title": "...", "visibility": "PRIVATE" }
```
Extract ID: `raw.name.split("/")[1]`

### generate_screen_from_text
```json
{
  "outputComponents": [
    { "designSystem": { ... } },   ← index 0 (design system only)
    { "design": { "screens": [...], "theme": {...} } },  ← index 1 (actual screen)
    { "text": "..." },
    { "suggestion": "..." },
    ...
  ],
  "projectId": "...",
  "sessionId": "..."
}
```
Screen data fields: `id`, `name` (`projects/<pid>/screens/<sid>`), `htmlCode.downloadUrl`, `screenshot.downloadUrl`

### get_screen
```json
{
  "htmlCode": { "downloadUrl": "https://contribution.usercontent.google.com/..." },
  "screenshot": { "downloadUrl": "https://lh3.googleusercontent.com/..." }
}
```

### edit_screens
Same structure as `generate_screen_from_text`. Use same `find` approach.

### generate_variants
Same response structure as `generate_screen_from_text`. Use same `find` approach.
Args: `{ projectId, selectedScreenIds: [screenId] }`

### list_projects
```json
{ "projects": [{ "name": "projects/<id>", "title": "..." }] }
```

### list_screens
```json
{ "screens": [{ "id": "<screenId>", "name": "projects/.../screens/...", "displayName": "..." }] }
```

## Available Tools
```
create_project, get_project, list_projects
list_screens, get_screen
generate_screen_from_text, edit_screens, generate_variants
```
❌ No `delete_project` — must delete via UI at https://stitch.withgoogle.com

## Project Visibility
Projects created via API are PRIVATE — only the API key owner can view them at:
`https://stitch.withgoogle.com/project/<id>`

## HTML Output
Downloaded HTML is self-contained (inline CSS/JS). Safe to open directly in browser or copy into Next.js.

## Screen Image
Screenshot URL from `lh3.googleusercontent.com` — use `curl` or `https.get()` to download.
