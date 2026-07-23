from __future__ import annotations

import html

import streamlit as st


def topbar(employee_no: str | None = None) -> None:
    user = f"職員番号 {html.escape(employee_no)}" if employee_no else "未ログイン"
    st.markdown(
        f"""
        <div class="topbar">
          <div class="brand"><div class="brand-mark"></div><div>AI業務アシスト</div></div>
          <div class="auth-chip">暫定職員番号認証 ｜ {user}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def page_head(kicker: str, title: str, description: str) -> None:
    st.markdown(
        f"""
        <div class="page-head">
          <small>{html.escape(kicker)}</small>
          <h1>{html.escape(title)}</h1>
          <p>{html.escape(description)}</p>
        </div>
        """,
        unsafe_allow_html=True,
    )


def step(number: int, label: str) -> None:
    st.markdown(
        f'<div class="step"><span class="step-num">{number}</span>{html.escape(label)}</div>',
        unsafe_allow_html=True,
    )

