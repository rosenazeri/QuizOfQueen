from src.DataBase.DataBase import get_connection

def block_user():
    conn = get_connection()
    cursor = conn.cursor()
    username = str(input("نام کاربری خود را وارد کنید: "))
    cursor.execute("SELECT userid FROM users WHERE username = %s", (username,))
    result = cursor.fetchone()

    if result is None:
        print("چنین کاربری وجود ندارد.")
        exit()
    else:
        userid = result[0]

    if userid % 2 == 0:
        try:
            target_username= str(input("لطفاً نام کاربری شخص هدف را وارد کنید: "))
            cursor.execute("SELECT userid FROM users WHERE username = %s", (target_username,))
            result = cursor.fetchone()
            if result is None:
                print("چنین کاربری وجود ندارد.")
                exit()
            else:
                target_userid = result[0]

            new_status = input("وضعیت جدید را وارد کنید (مثلاً 'active' یا 'inactive'): ")

            cursor.execute("SELECT * FROM users WHERE userid = %s", (target_userid,))
            result = cursor.fetchone()

            if result:
                cursor.execute("UPDATE users SET status = %s WHERE userid = %s", (new_status, target_userid))
                print(f"عملیات انجام شد")
            else:
                print(f".کاربر با این شناسه وجود ندارد")

            conn.commit()

        except ValueError:
            print("شناسه باید عدد باشد")

    else:
        print("این قابلیت برای شما وجود ندارد")

    conn.close()

