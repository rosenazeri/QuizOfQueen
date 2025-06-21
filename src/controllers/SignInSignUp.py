import re
from datetime import datetime

import bcrypt
import psycopg2
from src.DataBase.DataBase import get_connection
from src.model.PlayerStatus import PlayerStatus

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())
def sign_in():
    x = 1
    while x:
        identifier = input("Username or Email: ").strip().lower()
        password = input("Password: ").strip()

        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute("""
              SELECT username, passwordhash
              FROM users
              WHERE username = %s OR email = %s
              """, (identifier, identifier))

            user = cursor.fetchone()
            conn.close()

            if user:
                username, password_hash_db = user
                if bcrypt.checkpw(password.encode('utf-8'), password_hash_db.encode('utf-8')):
                    print(f"Login successful! Welcome {username}.")
                    return identifier
                    x = 0
                else:
                    print("Incorrect password. Please try again.\n")
            else:
                 print("No user found with these details. Please try again.\n")

        except Exception as e:
            print(f"System error: {e}\n")
    return "Error processing request. Please try again later."

def insert_player_status(player_status: PlayerStatus):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        query = """
            INSERT INTO playerstatus (userid, totalgames, gameswon, gameslost, accuracy, xp)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            player_status.user_id,
            player_status.total_games,
            player_status.games_won,
            player_status.games_lost,
            player_status.accuracy,
            player_status.xp
        ))
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(f"Error inserting player status: {e}")
        return False

def is_valid_email(email):
    email_regex = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return re.match(email_regex, email) is not None

def username_exists(username):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM users WHERE username = %s", (username,))
        exists = cursor.fetchone() is not None
        cursor.close()
        conn.close()
        return exists
    except Exception as e:
        print(f"Error checking username: {e}")
        return True

def sign_up():
    while True:

        while True:
            username = input("Enter username: ").lower()
            if username_exists(username):
                print("Username already exists. Please choose a different one.")
            else:
                break

        while True:
            email = input("Enter email: ").lower()
            if is_valid_email(email):
                break
            else:
                print("Invalid email format. Please enter a valid email address.")

        password = input("Enter password: ")
        AdminOrUser = input("Admin or user?: ").lower()

        try:
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute("SELECT MAX(userid) FROM users")
            max_id = cursor.fetchone()[0]

            if AdminOrUser == "admin":
                new_userid = 2 if max_id is None else (max_id + 2 if max_id % 2 == 0 else max_id + 1)
            else:
                new_userid = 1 if max_id is None else (max_id + 2 if max_id % 2 == 1 else max_id + 1)

            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode()
            signup_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            query = """
            INSERT INTO users (userid, username, email, passwordhash, registerdate, status)
            VALUES (%s, %s, %s, %s, %s, %s)
            """
            cursor.execute(query, (new_userid, username, email, hashed_password, signup_date, "active"))
            conn.commit()
            cursor.close()
            conn.close()

            player_status = PlayerStatus(
                user_id=new_userid,
                total_games=0,
                games_won=0,
                games_lost=0,
                accuracy=0.0,
                xp=0
            )
            if not insert_player_status(player_status):
                return "Warning: Registration completed, but failed to insert initial player data."

            print(f"Registration successful! User ID: {new_userid}")
            return username

        except Exception as e:
            print(f"Error: {e}. Please try again.")
