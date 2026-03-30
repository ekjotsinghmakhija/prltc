/**
 * PRLTC Rewrite Plugin for OpenClaw
 *
 * Transparently rewrites exec tool commands to PRLTC equivalents
 * before execution, achieving 60-90% LLM token savings.
 *
 * All rewrite logic lives in `prltc rewrite` (src/discover/registry.rs).
 * This plugin is a thin delegate — to add or change rules, edit the
 * Rust registry, not this file.
 */

import { execSync } from "node:child_process";

let prltcAvailable: boolean | null = null;

function checkRtk(): boolean {
  if (prltcAvailable !== null) return prltcAvailable;
  try {
    execSync("which prltc", { stdio: "ignore" });
    prltcAvailable = true;
  } catch {
    prltcAvailable = false;
  }
  return prltcAvailable;
}

function tryRewrite(command: string): string | null {
  try {
    const result = execSync(`prltc rewrite ${JSON.stringify(command)}`, {
      encoding: "utf-8",
      timeout: 2000,
    }).trim();
    return result && result !== command ? result : null;
  } catch {
    return null;
  }
}

export default function register(api: any) {
  const pluginConfig = api.config ?? {};
  const enabled = pluginConfig.enabled !== false;
  const verbose = pluginConfig.verbose === true;

  if (!enabled) return;

  if (!checkRtk()) {
    console.warn("[prltc] prltc binary not found in PATH — plugin disabled");
    return;
  }

  api.on(
    "before_tool_call",
    (event: { toolName: string; params: Record<string, unknown> }) => {
      if (event.toolName !== "exec") return;

      const command = event.params?.command;
      if (typeof command !== "string") return;

      const rewritten = tryRewrite(command);
      if (!rewritten) return;

      if (verbose) {
        console.log(`[prltc] ${command} -> ${rewritten}`);
      }

      return { params: { ...event.params, command: rewritten } };
    },
    { priority: 10 }
  );

  if (verbose) {
    console.log("[prltc] OpenClaw plugin registered");
  }
}
