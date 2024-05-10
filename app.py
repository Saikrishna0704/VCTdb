import streamlit as st
import psycopg2
def connect_to_db():
    conn = psycopg2.connect(
        dbname="VCT_database",
        user="sai",
        password="sai123",
        host="127.0.0.1"  # or your host address
    )
    return conn

# Function to fetch data from PostgreSQL database
def fetch_data():
    conn = connect_to_db()
    cur = conn.cursor()
    cur.execute("select * from maps;")
    data = cur.fetchall()
    cur.close()
    conn.close()
    return data

# Function to insert data into PostgreSQL database
def insert_data(name, age):
    pass
'''
    conn = connect_to_db()
    cur = conn.cursor()
    cur.execute("INSERT INTO your_table_name (name, age) VALUES (%s, %s)", (name, age))
    conn.commit()
    cur.close()
    conn.close()
    '''

# Streamlit web application
def main():
    st.title("PostgreSQL Web Application")

    # Insert data
    st.header("Insert Data")
    name = st.text_input("Enter Name:")
    age = st.number_input("Enter Age:")
    if st.button("Insert"):
        insert_data(name, age)
        st.success("Data Inserted Successfully!")

    # Display data
    st.header("Display Data")
    data = fetch_data()
    print(data)
    st.write("Data from PostgreSQL Database:")
    st.write(data)

if __name__ == "__main__":
    main()
