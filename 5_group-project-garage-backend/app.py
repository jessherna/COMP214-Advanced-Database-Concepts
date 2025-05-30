import streamlit as st
import pandas as pd
import cx_Oracle
from datetime import datetime, timedelta

# Database connection function
def get_db_connection():
    return cx_Oracle.connect(user='SYSTEM', password='Vardamir', dsn='localhost:1521/xe')

# Function to execute SQL queries
def execute_sql(query):
    try:
        with get_db_connection() as conn:
            return pd.read_sql(query, conn)
    except cx_Oracle.Error as e:
        st.error(f"Error executing SQL: {e}")
        return None

# Function to call procedures
def call_procedure(procedure_name, params=None):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Enable DBMS_OUTPUT
            cursor.callproc("dbms_output.enable")
            
            # Call the procedure
            cursor.callproc(procedure_name, params)
            
            # Fetch DBMS_OUTPUT
            chunk_size = 100
            lines = []
            numlines = cursor.var(int)
            linebuf = cursor.arrayvar(str, chunk_size)
            while True:
                cursor.callproc("dbms_output.get_lines", (linebuf, numlines))
                nlines = numlines.getvalue()
                lines.extend(linebuf.getvalue()[:nlines])
                if nlines < chunk_size:
                    break
            
            # Commit the transaction
            conn.commit()
            
            return lines
    except cx_Oracle.Error as e:
        st.error(f"Error during procedure call: {e}")
        return None

# Streamlit UI
st.set_page_config(page_title="Auto Dealership Database Interface", layout="wide")

st.title('Auto Dealership Database Interface')

# Sidebar for navigation
st.sidebar.title("Navigation")
page = st.sidebar.radio("Go to", ["View Data", "Update Vehicle", "Insert Workorder", "Overdue Payments", "Revenue Calculator"])

if page == "View Data":
    st.header('View Data')
    
    tables = ["ad_vehicles", "ad_customers", "ad_workorders", "ad_payments", "ad_services", "service_schedule"]
    selected_table = st.selectbox("Choose a table to view", tables)
    
    if st.button('View Table'):
        query = f"SELECT * FROM {selected_table}"
        data = execute_sql(query)
        if data is not None:
            st.write(data)

elif page == "Update Vehicle":
    st.header('Update Vehicle Mileage')
    
    vin = st.text_input('VIN')
    new_mileage = st.number_input('New Mileage', min_value=0)
    
    if st.button('Update Mileage'):
        if not vin:
            st.error("Please enter a VIN")
        elif new_mileage <= 0:
            st.error("Mileage must be greater than 0")
        else:
            result = call_procedure('auto_dealership_pkg.update_vehicle_mileage', [vin, new_mileage])
            if result:
                for line in result:
                    st.write(line)
                st.success('Mileage updated successfully.')

elif page == "Insert Workorder":
    st.header('Insert Workorder')
    
    vin_workorder = st.text_input('VIN for Workorder')
    
    services = {
        'Oil Change': 1,
        'Tire Rotation': 2,
        'Brake Service': 3,
        'Battery Replacement': 4,
        'Air Filter Replacement': 5
    }
    
    selected_service = st.selectbox('Select Service', list(services.keys()))
    schedule_id = services[selected_service]
    
    start_date = st.date_input('Start Date', value=datetime.now())
    
    if st.button('Insert Workorder'):
        if not vin_workorder:
            st.error("Please enter a VIN")
        else:
            result = call_procedure('auto_dealership_pkg.insert_workorder', 
                                    [vin_workorder, schedule_id, start_date.strftime('%Y-%m-%d')])
            if result:
                for line in result:
                    st.write(line)
                st.success('Workorder inserted successfully.')

elif page == "Overdue Payments":
    st.header('Get Overdue Payments')
    
    if st.button('Get Overdue Payments'):
        result = call_procedure('auto_dealership_pkg.get_overdue_payments')
        if result:
            for line in result:
                st.write(line)

elif page == "Revenue Calculator":
    st.header('Calculate Revenue')
    
    col1, col2 = st.columns(2)
    with col1:
        start_date = st.date_input('Start Date', value=datetime.now() - timedelta(days=30))
    with col2:
        end_date = st.date_input('End Date', value=datetime.now())
    
    if st.button('Calculate Revenue'):
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                output_var = cursor.var(cx_Oracle.NUMBER)
                cursor.callproc('auto_dealership_pkg.calculate_revenue', 
                                [start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d'), output_var])
                revenue = output_var.getvalue()
                st.success(f'Total Revenue: ${revenue:.2f}')
        except cx_Oracle.Error as e:
            st.error(f"Error calculating revenue: {e}")

# Add some styling
st.markdown("""
    <style>
    .reportview-container {
        background: #f0f2f6
    }
    .sidebar .sidebar-content {
        background: #262730
    }
    </style>
    """, unsafe_allow_html=True)