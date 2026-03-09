/**
 * Primitive Palette Tokens
 * Source: Figma "Core - Theme" (Q3Cp3s8ZqChwPKEoYGmj1o) → 🎨 Colour page
 *
 * Raw colour values only — no semantic meaning at this layer.
 * All values extracted directly from Figma Global Colours via REST API.
 */

export const palette = {
  // ─── Brand: Primary ───────────────────────────────────────────────
  brand: {
    primary: {
      light: {
        resting: "#7695EF",
        pressed: "#3B62D0",
        selected: "#7695EF",
        text: "#FFFFFF",
        disabled: "rgba(32, 39, 59, 0.10)",
      },
      dark: {
        resting: "#7695EF",
        pressed: "#3B62D0",
        selected: "#20387D",
        text: "#FFFFFF",
        disabled: "rgba(255, 255, 255, 0.10)",
      },
    },
    // ─── Brand: Secondary ─────────────────────────────────────────────
    secondary: {
      light: {
        resting: "rgba(32, 39, 59, 0.10)",
        pressed: "rgba(32, 39, 59, 0.20)",
        selected: "rgba(32, 39, 59, 0.30)",
        text: "#20273B",
        disabled: "rgba(32, 39, 59, 0.10)",
      },
      dark: {
        resting: "rgba(255, 255, 255, 0.10)",
        pressed: "rgba(255, 255, 255, 0.20)",
        selected: "rgba(255, 255, 255, 0.30)",
        text: "#FFFFFF",
        disabled: "rgba(255, 255, 255, 0.10)",
      },
    },
  },

  // ─── Content ──────────────────────────────────────────────────────
  content: {
    primary: {
      light: {
        resting: "#1D1D1B",
        pressed: "#878787",
        selected: "#FFFFFF",
        disabled: "#B8B8B8",
      },
      dark: {
        resting: "#FFFFFF",
        pressed: "rgba(255, 255, 255, 0.70)",
        selected: "#20273B",
        disabled: "rgba(255, 255, 255, 0.40)",
      },
    },
    secondary: {
      light: {
        resting: "#20273B",
        pressed: "rgba(32, 39, 59, 0.40)",
        contrast: "#FFFFFF",
        disabled: "#B8B8B8",
      },
      dark: {
        resting: "#FFFFFF",
        pressed: "rgba(255, 255, 255, 0.60)",
        contrast: "#FFFFFF",
        disabled: "rgba(255, 255, 255, 0.40)",
      },
    },
  },

  // ─── Surface ──────────────────────────────────────────────────────
  surface: {
    container: {
      light: "#FFFFFF",
      dark: "#2C3354",
    },
    page: {
      light: "#F3F3F3",
      dark: "#20273B",
    },
    highlight: {
      light: "rgba(255, 255, 255, 0.10)",
      dark: "rgba(255, 255, 255, 0.10)",
    },
    disabled: {
      light: "#E2E2E2",
      dark: "rgba(255, 255, 255, 0.40)",
    },
    border: {
      default: {
        light: "#F3F3F3",
        dark: "#20273B",
      },
      heavy: {
        light: "#F3F3F3",
        dark: "#20273B",
      },
    },
    overlay: {
      default: {
        light: "rgba(32, 39, 59, 0.50)",
        dark: "rgba(32, 39, 59, 0.50)",
      },
      heavy: {
        light: "rgba(32, 39, 59, 0.70)",
        dark: "rgba(32, 39, 59, 0.70)",
      },
    },
    divider: {
      default: {
        light: "rgba(32, 39, 59, 0.20)",
        dark: "rgba(255, 255, 255, 0.20)",
      },
      heavy: {
        light: "rgba(32, 39, 59, 0.30)",
        dark: "rgba(255, 255, 255, 0.30)",
      },
    },
    skeleton: {
      light: "rgba(0, 0, 0, 0.20)",
      dark: "rgba(0, 0, 0, 0.20)",
    },
  },

  // ─── Status ───────────────────────────────────────────────────────
  status: {
    info: {
      light: {
        resting: "#5B6FD3",
        pressed: "#3F52A9",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#5B6FD3",
      },
      dark: {
        resting: "#5B6FD3",
        pressed: "#3F52A9",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#5B6FD3",
      },
    },
    error: {
      light: {
        resting: "#FF494B",
        pressed: "#D43A3C",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#FF494B",
      },
      dark: {
        resting: "#FF494B",
        pressed: "#D43A3C",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#FF494B",
      },
    },
    success: {
      light: {
        resting: "#56CC8A",
        pressed: "#46AB72",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#56CC8A",
      },
      dark: {
        resting: "#56CC8A",
        pressed: "#46AB72",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#56CC8A",
      },
    },
    warning: {
      light: {
        resting: "#E67E23",
        pressed: "#C76E1D",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#E67E23",
      },
      dark: {
        resting: "#E67E23",
        pressed: "#C76E1D",
        text: "#FFFFFF",
        disabled: "#F3F3F3",
        border: "#E67E23",
      },
    },
  },

  // ─── Sub-theme 01 (Purple) ────────────────────────────────────────
  subTheme01: {
    primary: {
      light: {
        resting: "#AEA1E5",
        pressed: "#7963D4",
        selected: "#AEA1E5",
        text: "#FFFFFF",
        disabled: "rgba(32, 39, 59, 0.10)",
      },
      dark: {
        resting: "#AEA1E5",
        pressed: "#9379FF",
        selected: "#AEA1E5",
        text: "#FFFFFF",
        disabled: "rgba(255, 255, 255, 0.10)",
      },
    },
  },

  // ─── Sub-theme 02 (Teal) ──────────────────────────────────────────
  subTheme02: {
    primary: {
      light: {
        resting: "#80CBC4",
        pressed: "#26A69A",
        selected: "#80CBC4",
        text: "#FFFFFF",
        disabled: "rgba(32, 39, 59, 0.10)",
      },
      dark: {
        resting: "#80CBC4",
        pressed: "#26A69A",
        selected: "#80CBC4",
        text: "#FFFFFF",
        disabled: "rgba(255, 255, 255, 0.10)",
      },
    },
  },

  // ─── Raw neutral base ─────────────────────────────────────────────
  neutral: {
    dark: "#20273B",
    light: "#F3F3F3",
    white: "#FFFFFF",
    black: "#1D1D1B",
    mid: "#878787",
    muted: "#B8B8B8",
    elevated: "#E2E2E2",
    deepDark: "#2C3354",
  },
} as const;
