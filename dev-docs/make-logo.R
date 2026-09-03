# Generates the askr hex sticker using the hexSticker package.
# Output: man/figures/askr-logo.png  (standard R hex: 240 x 278 px at 72 dpi)
#
# Run with: Rscript dev-docs/make-logo.R

options(repos = c(CRAN = "https://cloud.r-project.org"))

for (pkg in c("hexSticker", "ggplot2", "ggforce")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

library(hexSticker)
library(ggplot2)

# ── Lighthouse SVG subplot ────────────────────────────────────────────────────
subplot <- "/var/folders/2t/y65www2s12j7wjvnpxhkgcdc0000gp/T/opencode/lighthouse.svg"

# ── Hex sticker ───────────────────────────────────────────────────────────────

sticker(
  subplot    = subplot,
  package    = "askr",
  p_size     = 9,
  p_color    = "#FFFFFF",
  p_fontface = "bold",
  p_x        = 1.0,
  p_y        = 1.55,
  s_x        = 1.0,
  s_y        = 0.85,
  s_width    = 0.75,
  s_height   = 0.75,
  h_fill     = "#1C2A45",
  h_color    = "#F5A623",
  h_size     = 1.8,
  filename   = "man/figures/askr-logo.png",
  dpi        = 72
)

message("Done: man/figures/askr-logo.png")
