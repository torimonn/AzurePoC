from __future__ import annotations

import os
from datetime import datetime
from typing import Any

import streamlit as st

from services.api_client import WorkAssistApi
from services.auth import AUTH_LABELS, authenticate, auth_mode
from services.excel_service import build_business_evaluation_excel
from services.mock_data import (
    BUSINESS_CHALLENGES,
    CUSTOMER_ATTRIBUTES,
    DECISIONS,
    FINANCIAL_ANALYSIS,
    SOURCE_DOCUMENTS,
    SUMMARY,
    SWOT_ANALYSIS,
    TASKS,
    TRADING_PARTNERS,
)
from ui.components import page_head, step, topbar
from ui.theme import CSS


st.set_page_config(
    page_title="AI業務アシスト",
    page_icon="🏦",
    layout="wide",
    initial_sidebar_state="collapsed",
)
st.markdown(CSS, unsafe_allow_html=True)

API = WorkAssistApi()
NAV_ITEMS = ["ホーム", "事業性評価", "音声議事録", "履歴", "構成・認証"]


def init_state() -> None:
    defaults = {
        "page": "ホーム",
        "user": None,
        "document_ready": False,
        "document_sources": SOURCE_DOCUMENTS,
        "minutes_ready": False,
        "history": [
            {
                "type": "議事録",
                "title": "遠州テクノ様 設備更新打合せ",
                "created_at": "2026/07/14 16:20",
                "status": "完了",
            },
            {
                "type": "Excel",
                "title": "遠州テクノ様 事業性評価シート",
                "created_at": "2026/07/12 10:05",
                "status": "完了",
            },
        ],
        "audit_log": [],
    }
    for key, value in defaults.items():
        if key not in st.session_state:
            st.session_state[key] = value


def audit(action: str) -> None:
    user = st.session_state.user
    st.session_state.audit_log.append(
        {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "employee_no": user.employee_no if user else "anonymous",
            "action": action,
        }
    )


def go(page: str) -> None:
    st.session_state.page = page
    st.rerun()


def as_records(table: Any) -> list[dict[str, Any]]:
    """st.data_editorの戻り値をExcel生成用の辞書リストへそろえる。"""
    if hasattr(table, "to_dict"):
        return table.to_dict(orient="records")
    return list(table)


def login_page() -> None:
    demo_mode = os.getenv("DEMO_MODE", "false").lower() == "true"
    topbar()
    left, center, right = st.columns([0.5, 1.2, 0.5])
    with center:
        st.markdown(
            """
            <div class="hero" style="padding:34px 30px 78px">
              <span class="eyebrow">CLOSED NETWORK / PoC</span>
              <h1>職員番号で<br><span class="accent">業務をはじめる</span></h1>
              <p>Entra ID導入までの暫定認証です。閉域・接続元制限・監査ログを前提に運用します。</p>
            </div>
            """,
            unsafe_allow_html=True,
        )
        with st.form("temporary_login", clear_on_submit=False):
            st.markdown("#### 暫定職員番号認証")
            employee_no = st.text_input(
                "職員番号",
                value="123456" if demo_mode else "",
                placeholder="例：123456",
                max_chars=10,
            )
            login_code = st.text_input(
                "ログインコード",
                value="",
                type="password",
                help="本番ではFastAPI側で照合し、Streamlitには保持しません。",
            )
            submitted = st.form_submit_button("ログイン", type="primary", width="stretch")
        if submitted:
            result = authenticate(employee_no, login_code)
            if result.ok:
                st.session_state.user = result.user
                audit("temporary_login_success")
                st.rerun()
            st.error(result.message)
        if demo_mode:
            st.caption("ローカルデモ用の職員番号は123456です。ログインコードは環境変数で設定します。")


def navigation() -> None:
    selected = st.radio(
        "メインメニュー",
        NAV_ITEMS,
        index=NAV_ITEMS.index(st.session_state.page),
        horizontal=True,
        label_visibility="collapsed",
    )
    if selected != st.session_state.page:
        st.session_state.page = selected
        st.rerun()


