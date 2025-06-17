import psycopg2

def get_connection():
    return psycopg2.connect(
        dbname="QuizOfQueen",
        user="postgres",
        password="admin",
        host="localhost",
        port="5432"
    )
