"use client";

import { useState } from "react";
import type { Block } from "@/lib/types";

const BLOCK_LABELS: Record<Block["type"], string> = {
  heading: "Titre",
  text: "Texte",
  cta: "Appel à l'action",
  image: "Image",
};

function defaultBlock(type: Block["type"]): Block {
  switch (type) {
    case "heading":
      return { type: "heading", text: "", level: 2 };
    case "text":
      return { type: "text", body: "" };
    case "cta":
      return { type: "cta", label: "", href: "" };
    case "image":
      return { type: "image", src: "", alt: "" };
  }
}

function inputClass() {
  return "rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2 text-sm text-neutral-100";
}

export function BlockEditor({ name, initialBlocks }: { name: string; initialBlocks: Block[] }) {
  const [blocks, setBlocks] = useState<Block[]>(initialBlocks);

  function update(index: number, block: Block) {
    setBlocks(blocks.map((b, i) => (i === index ? block : b)));
  }

  function remove(index: number) {
    setBlocks(blocks.filter((_, i) => i !== index));
  }

  function move(index: number, direction: -1 | 1) {
    const target = index + direction;
    if (target < 0 || target >= blocks.length) return;
    const next = [...blocks];
    [next[index], next[target]] = [next[target], next[index]];
    setBlocks(next);
  }

  function add(type: Block["type"]) {
    setBlocks([...blocks, defaultBlock(type)]);
  }

  return (
    <div className="flex flex-col gap-4">
      <input type="hidden" name={name} value={JSON.stringify({ blocks })} />

      {blocks.map((block, index) => (
        <div key={index} className="flex flex-col gap-2 rounded-lg border border-neutral-800 p-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium uppercase text-neutral-500">{BLOCK_LABELS[block.type]}</span>
            <div className="flex gap-2 text-xs text-neutral-400">
              <button type="button" onClick={() => move(index, -1)} className="hover:text-white">
                ↑
              </button>
              <button type="button" onClick={() => move(index, 1)} className="hover:text-white">
                ↓
              </button>
              <button type="button" onClick={() => remove(index)} className="text-red-400 hover:text-red-300">
                Supprimer
              </button>
            </div>
          </div>

          {block.type === "heading" && (
            <div className="flex gap-2">
              <input
                value={block.text}
                onChange={(e) => update(index, { ...block, text: e.target.value })}
                placeholder="Texte du titre"
                className={`${inputClass()} flex-1`}
              />
              <select
                value={block.level ?? 2}
                onChange={(e) => update(index, { ...block, level: Number(e.target.value) as 1 | 2 | 3 })}
                className={inputClass()}
              >
                <option value={1}>H1</option>
                <option value={2}>H2</option>
                <option value={3}>H3</option>
              </select>
            </div>
          )}

          {block.type === "text" && (
            <textarea
              value={block.body}
              onChange={(e) => update(index, { ...block, body: e.target.value })}
              rows={3}
              placeholder="Contenu du paragraphe"
              className={inputClass()}
            />
          )}

          {block.type === "cta" && (
            <div className="flex gap-2">
              <input
                value={block.label}
                onChange={(e) => update(index, { ...block, label: e.target.value })}
                placeholder="Libellé du bouton"
                className={`${inputClass()} flex-1`}
              />
              <input
                value={block.href}
                onChange={(e) => update(index, { ...block, href: e.target.value })}
                placeholder="Lien (ex. /compatibilite)"
                className={`${inputClass()} flex-1`}
              />
            </div>
          )}

          {block.type === "image" && (
            <div className="flex gap-2">
              <input
                value={block.src}
                onChange={(e) => update(index, { ...block, src: e.target.value })}
                placeholder="URL de l'image"
                className={`${inputClass()} flex-1`}
              />
              <input
                value={block.alt}
                onChange={(e) => update(index, { ...block, alt: e.target.value })}
                placeholder="Texte alternatif"
                className={`${inputClass()} flex-1`}
              />
            </div>
          )}
        </div>
      ))}

      <div className="flex gap-2 text-sm">
        {(Object.keys(BLOCK_LABELS) as Block["type"][]).map((type) => (
          <button
            key={type}
            type="button"
            onClick={() => add(type)}
            className="rounded-md border border-neutral-700 px-3 py-1.5 text-neutral-300 hover:border-neutral-500 hover:text-white"
          >
            + {BLOCK_LABELS[type]}
          </button>
        ))}
      </div>
    </div>
  );
}