def home_page() -> None:
    user = st.session_state.user
    st.markdown(
        f"""
        <div class="hero">
          <span class="eyebrow">SECURE AI WORKSPACE</span>
          <h1>定型業務を、<br><span class="accent">もっと速く。もっと確かに。</span></h1>
          <p>{user.display_name}さん、お疲れさまです。資料の転記と議事録作成をAIが支援し、最終確認は職員が行います。</p>
        </div>
        <div class="notice"><b>暫定職員番号認証で運用中</b>　履歴は職員番号にひも付けて保存します。将来のAD／Entra ID切替後も同じキーで引き継ぎます。</div>
        <div class="section-kicker">Services</div>
        <div class="section-title">利用する機能を選んでください</div>
        """,
        unsafe_allow_html=True,
    )
    col1, col2 = st.columns(2, gap="large")
    with col1:
        st.markdown(
            """
            <div class="service-card blue">
              <div class="service-no">SERVICE 01</div>
              <h3>事業性評価シートを作成</h3>
              <p>決算書PDFや参考資料を読み取り、顧客属性・財務・取引先・SWOT・事業課題を整理します。</p>
              <div class="mini-flow"><span>資料登録</span><span>文書読取</span><span>AI整形</span><span>Excel取得</span></div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        if st.button("事業性評価を開く", type="primary", width="stretch"):
            go("事業性評価")
    with col2:
        st.markdown(
            """
            <div class="service-card yellow">
              <div class="service-no">SERVICE 02</div>
              <h3>音声から議事録を作成</h3>
              <p>その場で録音、または音声ファイルを登録。文字起こし・要約・決定事項・担当タスクを整理します。</p>
              <div class="mini-flow"><span>録音</span><span>文字起こし</span><span>要約</span><span>Blob保存</span></div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        if st.button("音声議事録を開く", width="stretch"):
            go("音声議事録")

    st.markdown('<div class="section-kicker">Status</div><div class="section-title">利用状況</div>', unsafe_allow_html=True)
    a, b, c = st.columns(3)
    a.metric("今月のExcel作成", "18件", "+4件")
    b.metric("今月の議事録", "11件", "+2件")
    c.metric("処理待ち", "0件", "正常")


def document_page() -> None:
    page_head(
        "BUSINESS ASSESSMENT",
        "事業性評価シートを作成",
        "決算書と参考資料を読み取り、Azure OpenAIで評価項目を整理してExcelへ出力します。",
    )
    left, right = st.columns([1, 1], gap="large")
    with left:
        step(1, "決算書・参考資料を選択")
        uploaded_files = st.file_uploader(
            "決算書PDF・試算表・会社案内・取引先資料",
            type=["pdf", "png", "jpg", "jpeg", "xlsx", "docx"],
            accept_multiple_files=True,
            label_visibility="collapsed",
            help="複数ファイルをまとめて選択できます。実運用ではアップロード直後にBlobの入力領域へ保存します。",
        )
        source_documents = [file.name for file in uploaded_files] if uploaded_files else SOURCE_DOCUMENTS
        step(2, "AIで読取・整形")
        st.info(
            f"処理フロー：{API.processing_pipeline()}\n\n"
            "Document Intelligenceが文字・表を読み取り、Azure OpenAIが事業性評価の項目へ整理します。"
        )
        with st.expander("対象資料", expanded=True):
            for filename in source_documents:
                st.write(f"・{filename}")
        if st.button(
            "サンプル資料で評価案を作成" if not uploaded_files else "選択した資料から評価案を作成",
            type="primary",
            width="stretch",
        ):
            st.session_state.document_ready = True
            st.session_state.document_sources = source_documents
            audit(f"business_evaluation_extracted:{','.join(source_documents)}")
            st.rerun()
        st.caption(f"API：{API.health_label()} ／ 入力資料：{len(source_documents)}件")

    with right:
        step(3, "AIの整理結果を確認・修正")
        if not st.session_state.document_ready:
            st.markdown(
                '<div class="result-panel"><b>事業性評価の下書きがここに表示されます</b><br><span style="color:#60758d;font-size:.85rem">左側で資料を選び、評価案の作成を実行してください。</span></div>',
                unsafe_allow_html=True,
            )
        else:
            st.markdown('<span class="confidence">文書読取の平均信頼度 94%</span>', unsafe_allow_html=True)
            customer_tab, financial_tab, partners_tab, swot_tab, challenges_tab = st.tabs(
                ["顧客属性", "財務分析", "取引先", "SWOT", "事業課題"]
            )

            edited_customer: dict[str, str] = {}
            with customer_tab:
                for index, (key, value) in enumerate(CUSTOMER_ATTRIBUTES.items()):
                    edited_customer[key] = st.text_input(
                        key,
                        value=value,
                        key=f"customer_{index}",
                    )

            with financial_tab:
                edited_financial_table = st.data_editor(
                    FINANCIAL_ANALYSIS,
                    width="stretch",
                    hide_index=True,
                    num_rows="fixed",
                    key="financial_analysis_editor",
                    column_config={"AI評価": st.column_config.TextColumn(width="large")},
                )

            with partners_tab:
                edited_partner_table = st.data_editor(
                    TRADING_PARTNERS,
                    width="stretch",
                    hide_index=True,
                    num_rows="dynamic",
                    key="trading_partners_editor",
                    column_config={"取引状況・リスク": st.column_config.TextColumn(width="large")},
                )

            edited_swot: dict[str, dict[str, str]] = {}
            with swot_tab:
                for category, values in SWOT_ANALYSIS.items():
                    with st.expander(category, expanded=True):
                        content = st.text_area(
                            "内容",
                            value=values["内容"],
                            key=f"swot_content_{category}",
                        )
                        evidence = st.text_input(
                            "評価根拠",
                            value=values["評価根拠"],
                            key=f"swot_evidence_{category}",
                        )
                        edited_swot[category] = {"内容": content, "評価根拠": evidence}

            with challenges_tab:
                edited_challenge_table = st.data_editor(
                    BUSINESS_CHALLENGES,
                    width="stretch",
                    hide_index=True,
                    num_rows="dynamic",
                    key="business_challenges_editor",
                    column_config={
                        "現状・背景": st.column_config.TextColumn(width="large"),
                        "対応案": st.column_config.TextColumn(width="large"),
                    },
                )

            evaluation_data = {
                "customer_attributes": edited_customer,
                "financial_analysis": as_records(edited_financial_table),
                "trading_partners": as_records(edited_partner_table),
                "swot_analysis": edited_swot,
                "business_challenges": as_records(edited_challenge_table),
            }
            st.warning("AIの抽出・分析結果は参考情報です。原資料と照合し、担当職員が確認・修正してください。")
            excel_data = build_business_evaluation_excel(
                evaluation_data,
                st.session_state.document_sources,
            )
            step(4, "Excelを取得")
            downloaded = st.download_button(
                "事業性評価シートをダウンロード",
                data=excel_data,
                file_name="事業性評価シート_株式会社遠州テクノ.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                type="primary",
                width="stretch",
            )
            st.caption("保存先はブラウザーで設定されている「ダウンロード」フォルダーです。")
            if downloaded:
                audit("business_evaluation_excel_downloaded")
                st.success("Excelのダウンロードを開始しました。ブラウザーのダウンロード一覧を確認してください。")


def minutes_page() -> None:
    page_head("VOICE MINUTES", "音声議事録を作成", "録音から文字起こし・要約・決定事項・担当タスクを整理します。")
    left, right = st.columns([0.9, 1.1], gap="large")
    with left:
        step(1, "会議情報")
        title = st.text_input("会議名", "遠州テクノ様 設備更新打合せ")
        attendees = st.text_input("参加者", "浜松 太郎、鈴木 一郎")
        step(2, "録音または音声を選択")
        audio = st.audio_input("録音する")
        uploaded_audio = st.file_uploader(
            "録音済みファイルを選択",
            type=["wav", "mp3", "m4a"],
        )
        source = audio or uploaded_audio
        if source:
            st.audio(source)
        if st.button(
            "サンプル音声で議事録を作成" if source is None else "文字起こし・要約を開始",
            type="primary",
            width="stretch",
        ):
            st.session_state.minutes_ready = True
            audit(f"minutes_created:{title}")
            st.rerun()
        st.caption("録音データと生成結果は、職員番号別のBlobパスへ保存する想定です。")

    with right:
        step(3, "AI生成結果を確認")
        if not st.session_state.minutes_ready:
            st.markdown(
                '<div class="result-panel"><b>議事録がここに表示されます</b><br><span style="color:#60758d;font-size:.85rem">録音またはサンプル音声から作成できます。</span></div>',
                unsafe_allow_html=True,
            )
        else:
            with st.container(border=True):
                st.markdown("#### 要約")
                summary = st.text_area("要約本文", SUMMARY, height=135, label_visibility="collapsed")
                st.markdown("#### 決定事項")
                for item in DECISIONS:
                    st.write(f"・{item}")
                st.markdown("#### 担当タスク")
                for task, owner, due in TASKS:
                    st.write(f"・{task}｜担当：{owner}｜期限：{due}")
            text = (
                f"会議名：{title}\n参加者：{attendees}\n\n要約\n{summary}\n\n"
                + "決定事項\n"
                + "\n".join(f"- {x}" for x in DECISIONS)
                + "\n\n担当タスク\n"
                + "\n".join(f"- {x[0]} / {x[1]} / {x[2]}" for x in TASKS)
            )
            if st.download_button(
                "議事録をダウンロード",
                data=text.encode("utf-8-sig"),
                file_name="議事録_遠州テクノ様.txt",
                mime="text/plain",
                type="primary",
                width="stretch",
            ):
                audit(f"minutes_downloaded:{title}")


def history_page() -> None:
    user = st.session_state.user
    page_head("MY HISTORY", "処理履歴", f"職員番号 {user.employee_no} の保存済みデータを表示します。")
    query_col, type_col = st.columns([2, 1])
    query = query_col.text_input("履歴を検索", placeholder="会議名・帳票名で検索")
    kind = type_col.selectbox("種類", ["すべて", "Excel", "議事録"])

    rows = st.session_state.history
    rows = [r for r in rows if query.lower() in r["title"].lower()]
    if kind != "すべて":
        rows = [r for r in rows if r["type"] == kind]
    if not rows:
        st.info("該当する履歴はありません。")
    for row in rows:
        with st.container(border=True):
            c1, c2, c3 = st.columns([3, 1.3, 0.7])
            c1.markdown(f"**{row['title']}**  \n{row['created_at']}")
            c2.write(f"{row['type']} ／ {row['status']}")
            c3.button("詳細", key=f"detail_{row['type']}_{row['created_at']}")

    with st.expander("監査ログ（PoC確認用）"):
        if st.session_state.audit_log:
            st.dataframe(st.session_state.audit_log, width="stretch", hide_index=True)
        else:
            st.caption("このセッションの操作ログはまだありません。")


def architecture_page() -> None:
    page_head("ARCHITECTURE & AUTH", "構成・認証切替", "初期の暫定認証から、オンプレAD・Entra IDへ段階的に移行します。")
    st.markdown('<div class="section-kicker">Authentication roadmap</div><div class="section-title">認証方式を環境変数で切替</div>', unsafe_allow_html=True)
    c1, c2, c3 = st.columns(3, gap="medium")
    with c1:
        st.markdown(
            """<div class="phase active"><b>PHASE 1 ／ 初期</b><h3>暫定職員番号認証</h3><p>閉域・IP制限・監査ログを前提。履歴キーは職員番号。</p><code>AUTH_MODE=temporary</code></div>""",
            unsafe_allow_html=True,
        )
    with c2:
        st.markdown(
            """<div class="phase"><b>PHASE 2 ／ 移行</b><h3>オンプレAD</h3><p>FastAPIまたは認証プロキシでAD連携。職員番号をクレームへマッピング。</p><code>AUTH_MODE=onprem</code></div>""",
            unsafe_allow_html=True,
        )
    with c3:
        st.markdown(
            """<div class="phase"><b>PHASE 3 ／ 将来</b><h3>Entra ID</h3><p>OIDCへ切替。employee_noを維持して履歴をそのまま引き継ぐ。</p><code>AUTH_MODE=entra</code></div>""",
            unsafe_allow_html=True,
        )

    st.markdown('<div class="section-kicker">Recommended composition</div><div class="section-title">閉域向けの推奨構成</div>', unsafe_allow_html=True)
    st.code(
        """[スマホ / PC]
      │ HTTPS（閉域・接続元制限）
      ▼
[Reverse Proxy / WAF]
      ├── Streamlit：画面・入力・ダウンロード
      └── FastAPI：認証、処理受付、履歴API、監査ログ
              ├── Document Intelligence（決算書・参考資料の読取）
              ├── Azure OpenAI（事業性評価項目への整形・分析）
              ├── Speech / 要約モデル
              ├── Blob Storage（原本、テンプレート、成果物、音声）
              └── Table / DB（処理履歴、状態、職員番号キー）""",
        language="text",
    )
    current = auth_mode()
    st.info(f"現在の設定：{AUTH_LABELS[current]} ／ API接続：{API.health_label()}")


init_state()
if st.session_state.user is None:
    login_page()
    st.stop()

topbar(st.session_state.user.employee_no)
navigation()

page = st.session_state.page
if page == "ホーム":
    home_page()
elif page == "事業性評価":
    document_page()
elif page == "音声議事録":
    minutes_page()
elif page == "履歴":
    history_page()
else:
    architecture_page()

st.divider()
foot_left, foot_right = st.columns([3, 1])
foot_left.caption("AI業務アシスト PoC ｜ 出力内容は必ず職員が確認してください")
if foot_right.button("ログアウト", width="stretch"):
    audit("logout")
    st.session_state.user = None
    st.session_state.page = "ホーム"
    st.rerun()
