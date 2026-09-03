# Design System Document: The Mindful Alchemist

## 1. Overview & Creative North Star
This design system moves away from the clinical, rigid grids of traditional health apps and toward a concept we call **"The Digital Sanctuary."** The North Star for this system is **Organic Precision**: a harmonious blend of high-tech intelligence (AI) and soft, human-centric wellness.

To break the "template" look, we utilize **Intentional Asymmetry**. Instead of perfectly centered layouts, use the spacing scale to create a "weighted" feel, where content flows like an editorial magazine. We lean heavily on overlapping elements—such as a data visualization chip breaking the boundary of a parent card—to create a sense of depth and life. The goal is to make the user feel like they are interacting with a living, breathing assistant rather than a database.

---

## 2. Colors & The Surface Philosophy
The palette is rooted in botanical vitality. We use deep forest greens (`primary`) for authority and soft mints (`primary_container`) for comfort.

### The "No-Line" Rule
**Borders are forbidden for sectioning.** To define a new content area, you must use background color shifts. For example, a `surface_container_low` card must sit on a `surface` background. If you need more definition, use a tonal shift, never a 1px solid line. This creates a "soft UI" that feels high-end and approachable.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers of fine vellum paper.
*   **Level 0 (Base):** `surface` (#f5f7f9).
*   **Level 1 (Sections):** `surface_container_low`.
*   **Level 2 (Active Cards):** `surface_container_lowest` (#ffffff).
*   **Level 3 (Floating AI Elements):** Semi-transparent `surface_tint` with a 20px backdrop blur.

### The "Glass & Gradient" Rule
To elevate the AI features, use **Glassmorphism**. Components like the AI Floating Action Button should use a semi-transparent `secondary` or `tertiary` fill with a `backdrop-blur`. Apply a subtle linear gradient (from `primary` to `primary_container` at a 135° angle) to main CTAs to give them a "lit from within" glow.

---

## 3. Typography: The Editorial Voice
We pair **Plus Jakarta Sans** (Display/Headlines) with **Inter** (Body) to create an authoritative yet friendly typographic scale.

*   **Display & Headlines:** Use `display-md` for daily calorie totals or "Hero" numbers. The generous x-height of Plus Jakarta Sans feels modern and "smart."
*   **Body:** Use `body-lg` for nutritional advice. Increase line-height to 1.6x the font size to ensure the "generous whitespace" feel extends into the text itself.
*   **Labels:** Use `label-md` in all-caps with +5% letter spacing for category tags (e.g., "PROTEIN," "VITAMIN C") to provide a sophisticated, metadata-driven look.

---

## 4. Elevation & Depth
We eschew traditional drop shadows for **Tonal Layering**.

*   **The Layering Principle:** A card should be identified by its color (`surface_container_lowest`) against the background (`surface`). This "White-on-Gray" approach is the hallmark of premium modern design.
*   **Ambient Shadows:** For floating AI prompts, use an extra-diffused shadow: `offset: 0, 20px`, `blur: 40px`, `color: alpha(on_surface, 0.06)`. It should feel like a soft glow, not a hard shadow.
*   **The "Ghost Border" Fallback:** If a container lacks contrast (e.g., on certain mobile screens), use the `outline_variant` token at **15% opacity**. It should be felt, not seen.
*   **Curvature:** Use the `md` (1.5rem / 24px) or `lg` (2rem / 32px) tokens for all cards. This aggressive rounding reinforces the "friendly" brand personality.

---

## 5. Components

### The AI Floating Action Button (The "Aura" FAB)
This is the heart of the app. It does not use a flat color.
*   **Background:** Linear gradient `secondary` to `tertiary`.
*   **Shape:** `full` (pill-shaped).
*   **Effect:** A subtle `primary_fixed` outer glow to signify the AI is "listening" or "thinking."

### Modern Nutrition Cards
*   **Structure:** No dividers. Use `3` (1rem) spacing between the title and metadata.
*   **Visuals:** Use a `surface_container_highest` background for the progress bar track, with a `primary` fill.
*   **Rounding:** Always `md` (1.5rem).

### Progress Bars (The "Vitals" Bar)
*   **Height:** 8px to 12px for a modern, bold look.
*   **Cap:** Rounded (`full`).
*   **Interaction:** On tap, the bar should expand slightly, revealing `label-sm` details using a `tertiary` color.

### Input Fields
*   **Style:** No bottom line. Use a `surface_container_low` filled background with `xl` (3rem) corner radius for search bars.
*   **States:** On focus, the background shifts to `surface_container_lowest` with a 1px "Ghost Border" of `primary`.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use asymmetrical margins. If the left margin is `6` (2rem), try making the right content edge bleed off-screen or use `8` (2.75rem) to create an editorial feel.
*   **Do** use `primary_container` as a background for "Success" or "Encouragement" messages to bathe the user in a healthy green glow.
*   **Do** use high-quality food photography with soft, natural lighting that mirrors the `surface` color tones.

### Don’t:
*   **Don’t** use black (#000000). Always use `on_surface` (#2c2f31) for text to maintain a soft, premium contrast.
*   **Don’t** use 1px dividers between list items. Use `3.5` (1.2rem) of vertical whitespace instead.
*   **Don’t** use standard "Information" blues. Use the `tertiary` (#006573) teal tones to keep the palette cohesive and health-focused.
*   **Don’t** crowd the edges. If a card feels full, increase the padding to `5` (1.7rem) and reduce the font size of secondary text.