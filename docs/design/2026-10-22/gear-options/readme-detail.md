# Gear options D / E / F

Three independent proposals in `variants-detail.js`, authored for the combined Canvas/SVG review. None changes production art or gameplay. Origin `(0,0)`;128px frame; eight teeth; intended outer radius54, root36.5 and shoulder43. Cat art occupies62px; radius32.5 progress area stays quiet.

Named profiles: `MAIN=3.2`, ink `#583F21`; `SECONDARY=1.9`, material seam `#9B784B`. Flat tier fill is supplied to `draw(P,fill)`. No gradients, shine, shadows, extra material colors or center badges.

- **D — Carton bế:** repeated two-step die-cut tabs with short fold seams placed out on the tabs. The center is blank. Its broad angular shoulders distinguish it from a plain block cog.
- **E — Vòng có khe:** broad softened mechanical teeth and four genuinely transparent elliptical rim windows, centered at diagonal radius38.5 (radial extent35..42). The holes use reverse-winding subpaths, so Canvas/SVG nonzero fill leaves real alpha; no background-colored patch. Hole contours are structural `MAIN` lines. No interior seam is added. Inner hole ink starts about33.4, outside the center cat/progress space.
- **F — Răng tròn:** eight capsule caps with smooth U valleys. Cubic paths soften both the working ends and roots; no block shoulders or additional surface marks.

Only these exports are public: `GearDetail.D`, `.E`, `.F`, each containing `title`, `subtitle`, `draw(P,fill)`. Root supplies the combined preview, captures and native export/review. The shared Pen path records are the identical source for both Canvas and SVG.
