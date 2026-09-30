# Rebuilds the report and slide, then prints them with Edge (headless). Run: bash print.sh
cd "$(dirname "$0")"
N="C:/Users/dangp/AppData/Local/OpenAI/Codex/runtimes/cua_node/13827bafdc0b5422/bin/node.exe"
E="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
W="$(pwd -W)"
U="file:///$W"
P="${TEMP:-/tmp}/edge-pdf"
pdf() { "$E" --headless=new --disable-gpu --no-pdf-header-footer --user-data-dir="$P" --allow-file-access-from-files --print-to-pdf="$W/$2" "$U/$1" 2>/dev/null; }
count() { "$N" -e "const b=require('fs').readFileSync('$1').toString('latin1');console.log((b.match(/\/Type\s*\/Page[^s]/g)||[]).length)"; }
"$N" build.js
pdf bao_cao.html bao_cao_thiet_ke_level.pdf
PAGES=$(count bao_cao_thiet_ke_level.pdf)
PAGES=$PAGES "$N" build.js
pdf bao_cao.html bao_cao_thiet_ke_level.pdf
pdf tong_quan_1_trang.html tong_quan_1_trang.pdf
"$E" --headless=new --disable-gpu --user-data-dir="$P" --allow-file-access-from-files --hide-scrollbars --window-size=1920,1080 --screenshot="$W/tong_quan_1_trang.png" "$U/tong_quan_1_trang.html" 2>/dev/null
echo "report pages: $(count bao_cao_thiet_ke_level.pdf), slide pages: $(count tong_quan_1_trang.pdf)"
# The 50-level table as .xlsx (read as UTF-8, so Vietnamese survives in any spreadsheet app).
"/c/Program Files/LibreOffice/program/soffice.exe" --headless --infilter="CSV:44,34,76,1" --convert-to xlsx:"Calc MS Excel 2007 XML" --outdir "$W" _build/bang_tien_trinh_50_level.csv >/dev/null 2>&1 && echo "xlsx: bang_tien_trinh_50_level.xlsx"
