"""浜松いわた信用金庫を想起させる青×黄のStreamlitテーマ。"""

CSS = r"""
<style>
:root {
  --navy: #082d63;
  --blue: #0b45a0;
  --sky: #1c86e8;
  --yellow: #ffd43b;
  --ink: #102a4c;
  --muted: #60758d;
  --line: #dbe6f2;
  --surface: #ffffff;
}
html, body, [class*="css"] { font-family: "Noto Sans JP", "Yu Gothic UI", "Yu Gothic", Meiryo, sans-serif; color: var(--ink); }
.stApp { background: #f4f8fc; }
[data-testid="stHeader"] { background: transparent; }
[data-testid="stToolbar"], #MainMenu, footer { visibility: hidden; }
.block-container { max-width: 1180px; padding-top: 1rem; padding-bottom: 5rem; }

.topbar {
  display:flex; align-items:center; justify-content:space-between; gap:1rem;
  background:#fff; border:1px solid var(--line); border-radius:18px;
  padding:13px 18px; box-shadow:0 8px 28px rgba(8,45,99,.07); margin-bottom:12px;
}
.brand { display:flex; align-items:center; gap:11px; font-weight:800; color:var(--navy); letter-spacing:.02em; }
.brand-mark { width:38px; height:38px; border-radius:12px; background:linear-gradient(135deg,var(--blue) 0 55%,var(--yellow) 55%); box-shadow:inset 0 0 0 3px #fff; }
.auth-chip { background:#fff8d8; border:1px solid #f0c529; color:#6a5100; border-radius:999px; padding:7px 12px; font-size:.76rem; font-weight:700; white-space:nowrap; }

.hero {
  position:relative; overflow:hidden; border-radius:26px; padding:45px 44px;
  color:#fff; background:linear-gradient(120deg,#072a5d 0%,#0b4daf 58%,#1592e5 100%);
  box-shadow:0 20px 55px rgba(10,62,136,.19); margin:10px 0 20px;
}
.hero:after { content:""; position:absolute; right:-45px; bottom:-100px; width:310px; height:310px; border-radius:50%; background:rgba(255,212,59,.96); }
.hero:before { content:""; position:absolute; right:125px; top:-80px; width:180px; height:180px; border-radius:50%; border:32px solid rgba(255,255,255,.10); }
.hero > * { position:relative; z-index:2; max-width:720px; }
.eyebrow { display:inline-block; padding:6px 11px; border:1px solid rgba(255,255,255,.45); border-radius:999px; font-size:.74rem; font-weight:700; letter-spacing:.08em; }
.hero h1 { font-size:clamp(2rem,4vw,3.35rem); line-height:1.18; margin:16px 0 12px; font-weight:800; }
.hero p { font-size:1rem; line-height:1.8; color:#eaf4ff; max-width:630px; }
.accent { color:var(--yellow); }

.notice { background:#fff9dc; border:1px solid #efd04d; border-left:5px solid var(--yellow); border-radius:15px; padding:14px 17px; margin:12px 0 18px; color:#5a4a0b; font-size:.88rem; }
.section-kicker { color:var(--blue); font-size:.74rem; letter-spacing:.12em; font-weight:800; text-transform:uppercase; margin-top:26px; }
.section-title { color:var(--navy); font-size:1.55rem; font-weight:800; margin:3px 0 16px; }
.service-card { background:#fff; border:1px solid var(--line); border-radius:21px; padding:24px; min-height:205px; box-shadow:0 10px 30px rgba(19,64,111,.07); }
.service-card.blue { border-top:5px solid var(--blue); }
.service-card.yellow { border-top:5px solid var(--yellow); }
.service-no { font-size:.72rem; font-weight:800; letter-spacing:.14em; color:var(--blue); }
.service-card h3 { color:var(--navy); font-size:1.25rem; margin:10px 0 8px; }
.service-card p { color:var(--muted); line-height:1.75; font-size:.88rem; }
.mini-flow { display:flex; gap:6px; flex-wrap:wrap; margin-top:16px; }
.mini-flow span { background:#edf5ff; color:#23558d; padding:6px 9px; border-radius:8px; font-size:.7rem; font-weight:700; }

.page-head { background:linear-gradient(110deg,#082d63,#0d5ac1); border-radius:21px; padding:25px 28px; color:#fff; margin:10px 0 18px; }
.page-head small { color:var(--yellow); font-weight:800; letter-spacing:.12em; }
.page-head h1 { margin:5px 0; font-size:1.8rem; }
.page-head p { color:#dcecff; margin:0; font-size:.9rem; }
.step { display:inline-flex; align-items:center; gap:8px; color:var(--navy); font-weight:800; margin:8px 0; }
.step-num { width:27px; height:27px; display:inline-grid; place-items:center; border-radius:50%; color:#fff; background:var(--blue); font-size:.75rem; }
.result-panel { background:#fff; border:1px solid var(--line); border-radius:18px; padding:19px; margin:10px 0; box-shadow:0 7px 24px rgba(11,69,160,.05); }
.confidence { color:#167347; background:#e8f8ef; padding:4px 8px; border-radius:999px; font-weight:700; font-size:.7rem; }
.phase { background:#fff; border:1px solid var(--line); border-radius:17px; padding:18px; min-height:172px; }
.phase.active { border:2px solid var(--yellow); box-shadow:0 0 0 4px #fff8d4; }
.phase b { color:var(--blue); }
.metric-label { color:var(--muted); font-size:.75rem; }

div[data-testid="stButton"] > button, div[data-testid="stDownloadButton"] > button {
  width:100%; border-radius:11px; min-height:43px; font-weight:700; border:1px solid #0b45a0;
}
div[data-testid="stButton"] > button[kind="primary"], div[data-testid="stDownloadButton"] > button[kind="primary"] {
  color:#fff; background:linear-gradient(100deg,#082d63,#0b5fc8); border:0;
}
div[role="radiogroup"] { background:#fff; border:1px solid var(--line); border-radius:14px; padding:4px 8px; justify-content:center; }
div[role="radiogroup"] label { padding:5px 7px; }
[data-testid="stFileUploaderDropzone"] { background:#f8fbff; border:2px dashed #91b5dd; border-radius:16px; }
[data-testid="stForm"] { background:#fff; border:1px solid var(--line); border-radius:20px; padding:22px; box-shadow:0 15px 40px rgba(7,48,103,.08); }

@media (max-width: 700px) {
  .block-container { padding: .55rem .8rem 4rem; }
  .topbar { padding:12px; border-radius:14px; align-items:stretch; flex-direction:column; }
  .brand-mark { width:32px; height:32px; }
  .brand { font-size:.92rem; white-space:nowrap; }
  .auth-chip { font-size:.7rem; padding:7px 8px; text-align:center; }
  .hero { padding:29px 22px 92px; border-radius:20px; }
  .hero:after { width:180px; height:180px; right:-35px; bottom:-105px; }
  .hero h1 { font-size:2rem; }
  .hero p { font-size:.86rem; }
  .service-card { min-height:0; padding:19px; }
  .page-head { padding:20px; border-radius:17px; }
  .page-head h1 { font-size:1.5rem; }
  div[role="radiogroup"] { overflow-x:auto; justify-content:flex-start; flex-wrap:nowrap; }
  div[role="radiogroup"] label { white-space:nowrap; font-size:.74rem; }
}
</style>
"""
