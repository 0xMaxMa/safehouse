#!/usr/bin/env node
/**
 * stitch.mjs — Google Stitch SDK helper
 * Usage:
 *   STITCH_API_KEY=<key> node stitch.mjs create-project "My App"
 *   STITCH_API_KEY=<key> node stitch.mjs generate <projectId> "prompt text" [screen-name]
 *   STITCH_API_KEY=<key> node stitch.mjs edit <projectId> <screenId> "edit prompt"
 *   STITCH_API_KEY=<key> node stitch.mjs get-screen <projectId> <screenId>
 *   STITCH_API_KEY=<key> node stitch.mjs list-projects
 *   STITCH_API_KEY=<key> node stitch.mjs list-screens <projectId>
 *   STITCH_API_KEY=<key> node stitch.mjs download-html <htmlUrl> [output.html]
 *
 * Outputs JSON results to stdout. Errors to stderr.
 */

import { StitchToolClient } from "@google/stitch-sdk";
import { writeFileSync } from "fs";
import https from "https";

const client = new StitchToolClient({ apiKey: process.env.STITCH_API_KEY });

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Find outputComponent that has design.screens and return screens[0] */
function extractScreenData(raw) {
  const comp = raw.outputComponents?.find(c => c.design?.screens?.length > 0);
  if (!comp) throw new Error("No design.screens in response. Keys: " + raw.outputComponents?.map(c => Object.keys(c)).join(" | "));
  return comp.design.screens[0];
}

function extractScreenId(screenData) {
  return screenData.id || screenData.name?.split("/screens/")?.[1];
}

async function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    https.get(url, res => {
      const chunks = [];
      res.on("data", c => chunks.push(c));
      res.on("end", () => resolve(Buffer.concat(chunks)));
      res.on("error", reject);
    }).on("error", reject);
  });
}

// ─── Commands ─────────────────────────────────────────────────────────────────

async function createProject(title) {
  const raw = await client.callTool("create_project", { title });
  const projectId = raw.name?.split("/")?.[1];
  console.log(JSON.stringify({ projectId, title, url: `https://stitch.withgoogle.com/project/${projectId}` }, null, 2));
}

async function listProjects() {
  const raw = await client.callTool("list_projects", {});
  const projects = (raw.projects || []).map(p => ({
    projectId: p.name?.split("/")?.[1],
    title: p.title,
    url: `https://stitch.withgoogle.com/project/${p.name?.split("/")?.[1]}`
  }));
  console.log(JSON.stringify(projects, null, 2));
}

async function listScreens(projectId) {
  const raw = await client.callTool("list_screens", { projectId });
  const screens = (raw.screens || []).map(s => ({
    screenId: s.id || s.name?.split("/screens/")?.[1],
    name: s.displayName || s.name
  }));
  console.log(JSON.stringify(screens, null, 2));
}

async function generateScreen(projectId, prompt, screenName) {
  const raw = await client.callTool("generate_screen_from_text", { projectId, prompt });
  const screenData = extractScreenData(raw);
  const screenId = extractScreenId(screenData);

  // fetch full detail for download URLs
  const detail = await client.callTool("get_screen", {
    projectId,
    screenId,
    name: `projects/${projectId}/screens/${screenId}`
  });

  const result = {
    screenId,
    name: screenName || "generated",
    projectId,
    htmlUrl: detail.htmlCode?.downloadUrl || screenData.htmlCode?.downloadUrl || null,
    imageUrl: detail.screenshot?.downloadUrl || screenData.screenshot?.downloadUrl || null,
    viewUrl: `https://stitch.withgoogle.com/project/${projectId}`
  };
  console.log(JSON.stringify(result, null, 2));
}

async function editScreen(projectId, screenId, prompt) {
  const raw = await client.callTool("edit_screens", {
    projectId,
    selectedScreenIds: [screenId],
    prompt
  });
  const screenData = extractScreenData(raw);
  const newScreenId = extractScreenId(screenData);

  const detail = await client.callTool("get_screen", {
    projectId,
    screenId: newScreenId,
    name: `projects/${projectId}/screens/${newScreenId}`
  });

  const result = {
    screenId: newScreenId,
    projectId,
    htmlUrl: detail.htmlCode?.downloadUrl || null,
    imageUrl: detail.screenshot?.downloadUrl || null,
  };
  console.log(JSON.stringify(result, null, 2));
}

async function getScreen(projectId, screenId) {
  const raw = await client.callTool("get_screen", {
    projectId,
    screenId,
    name: `projects/${projectId}/screens/${screenId}`
  });
  console.log(JSON.stringify({
    screenId,
    projectId,
    htmlUrl: raw.htmlCode?.downloadUrl || null,
    imageUrl: raw.screenshot?.downloadUrl || null,
  }, null, 2));
}

async function generateVariants(projectId, screenId) {
  const raw = await client.callTool("generate_variants", {
    projectId,
    selectedScreenIds: [screenId]
  });
  const screenData = extractScreenData(raw);
  const newScreenId = extractScreenId(screenData);

  const detail = await client.callTool("get_screen", {
    projectId,
    screenId: newScreenId,
    name: `projects/${projectId}/screens/${newScreenId}`
  });

  console.log(JSON.stringify({
    screenId: newScreenId,
    projectId,
    htmlUrl: detail.htmlCode?.downloadUrl || null,
    imageUrl: detail.screenshot?.downloadUrl || null,
  }, null, 2));
}

async function downloadHtml(url, outputPath) {
  const buf = await fetchUrl(url);
  const path = outputPath || "screen.html";
  writeFileSync(path, buf);
  console.log(JSON.stringify({ saved: path, bytes: buf.length }, null, 2));
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const [,, cmd, ...args] = process.argv;

const commands = {
  "create-project": () => createProject(args[0]),
  "list-projects":  () => listProjects(),
  "list-screens":   () => listScreens(args[0]),
  "generate":       () => generateScreen(args[0], args[1], args[2]),
  "edit":           () => editScreen(args[0], args[1], args[2]),
  "get-screen":     () => getScreen(args[0], args[1]),
  "generate-variants": () => generateVariants(args[0], args[1]),
  "download-html":  () => downloadHtml(args[0], args[1]),
};

if (!cmd || !commands[cmd]) {
  console.error("Usage: node stitch.mjs <command> [args...]");
  console.error("Commands:", Object.keys(commands).join(", "));
  process.exit(1);
}

commands[cmd]()
  .catch(e => { console.error("Error:", e.message); process.exit(1); })
  .finally(async () => { await client.close(); });
