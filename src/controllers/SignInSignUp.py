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
    identifier = input("نام کاربری یا ایمیل: ")
    password = input("رمز عبور: ")
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
            if verify_password(password, password_hash_db):
                return f"✅ ورود موفق! خوش آمدی {username}."
            else:
                return "❌ رمز عبور اشتباه است."
        else:
            return "❌ کاربری با این مشخصات یافت نشد."

    except Exception as e:
        return f"⚠️ خطا در اتصال به پایگاه داده: {e}"
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
        print(f"❌ خطا در درج وضعیت بازیکن: {e}")
        return False
def sign_up():
    while True:
        username = input("نام کاربری را وارد کنید: ")
        email = input("ایمیل را وارد کنید: ")
        password = input("رمز عبور را وارد کنید: ")
        AdminOrUser = input("admin or user?: ")
        try:
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute("SELECT MAX(userid) FROM users")
            max_id = cursor.fetchone()[0]

            if AdminOrUser == "admin":
                if max_id is None:
                    new_userid = 2
                else:
                    new_userid = max_id + 2 if max_id % 2 == 0 else max_id + 1
            else:
                if max_id is None:
                    new_userid = 1
                else:
                    new_userid = max_id + 2 if max_id % 2 == 1 else max_id + 1

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
                return "⚠️ ثبت‌نام انجام شد ولی درج اطلاعات اولیه بازیکن با خطا مواجه شد."

            return f"✅ ثبت‌نام با موفقیت انجام شد. شناسه کاربر: {new_userid}"

        except psycopg2.IntegrityError:
            print(f"نام کاربری شما تکراری است. لطفا نام جدیدی برای خود بسازید.")
        except Exception as e:
            print(f"خطا: {e}. لطفا مجدداً تلاش کنید.")