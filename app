import streamlit as st
import pandas as pd

# --- CONFIGURATION ---
# Replace this with your actual Google Sheet ID
# You can find it in your browser URL: https://docs.google.com/spreadsheets/d/[SHEET_ID]/edit
SHEET_ID = "https://docs.google.com/spreadsheets/d/15nFXQspQ7lvC-iY999y8Bb8DeEZzlAod0FqnW-IckeU/edit?gid=0#gid=0"
SHEET_NAME = "Sheet1"

# Construction of the direct CSV export link
CSV_URL = f"https://docs.google.com/spreadsheets/d/15nFXQspQ7lvC-iY999y8Bb8DeEZzlAod0FqnW-IckeU/gviz/tq?tqx=out:csv&sheet=Sheet1"

# --- APP SETUP ---
st.set_page_config(
    page_title="TSX Dashboard | Groww Style", 
    page_icon="📈",
    layout="wide", 
    initial_sidebar_state="expanded"
)

# Custom CSS for Groww-like Styling
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');
    
    html, body, [class*="css"]  {
        font-family: 'Roboto', sans-serif;
    }
    
    .main {
        background-color: #f8f9fb;
    }
    
    /* Sidebar styling */
    section[data-testid="stSidebar"] {
        background-color: white !important;
        border-right: 1px solid #eee;
    }

    /* Sector Buttons */
    .stButton>button {
        width: 100%;
        border-radius: 8px;
        height: 3.5em;
        background-color: white;
        color: #444;
        border: 1px solid #eee;
        text-align: left;
        padding-left: 20px;
        transition: all 0.3s;
        font-weight: 500;
    }
    .stButton>button:hover {
        border-color: #00d09c;
        color: #00d09c;
        background-color: #f1fcf9;
    }
    
    /* Active Sector State simulation via CSS is hard, 
       but we can style the container */
    
    .index-card {
        background-color: white;
        padding: 24px;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.03);
        border: 1px solid #f0f0f0;
        margin-bottom: 20px;
    }
    
    .stock-row {
        background-color: white;
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 8px;
        border: 1px solid #f0f0f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    
    .metric-pos { color: #00d09c; font-weight: 600; }
    .metric-neg { color: #eb5b3c; font-weight: 600; }
    
    /* Search bar styling */
    .stTextInput>div>div>input {
        border-radius: 8px;
    }
    </style>
    """, unsafe_allow_html=True)

# --- DATA LOADING ---
@st.cache_data(ttl=300)  # Refresh data every 5 minutes
def load_data():
    try:
        # We use storage_options if needed, but for public sheets simple read_csv is enough
        df = pd.read_csv(CSV_URL)
        # Cleaning column names (stripping whitespace)
        df.columns = [c.strip() for c in df.columns]
        return df
    except Exception as e:
        return pd.DataFrame() # Return empty on error

# --- LOGIC ---
df_stocks = load_data()

# Initialize Session State
if 'page' not in st.session_state:
    st.session_state.page = "Home"
if 'selected_sector' not in st.session_state:
    st.session_state.selected_sector = None

# --- SIDEBAR ---
with st.sidebar:
    st.image("https://groww.in/logo-groww-dark.60145e4a.svg", width=130)
    st.markdown("<br>", unsafe_allow_html=True)
    
    if st.button("🏠 Home"):
        st.session_state.page = "Home"
        st.session_state.selected_sector = None
    if st.button("💼 Portfolio"):
        st.session_state.page = "Portfolio"
    
    st.divider()
    
    if not df_stocks.empty:
        st.markdown("### Explore Sectors")
        sectors = sorted(df_stocks['Sector'].unique())
        for sector in sectors:
            if st.button(f" {sector}", key=f"btn_{sector}"):
                st.session_state.page = "Home"
                st.session_state.selected_sector = sector
    
    st.spacer = st.empty()
    st.markdown("<div style='position: fixed; bottom: 20px; font-size: 12px; color: #999;'>Live Data via Google Finance</div>", unsafe_allow_html=True)

# --- MAIN PAGE ---
if df_stocks.empty:
    st.error("⚠️ Data connection failed.")
    st.info("Check if your Google Sheet is shared as 'Anyone with the link can view' and that the SHEET_ID is correct.")
    st.stop()

if st.session_state.page == "Home":
    # Search and Header
    col_h1, col_h2 = st.columns([2, 1])
    with col_h1:
        search_query = st.text_input("🔍 Search stocks, sectors...", placeholder="e.g. Material")
    
    # Hero Indices
    idx_col1, idx_col2, idx_col3 = st.columns(3)
    with idx_col1:
        st.markdown('''
            <div class="index-card">
                <p style="color:#777; margin-bottom:5px;">S&P/TSX Composite</p>
                <h2 style="margin:0;">21,585.10</h2>
                <p class="metric-pos">▲ 102.40 (0.48%)</p>
            </div>
        ''', unsafe_allow_html=True)
    with idx_col2:
        st.markdown('''
            <div class="index-card">
                <p style="color:#777; margin-bottom:5px;">S&P 500</p>
                <h2 style="margin:0;">5,137.08</h2>
                <p class="metric-pos">▲ 40.23 (0.80%)</p>
            </div>
        ''', unsafe_allow_html=True)
    with idx_col3:
        st.markdown('''
            <div class="index-card">
                <p style="color:#777; margin-bottom:5px;">Nasdaq</p>
                <h2 style="margin:0;">16,274.94</h2>
                <p class="metric-pos">▲ 183.02 (1.14%)</p>
            </div>
        ''', unsafe_allow_html=True)

    # Display Logic
    display_df = df_stocks.copy()
    
    # Filter by Search
    if search_query:
        display_df = display_df[
            display_df['Ticker'].str.contains(search_query, case=False) | 
            display_df['Sector'].str.contains(search_query, case=False)
        ]

    # Filter by Sector Sidebar
    if st.session_state.selected_sector:
        display_df = display_df[display_df['Sector'] == st.session_state.selected_sector]
        st.subheader(f"Results for {st.session_state.selected_sector}")
    else:
        st.subheader("All Stocks" if not search_query else "Search Results")

    # The Stock List
    if not display_df.empty:
        # Header for the list
        hcol1, hcol2, hcol3 = st.columns([3, 1, 1])
        hcol1.caption("COMPANY")
        hcol2.caption("MARKET PRICE")
        hcol3.caption("DAY CHANGE")
        st.markdown("<hr style='margin: 5px 0 15px 0;'>", unsafe_allow_html=True)

        for _, row in display_df.iterrows():
            c1, c2, c3 = st.columns([3, 1, 1])
            
            # Format % Change
            change_val = str(row['%Chng Daily'])
            is_pos = "-" not in change_val
            change_class = "metric-pos" if is_pos else "metric-neg"
            prefix = "+" if is_pos else ""

            with c1:
                st.markdown(f"**{row['Ticker']}** \n<small style='color:#888'>{row['Sector']}</small>", unsafe_allow_html=True)
            with c2:
                st.markdown(f"**${row['Price']:.2f}**", unsafe_allow_html=True)
            with c3:
                st.markdown(f"<span class='{change_class}'>{prefix}{change_val}</span>", unsafe_allow_html=True)
            
            st.divider()
    else:
        st.warning("No stocks found matching your criteria.")

elif st.session_state.page == "Portfolio":
    st.title("My Portfolio")
    st.info("Portfolio tracking feature is being developed. Your data in Google Sheets will be used to calculate P&L here.")
