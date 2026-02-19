import type { Config } from "tailwindcss";
import typography from "@tailwindcss/typography";

const config: Config = {
  darkMode: "class",
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: {
          50: "#f4f8fb",
          100: "#dce9f2",
          200: "#c0d9e8",
          300: "#8dbad4",
          400: "#5da0c6",
          500: "#3588b1",
          600: "#286f92",
          700: "#1f5773",
          800: "#1d485f",
          900: "#1d3d50",
          950: "#0d1e29"
        },
        accent: {
          50: "#ecfdff",
          100: "#cff8fd",
          200: "#a3effb",
          300: "#67e1f8",
          400: "#23c8eb",
          500: "#08aad0",
          600: "#0b87ac",
          700: "#116d8b",
          800: "#16586f",
          900: "#194a5e",
          950: "#0b2f3f"
        }
      },
      boxShadow: {
        card: "0 18px 48px -24px rgba(10, 19, 30, 0.5)"
      },
      borderRadius: {
        xl2: "1.35rem"
      },
      backgroundImage: {
        "soft-grid":
          "linear-gradient(to right, rgba(43,95,124,0.08) 1px, transparent 1px), linear-gradient(to bottom, rgba(43,95,124,0.08) 1px, transparent 1px)"
      },
      backgroundSize: {
        "soft-grid": "28px 28px"
      },
      keyframes: {
        fadeUp: {
          "0%": { opacity: "0", transform: "translateY(14px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        },
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-8px)" }
        }
      },
      animation: {
        fadeUp: "fadeUp 240ms ease-out",
        float: "float 6s ease-in-out infinite"
      }
    }
  },
  plugins: [typography]
};

export default config;
